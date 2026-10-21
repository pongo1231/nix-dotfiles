// Pure display-configuration logic for display-per-monitor@local.
//
// No gi:// imports on purpose: everything here is plain data in / data out, so
// it can be unit-tested outside GNOME Shell (and it keeps extension.js to
// plumbing only).
//
// Model
// -----
// mutter stores display configuration per *hardware setup* (the exact set of
// connected monitors, see mutter's doc/monitor-configuration.md). This module
// turns the two sources of per-display truth into per-display records:
//
//   1. `snapshot` – what the monitors are set to *right now* (in memory, fed
//                   from GetCurrentState; it only has to live as long as the
//                   monitors stay connected, which is exactly the lifetime
//                   needed for "survivors keep their settings when the set
//                   changes").
//   2. `db`       – per-display records parsed from ~/.config/monitors.xml,
//                   i.e. every configuration the user ever confirmed in
//                   Settings. Used for monitors that were not connected just
//                   before the change (e.g. a display that just came back).
//
// Records are keyed twice: by connector+identity and by identity. The
// connector-specific record wins when present, which is what makes the same
// monitor on two different ports (DP-1 @144Hz vs DP-3 @119.98Hz) resolve to the
// settings of *that* port.

const XML_ENTITIES = {amp: '&', lt: '<', gt: '>', quot: '"', apos: "'"};

// Rotation text used by mutter's monitors.xml writer, mapped to the
// MetaMonitorTransform values used by the DisplayConfig D-Bus API.
const ROTATIONS = {normal: 0, left: 1, upside_down: 2, right: 3};

// ---------------------------------------------------------------- XML subset

function decodeEntities(text) {
  if (!text.includes('&'))
    return text;

  return text.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, (match, entity) => {
    if (entity[0] === '#') {
      const hex = entity[1] === 'x' || entity[1] === 'X';
      const code = parseInt(hex ? entity.slice(2) : entity.slice(1), hex ? 16 : 10);
      return Number.isFinite(code) ? String.fromCodePoint(code) : match;
    }
    return XML_ENTITIES[entity] ?? match;
  });
}

function findTagEnd(source, start) {
  let quote = null;
  for (let i = start + 1; i < source.length; i++) {
    const ch = source[i];
    if (quote) {
      if (ch === quote)
        quote = null;
    } else if (ch === '"' || ch === "'") {
      quote = ch;
    } else if (ch === '>') {
      return i;
    }
  }
  return -1;
}

/** Minimal XML reader: elements and text; comments/PIs/doctypes skipped. */
export function parseXml(source) {
  const root = {name: '#root', children: [], text: ''};
  const stack = [root];
  let i = 0;

  while (i < source.length) {
    const lt = source.indexOf('<', i);
    if (lt < 0) {
      stack[stack.length - 1].text += source.slice(i);
      break;
    }
    if (lt > i)
      stack[stack.length - 1].text += source.slice(i, lt);

    if (source.startsWith('<!--', lt)) {
      const end = source.indexOf('-->', lt);
      i = end < 0 ? source.length : end + 3;
      continue;
    }
    if (source.startsWith('<?', lt) || source.startsWith('<!', lt)) {
      const end = source.indexOf('>', lt);
      i = end < 0 ? source.length : end + 1;
      continue;
    }

    const gt = findTagEnd(source, lt);
    if (gt < 0)
      break;

    const raw = source.slice(lt + 1, gt).trim();
    if (raw.startsWith('/')) {
      if (stack.length > 1)
        stack.pop();
    } else {
      const selfClosing = raw.endsWith('/');
      const body = selfClosing ? raw.slice(0, -1) : raw;
      const name = body.split(/\s+/)[0];
      if (name) {
        const node = {name, children: [], text: ''};
        stack[stack.length - 1].children.push(node);
        if (!selfClosing)
          stack.push(node);
      }
    }
    i = gt + 1;
  }

  return root;
}

export function childrenNamed(node, name) {
  return node ? node.children.filter(child => child.name === name) : [];
}

function firstNamed(node, name) {
  return node ? node.children.find(child => child.name === name) ?? null : null;
}

function textOf(node) {
  return node ? decodeEntities(node.text).trim() : '';
}

function childText(node, name) {
  return textOf(firstNamed(node, name));
}

function parseTransform(node) {
  // mutter omits <transform> for the default orientation and resets its own
  // parser state to NORMAL after every logical monitor, so absent == normal.
  if (!node)
    return ROTATIONS.normal;

  const rotation = ROTATIONS[childText(node, 'rotation')] ?? ROTATIONS.normal;
  const flipped = childText(node, 'flipped') === 'yes' ? 4 : 0;
  return rotation + flipped;
}

// ---------------------------------------------------------------------- keys

export function identityKey(vendor, product, serial) {
  return `${vendor}|${product}|${serial}`;
}

export function connectorKey(connector, vendor, product, serial) {
  return `${connector}|${vendor}|${product}|${serial}`;
}

function specKeys(spec) {
  return {
    connector: connectorKey(spec.connector, spec.vendor, spec.product, spec.serial),
    identity: identityKey(spec.vendor, spec.product, spec.serial),
  };
}

export function emptyRecords() {
  return {byConnector: new Map(), byIdentity: new Map()};
}

// -------------------------------------------------------- monitors.xml -> db

/**
 * Parse ~/.config/monitors.xml into per-display records.
 *
 * Only configurations the user actually confirmed live in this file, so it is
 * the one trustworthy source of "what the user wants" that survives restarts.
 * Disabled logical monitors are skipped: "this display was off in that setup"
 * is not a setting we restore.
 */
export function parseMonitorsXml(text) {
  const byConnector = new Map();
  const byIdentity = new Map();
  const root = parseXml(text);
  const monitorsNode = childrenNamed(root, 'monitors')[0];

  for (const configuration of childrenNamed(monitorsNode, 'configuration')) {
    for (const logicalMonitor of childrenNamed(configuration, 'logicalmonitor')) {
      if (childText(logicalMonitor, 'disabled') === 'yes')
        continue;

      const scale = parseFloat(childText(logicalMonitor, 'scale'));
      const transform = parseTransform(firstNamed(logicalMonitor, 'transform'));

      for (const monitor of childrenNamed(logicalMonitor, 'monitor')) {
        const spec = firstNamed(monitor, 'monitorspec');
        const mode = firstNamed(monitor, 'mode');
        if (!spec || !mode)
          continue;

        const record = {
          width: parseInt(childText(mode, 'width'), 10),
          height: parseInt(childText(mode, 'height'), 10),
          rate: parseFloat(childText(mode, 'rate')),
          vrr: childText(mode, 'ratemode') === 'variable',
          scale: Number.isFinite(scale) ? scale : null,
          transform,
          x: null,
          y: null,
          seen: Date.now(),
        };
        if (!Number.isFinite(record.width) || !Number.isFinite(record.height) ||
            !Number.isFinite(record.rate))
          continue;

        byIdentity.set(identityKey(childText(spec, 'vendor'), childText(spec, 'product'), childText(spec, 'serial')), record);
        byConnector.set(connectorKey(childText(spec, 'connector'), childText(spec, 'vendor'), childText(spec, 'product'), childText(spec, 'serial')), record);
      }
    }
  }

  return {byConnector, byIdentity};
}

// --------------------------------------------------------- live state helpers

function unpack(properties, key) {
  const value = properties?.[key];
  if (value === undefined || value === null)
    return null;
  return typeof value.deepUnpack === 'function' ? value.deepUnpack() : value;
}

/** One GetCurrentState mode tuple -> plain object. */
export function modeInfo(mode) {
  const [id, width, height, rate, preferredScale, supportedScales, properties] = mode;
  return {
    id,
    width,
    height,
    rate,
    preferredScale,
    supportedScales: supportedScales ?? [],
    vrr: unpack(properties, 'refresh-rate-mode') === 'variable',
    current: unpack(properties, 'is-current') === true,
    preferred: unpack(properties, 'is-preferred') === true,
  };
}

export function currentMode(modes) {
  const infos = modes.map(modeInfo);
  return infos.find(mode => mode.current) ?? infos.find(mode => mode.preferred) ?? infos[0] ?? null;
}

function scaleSupported(mode, scale) {
  return mode.supportedScales.some(supported => Math.abs(supported - scale) < 0.001);
}

/**
 * Pick the mode of `modes` matching a learned record: same resolution, the same
 * refresh-rate mode (fixed vs variable, i.e. VRR) when available, the closest
 * refresh rate, preferring one that supports the remembered scale.
 */
export function pickMode(modes, record) {
  const infos = modes.map(modeInfo);
  let pool = infos.filter(mode => mode.width === record.width && mode.height === record.height);
  if (pool.length === 0)
    return null;

  const sameVrr = pool.filter(mode => mode.vrr === record.vrr);
  if (sameVrr.length > 0)
    pool = sameVrr;

  if (record.scale !== null && record.scale !== undefined) {
    const withScale = pool.filter(mode => scaleSupported(mode, record.scale));
    if (withScale.length > 0)
      pool = withScale;
  }

  let best = pool[0];
  for (const mode of pool) {
    if (Math.abs(mode.rate - record.rate) < Math.abs(best.rate - record.rate))
      best = mode;
  }
  return best;
}

function lookupRecord(spec, sources) {
  const keys = specKeys(spec);
  for (const source of sources) {
    const record = source?.byConnector?.get(keys.connector);
    if (record)
      return record;
  }
  for (const source of sources) {
    const record = source?.byIdentity?.get(keys.identity);
    if (record)
      return record;
  }
  return null;
}

/** The record remembering `spec`, looked up in the given sources in order. */
export function rememberedRecord(spec, sources) {
  return lookupRecord(spec, sources);
}

/**
 * Is this monitor sitting on exactly what mutter configures on its own (EDID
 * preferred timing, preferred scale, fixed refresh rate)? That is what a
 * fallback looks like, and it must not be mistaken for a user choice when the
 * monitor set did not change (e.g. a flapping display-port link re-running
 * mutter's configuration).
 */
export function isAtAutoDefault(mode, scale) {
  if (!mode.preferred || mode.vrr)
    return false;
  const preferred = mode.preferredScale;
  return preferred === null || preferred === undefined || Math.abs(scale - preferred) < 0.001;
}

/** Does `record` already describe this mode and scale? */
export function recordDescribes(record, mode, scale) {
  if (!record)
    return false;
  return record.width === mode.width && record.height === mode.height &&
    Math.abs(record.rate - mode.rate) < 0.01 && record.vrr === mode.vrr &&
    (record.scale === null || record.scale === undefined || Math.abs(record.scale - scale) < 0.001);
}

function stateMonitors(state) {
  return new Map(state.monitors.map(monitor => [monitor.spec.connector, monitor]));
}

// ------------------------------------------------------------------- snapshot

/** Per-display records describing the live state. */
export function snapshotFromState(state) {
  const monitors = stateMonitors(state);
  const byConnector = new Map();
  const byIdentity = new Map();
  const now = Date.now();

  for (const logicalMonitor of state.logicalMonitors) {
    for (const spec of logicalMonitor.monitors) {
      const monitor = monitors.get(spec.connector);
      const mode = monitor ? currentMode(monitor.modes) : null;
      if (!mode)
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
        seen: now,
      };
      const keys = specKeys(spec);
      byConnector.set(keys.connector, record);
      byIdentity.set(keys.identity, record);
    }
  }

  return {byConnector, byIdentity};
}

export function mergeRecords(target, fresh) {
  for (const key of ['byConnector', 'byIdentity']) {
    for (const [name, record] of fresh[key])
      target[key].set(name, record);
  }
  return target;
}

/** Drop records of monitors that have not been seen for a long time. */
export function pruneRecords(records, maxAge = 30 * 24 * 3600 * 1000) {
  const cutoff = Date.now() - maxAge;
  for (const key of ['byConnector', 'byIdentity']) {
    for (const [name, record] of records[key]) {
      if (record.seen < cutoff)
        records[key].delete(name);
    }
  }
  return records;
}

// -------------------------------------------------------------- target config

function logicalSize(info, scale, transform) {
  const rotated = transform % 2 === 1;
  const width = rotated ? info.height : info.width;
  const height = rotated ? info.width : info.height;
  return {width: Math.round(width / scale), height: Math.round(height / scale)};
}

function orderKey(entries, logicalMonitor) {
  // Remembered x if we have one, else the live x: mutter's own fallback already
  // picks a sane order for displays it just met.
  const remembered = entries
    .map(entry => entry.record?.x)
    .filter(x => x !== null && x !== undefined);
  return remembered.length > 0 ? Math.min(...remembered) : 1000000 + logicalMonitor.x;
}

function repack(logicalMonitors) {
  const rows = new Map();
  for (const logicalMonitor of logicalMonitors) {
    const row = rows.get(logicalMonitor.originalY) ?? [];
    row.push(logicalMonitor);
    rows.set(logicalMonitor.originalY, row);
  }

  let rowY = 0;
  for (const y of [...rows.keys()].sort((a, b) => a - b)) {
    const row = rows.get(y).sort((a, b) => a.order - b.order || a.originalX - b.originalX);
    let x = 0;
    let rowHeight = 0;
    for (const logicalMonitor of row) {
      logicalMonitor.x = x;
      logicalMonitor.y = rowY;
      x += logicalMonitor.width;
      rowHeight = Math.max(rowHeight, logicalMonitor.height);
    }
    rowY += rowHeight;
  }
}

/**
 * Compute the configuration that reproduces each monitor's remembered settings
 * for the currently connected set.
 *
 * Survivors (present before the change) come from `snapshot`, newcomers from
 * `db`, and monitors in neither are left exactly as mutter configured them.
 * Positions are repacked per row so that changed scales never leave gaps or
 * overlaps, while the left-to-right order the user had is preserved.
 */
export function computeTarget(state, snapshot, db) {
  const monitors = stateMonitors(state);
  const logicalMonitors = [];
  let changed = false;

  for (const logicalMonitor of state.logicalMonitors) {
    const entries = [];
    for (const spec of logicalMonitor.monitors) {
      const monitor = monitors.get(spec.connector);
      if (!monitor)
        break;

      const live = currentMode(monitor.modes);
      if (!live)
        break;

      const record = lookupRecord(spec, [snapshot, db]);
      const wanted = (record && pickMode(monitor.modes, record)) || live;
      entries.push({spec, live, wanted, record});
    }
    if (entries.length !== logicalMonitor.monitors.length || entries.length === 0)
      continue; // nothing we can say about this logical monitor: leave it alone

    const recordScales = entries.map(entry => entry.record?.scale).filter(scale => scale !== null && scale !== undefined);
    let scale = logicalMonitor.scale;
    if (recordScales.length === entries.length && recordScales.every(candidate => Math.abs(candidate - recordScales[0]) < 0.001) &&
        entries.every(entry => scaleSupported(entry.wanted, recordScales[0])))
      scale = recordScales[0];

    const recordTransforms = entries.map(entry => entry.record?.transform).filter(transform => transform !== null && transform !== undefined);
    let transform = logicalMonitor.transform;
    if (recordTransforms.length === entries.length && recordTransforms.every(candidate => candidate === recordTransforms[0]))
      transform = recordTransforms[0];

    if (entries.some(entry => entry.wanted.id !== entry.live.id) ||
        Math.abs(scale - logicalMonitor.scale) > 0.001 ||
        transform !== logicalMonitor.transform)
      changed = true;

    const sizes = entries.map(entry => logicalSize(entry.wanted, scale, transform));
    logicalMonitors.push({
      x: logicalMonitor.x,
      y: logicalMonitor.y,
      originalX: logicalMonitor.x,
      originalY: logicalMonitor.y,
      scale,
      transform,
      primary: logicalMonitor.primary,
      entries,
      width: Math.max(...sizes.map(size => size.width)),
      height: Math.max(...sizes.map(size => size.height)),
      order: orderKey(entries, logicalMonitor),
    });
  }

  if (logicalMonitors.length === 0)
    return {changed: false, logicalMonitors: [], records: [], signature: liveConfigSignature(state)};

  repack(logicalMonitors);

  const records = [];
  for (const logicalMonitor of logicalMonitors) {
    if (logicalMonitor.x !== logicalMonitor.originalX || logicalMonitor.y !== logicalMonitor.originalY)
      changed = true;

    for (const entry of logicalMonitor.entries) {
      records.push({
        spec: entry.spec,
        record: {
          width: entry.wanted.width,
          height: entry.wanted.height,
          rate: entry.wanted.rate,
          vrr: entry.wanted.vrr,
          scale: logicalMonitor.scale,
          transform: logicalMonitor.transform,
          x: logicalMonitor.x,
          y: logicalMonitor.y,
          seen: Date.now(),
        },
      });
    }
  }

  return {
    changed,
    logicalMonitors: logicalMonitors.map(logicalMonitor => [
      logicalMonitor.x,
      logicalMonitor.y,
      logicalMonitor.scale,
      logicalMonitor.transform,
      logicalMonitor.primary,
      logicalMonitor.entries.map(entry => [entry.spec.connector, entry.wanted.id, {}]),
    ]),
    records,
    signature: targetSignature(logicalMonitors),
  };
}

/** Signature of the connected monitor set: changes only when displays come/go. */
export function stateSignature(state) {
  return state.monitors
    .map(monitor => monitor.spec.connector + ':' +
      identityKey(monitor.spec.vendor, monitor.spec.product, monitor.spec.serial))
    .sort()
    .join(',');
}

function describeLogicalMonitor(connectorsModes, x, y, scale, transform) {
  return `${connectorsModes.sort().join('+')}@${x},${y}/${scale}/${transform}`;
}

/** Signature of the D-Bus shaped config (array of logical monitor tuples). */
export function configSignature(logicalMonitors) {
  return logicalMonitors
    .map(([x, y, scale, transform, _primary, monitors]) =>
      describeLogicalMonitor(monitors.map(([connector, modeId]) => `${connector}=${modeId}`), x, y, scale, transform))
    .sort()
    .join(' ');
}

function targetSignature(logicalMonitors) {
  return logicalMonitors
    .map(logicalMonitor =>
      describeLogicalMonitor(logicalMonitor.entries.map(entry => `${entry.spec.connector}=${entry.wanted.id}`),
        logicalMonitor.x, logicalMonitor.y, logicalMonitor.scale, logicalMonitor.transform))
    .sort()
    .join(' ');
}

/** Signature of what is on screen right now. */
export function liveConfigSignature(state) {
  const monitors = stateMonitors(state);
  return state.logicalMonitors
    .map(logicalMonitor => {
      const connectorsModes = logicalMonitor.monitors.map(spec => {
        const monitor = monitors.get(spec.connector);
        const mode = monitor ? currentMode(monitor.modes) : null;
        return `${spec.connector}=${mode ? mode.id : '?'}`;
      });
      return describeLogicalMonitor(connectorsModes, logicalMonitor.x, logicalMonitor.y,
        logicalMonitor.scale, logicalMonitor.transform);
    })
    .sort()
    .join(' ');
}
