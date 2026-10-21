// display-per-monitor@local — keeps display settings per monitor instead of
// per monitor set.
//
// mutter keys its stored configurations by the *exact* set of connected
// monitors (see mutter's doc/monitor-configuration.md), and everything it
// generates itself — the fallback applied whenever the set changes — uses each
// monitor's preferred mode, the default scale and no VRR. So plugging in a new
// display resets the displays that were already working.
//
// This extension does not try to pre-empt mutter (it cannot: the
// monitors-changed signal is emitted after mutter commits its configuration).
// Instead it recomputes the whole configuration from per-display memory as soon
// as a set change is seen, and applies it with method=temporary so nothing is
// written back to monitors.xml.
//
// Per-display memory has two sources (see config.js):
//   snapshot – what each connected monitor is set to right now (in memory)
//   db       – every configuration the user confirmed in Settings, parsed
//              lazily from ~/.config/monitors.xml
//
// Nothing is hardcoded: no connector names, scales or refresh rates. Monitors
// that neither source knows about are left exactly as mutter configured them.

import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

import {
  parseMonitorsXml,
  mergeRecords,
  pruneRecords,
  emptyRecords,
  computeTarget,
  stateSignature,
  liveConfigSignature,
  connectorKey,
  identityKey,
  currentMode,
  rememberedRecord,
  isAtAutoDefault,
  recordDescribes,
} from './config.js';

const DisplayConfigIface = `
<node>
  <interface name="org.gnome.Mutter.DisplayConfig">
    <method name="GetCurrentState">
      <arg name="serial" direction="out" type="u"/>
      <arg name="monitors" direction="out" type="a((ssss)a(siiddada{sv})a{sv})"/>
      <arg name="logical_monitors" direction="out" type="a(iiduba(ssss)a{sv})"/>
      <arg name="properties" direction="out" type="a{sv}"/>
    </method>
    <method name="ApplyMonitorsConfig">
      <arg name="serial" direction="in" type="u"/>
      <arg name="method" direction="in" type="u"/>
      <arg name="logical_monitors" direction="in" type="a(iiduba(ssa{sv}))"/>
      <arg name="properties" direction="in" type="a{sv}"/>
    </method>
    <signal name="MonitorsChanged"/>
  </interface>
</node>`;

const METHOD_TEMPORARY = 1;
const SIGNAL_DEBOUNCE_MS = 400;
const LEARN_DEBOUNCE_MS = 500;
const MAX_REPAIRS = 3;
const RETRY_MS = 600;
const SETTLE_MS = 4000;
const LOG_LINES = 60;

export default class DisplayPerMonitorExtension extends Extension {
  enable() {
    this._enabled = true;
    this._db = emptyRecords();
    this._snapshot = emptyRecords();
    this._setSignature = null;
    this._settle = null;
    this._busy = false;
    this._checkId = 0;
    this._learnId = 0;
    this._fileMonitor = null;
    this._fileMonitorId = 0;
    this._signalId = 0;
    this._lines = [];

    this._learn();
    this._watchMonitorsXml();

    const ProxyWrapper = Gio.DBusProxy.makeProxyWrapper(DisplayConfigIface);
    this._proxy = new ProxyWrapper(
      Gio.DBus.session,
      'org.gnome.Mutter.DisplayConfig',
      '/org/gnome/Mutter/DisplayConfig',
      (proxy, error) => {
        if (error) {
          this._log(`display config unavailable: ${error.message}`);
          return;
        }
        this._signalId = this._proxy.connectSignal('MonitorsChanged', () => this._scheduleCheck());
        this._scheduleCheck(0); // treat the current state as a fresh set
      });
  }

  disable() {
    this._enabled = false;
    this._clearTimeout('_checkId');
    this._clearTimeout('_learnId');

    if (this._fileMonitorId) {
      this._fileMonitor.disconnect(this._fileMonitorId);
      this._fileMonitorId = 0;
    }
    this._fileMonitor = null;

    if (this._proxy && this._signalId) {
      this._proxy.disconnectSignal(this._signalId);
      this._signalId = 0;
    }
    this._proxy = null;
    this._snapshot = null;
    this._db = null;
    this._settle = null;
    this._lines = null;
  }

  // ------------------------------------------------------------ per-display db

  _monitorsXmlPath() {
    return GLib.build_filenamev([GLib.get_user_config_dir(), 'monitors.xml']);
  }

  _watchMonitorsXml() {
    try {
      this._fileMonitor = Gio.File.new_for_path(this._monitorsXmlPath())
        .monitor_file(Gio.FileMonitorFlags.NONE, null);
      this._fileMonitorId = this._fileMonitor.connect('changed', () => {
        this._clearTimeout('_learnId');
        this._learnId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, LEARN_DEBOUNCE_MS, () => {
          this._learnId = 0;
          this._learn();
          if (this._settle) {
            // A configuration was confirmed in Settings: that is the user
            // speaking, so stop re-asserting what we last applied.
            this._settle = null;
            this._scheduleCheck(0);
          }
          return GLib.SOURCE_REMOVE;
        });
      });
    } catch (e) {
      this._log(`monitors.xml watch failed: ${e.message}`);
    }
  }

  _learn() {
    let contents = null;
    try {
      const [ok, bytes] = GLib.file_get_contents(this._monitorsXmlPath());
      if (ok)
        contents = new TextDecoder().decode(bytes);
    } catch (e) {
      this._log(`monitors.xml unreadable: ${e.message}`);
    }

    if (contents === null) {
      this._db = emptyRecords();
      return;
    }

    try {
      this._db = parseMonitorsXml(contents);
      this._log(`monitors.xml: ${this._db.byConnector.size} per-port and ` +
                `${this._db.byIdentity.size} per-display record(s)`);
    } catch (e) {
      this._log(`monitors.xml parse failed: ${e.message}`);
    }
  }

  // ------------------------------------------------------------- mutter state

  _scheduleCheck(delay = SIGNAL_DEBOUNCE_MS) {
    this._clearTimeout('_checkId');
    this._checkId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, delay, () => {
      this._checkId = 0;
      this._check();
      return GLib.SOURCE_REMOVE;
    });
  }

  _clearTimeout(field) {
    if (this[field]) {
      GLib.source_remove(this[field]);
      this[field] = 0;
    }
  }

  _check() {
    if (!this._enabled || !this._proxy)
      return;
    if (this._busy) {
      this._scheduleCheck();
      return;
    }

    this._proxy.GetCurrentStateRemote((result, error) => {
      if (!this._enabled)
        return;
      if (error) {
        this._log(`GetCurrentState failed: ${error.message}`);
        return;
      }
      try {
        this._handleState(this._stateFromResult(result));
      } catch (e) {
        this._log(`state handling failed: ${e.message}`);
      }
    });
  }

  _stateFromResult([serial, monitors, logicalMonitors]) {
    const spec = value => ({
      connector: value[0], vendor: value[1], product: value[2], serial: value[3],
    });

    return {
      serial,
      monitors: monitors.map(([monitorSpec, modes]) => ({spec: spec(monitorSpec), modes})),
      logicalMonitors: logicalMonitors.map(([x, y, scale, transform, primary, monitorsInLm]) => ({
        x, y, scale, transform, primary, monitors: monitorsInLm.map(spec),
      })),
    };
  }

  _handleState(state) {
    const signature = stateSignature(state);
    const setChanged = signature !== this._setSignature;
    this._setSignature = signature;

    if (setChanged) {
      this._onSetChange(state, signature);
      return;
    }

    if (this._settle) {
      // mutter (or anything else) changed something while we were settling:
      // re-assert what we computed, but only a bounded number of times.
      const {records, config, signature: desired, until, attempts} = this._settle;
      const live = liveConfigSignature(state);
      const now = this._nowMs();
      if (live !== desired && now < until && attempts < MAX_REPAIRS) {
        this._settle.attempts = attempts + 1;
        this._apply(state.serial, config, desired, 're-assert',
          () => this._rememberRecords(records));
        return;
      }
      this._settle = null;
    }

    // Same set, nothing in flight: this is what the user is running with, so
    // remember it per display.
    this._remember(state);
  }

  _onSetChange(state, signature) {
    const target = computeTarget(state, this._snapshot, this._db);
    const learned = `${this._snapshot.byConnector.size}/${this._db.byConnector.size}`;

    if (!target.changed) {
      this._log(`set change (${learned} remembered): ${signature} already matches`);
      this._remember(state);
      return;
    }

    const records = target.records;
    this._settle = {
      until: this._nowMs() + SETTLE_MS,
      attempts: 1,
      config: target.logicalMonitors,
      signature: target.signature,
      records,
    };
    this._log(`set change (${learned} remembered): repairing -> ${target.signature}`);
    this._apply(state.serial, target.logicalMonitors, target.signature, 'set change',
      () => this._rememberRecords(records));
  }

  _apply(serial, logicalMonitors, signature, reason, onApplied) {
    this._busy = true;
    this._proxy.ApplyMonitorsConfigRemote(serial, METHOD_TEMPORARY, logicalMonitors, {},
      (result, error) => {
        this._busy = false;
        if (error) {
          this._log(`apply failed (${reason}): ${error.message}`);
          this._scheduleCheck(RETRY_MS); // serial may be stale by now
          return;
        }
        this._log(`applied (${reason}): ${signature}`);
        onApplied?.();
      });
  }

  // ------------------------------------------------------------------ memory

  _remember(state) {
    if (!this._snapshot)
      return;

    const fresh = emptyRecords();
    const monitors = new Map(state.monitors.map(monitor => [monitor.spec.connector, monitor]));

    for (const logicalMonitor of state.logicalMonitors) {
      for (const spec of logicalMonitor.monitors) {
        const monitor = monitors.get(spec.connector);
        const mode = monitor ? currentMode(monitor.modes) : null;
        if (!mode)
          continue;

        // A monitor sitting on mutter's own defaults while the set is unchanged
        // is either a fallback re-run (flapping link) or a throwaway temporary
        // change — never overwrite what we remember with it.
        const remembered = rememberedRecord(spec, [this._snapshot, this._db]);
        if (isAtAutoDefault(mode, logicalMonitor.scale) && remembered &&
            !recordDescribes(remembered, mode, logicalMonitor.scale))
          continue;

        const record = {
          width: mode.width,
          height: mode.height,
          rate: mode.rate,
          vrr: mode.vrr,
          scale: logicalMonitor.scale,
          transform: logicalMonitor.transform,
          x: logicalMonitor.x,
          y: logicalMonitor.y,
          seen: Date.now(),
        };
        const keys = {connector: connectorKey(spec.connector, spec.vendor, spec.product, spec.serial),
          identity: identityKey(spec.vendor, spec.product, spec.serial)};
        fresh.byConnector.set(keys.connector, record);
        fresh.byIdentity.set(keys.identity, record);
      }
    }

    mergeRecords(this._snapshot, fresh);
    pruneRecords(this._snapshot);
  }

  /**
   * Remember what we asked for rather than what is on screen: right after a set
   * change the screen still shows mutter's fallback.
   */
  _rememberRecords(records) {
    if (!records || !this._snapshot)
      return;

    const fresh = emptyRecords();
    for (const {spec, record} of records) {
      fresh.byConnector.set(connectorKey(spec.connector, spec.vendor, spec.product, spec.serial), record);
      fresh.byIdentity.set(identityKey(spec.vendor, spec.product, spec.serial), record);
    }
    mergeRecords(this._snapshot, fresh);
    pruneRecords(this._snapshot);
  }

  // ------------------------------------------------------------------- logging

  _nowMs() {
    return GLib.get_monotonic_time() / 1000;
  }

  _log(message) {
    console.log(`[display-per-monitor] ${message}`);

    if (!this._lines)
      return;

    const stamp = GLib.DateTime.new_now_local().format('%H:%M:%S');
    this._lines.push(`${stamp} ${message}`);
    if (this._lines.length > LOG_LINES)
      this._lines.splice(0, this._lines.length - LOG_LINES);

    try {
      GLib.file_set_contents(
        GLib.build_filenamev([GLib.get_user_cache_dir(), 'display-per-monitor.log']),
        this._lines.join('\n') + '\n');
    } catch (e) {
      // Logging must never break the extension.
    }
  }
}
