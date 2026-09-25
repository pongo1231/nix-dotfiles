#!/usr/bin/env python3
"""snapps -- browse and prune snapper snapshots.

Usage:
    sudo snapps SNAPSHOT_DIR [PATH]           browse the snapshots in gdu
    sudo snapps --dump SNAPSHOT_DIR [PATH]    print the gdu import JSON
    sudo snapps rm SNAPSHOT_DIR PATH          delete PATH from every snapshot

SNAPSHOT_DIR  directory whose entries are snapshot directories, each holding a
              `snapshot` subvolume (e.g. `/.snapshots` for the root config, or
              `/home/.snapshots` for the home config).
PATH          absolute path, interpreted relative to each snapshot's root,
              i.e. joined as `<SNAPSHOT_DIR>/<entry>/snapshot/<PATH>`.

The browser lists every snapshot with the space that snapshot holds by itself
(what deleting its stale content would free) and lets the user drill into the
individual folders and files that differ from the live subvolume, each with
what deleting it would free.

The `rm` subcommand is the equivalent of the old `snapperS -d SNAPSHOT_DIR rm
--recursive -f PATH`: deletion is recursive and never prompts.  Only paths
inside SNAPSHOT_DIR are modified, so the live filesystem is never touched.

Which entries a snapshot holds on its own is derived from `btrfs send
--no-data` diffs against a temporary read-only snapshot of the live subvolume.
How many bytes deleting one of them would free is derived three ways, none of
which involves btrfs quota:

  default        each file's own extents are read with BTRFS_IOC_TREE_SEARCH_V2
                 (one call per file), so sizes are compression-exact, and
                 sharing is decided by inode identity plus the link/clone
                 operations the stream reported.
  --fast         no ioctls at all: sizes come from st_blocks, so a compressed
                 file is counted at its uncompressed size.
  --extent-refs  additionally reads the global refcount of each extent from the
                 extent tree, which makes sharing exact -- including partial
                 sharing of one file -- but walks the extent tree, so it is
                 much slower on a large filesystem.
"""

import argparse
import atexit
import concurrent.futures
import fcntl
import hashlib
import json
import os
import re
import signal
import stat
import struct
import subprocess
import sys
import tempfile
import threading
import time

BTRFS = "btrfs"
GDU = "gdu"
REF_NAME = ".snappers-ref"
CACHE_DIR = "/var/cache/snapps"
VERSION = "2.1.0"
# Bumped whenever the way rows are derived changes, so a cache written by an
# older build can never be replayed under newer rules.  4: the size column is
# one of "sizes" (extent-exact bytes), "blocks" (st_blocks) or "refs"
# (extent-exact and refcount-filtered), recorded in the header.
CACHE_SCHEMA = 4

# `btrfs receive --dump` operations that prove the path exists in the snapshot
# that was sent.  Everything else (unlink, rmdir, chmod, chown, utimes,
# set_xattr, ...) is either metadata-only or describes a path that only exists
# in the parent, so it can never be reclaimed from the snapshot.
SNAPSHOT_OPS = frozenset(
    {
        b"mkfile",
        b"mkdir",
        b"mknod",
        b"mkfifo",
        b"mksock",
        b"symlink",
        b"update_extent",
        b"truncate",
        b"clone",
        b"fallocate",
        b"encoded_write",
        b"write",
        b"link",
    }
)
# `rename` prints the real name of a newly created entry in `dest=`; its own
# path argument is the stream-local temporary name (`o<ino>-<gen>-<n>`, see
# fs/btrfs/send.c) which never exists on disk.  `symlink`'s and `link`'s
# `dest=` is *not* a new entry -- it is a symlink target string or an already
# existing hard-link target -- so only `rename` belongs here.
DEST_OPS = frozenset({b"rename"})
# Everything else a dump contains (chown, chmod, utimes, unlink, rmdir,
# set_xattr, subvol, ...) carries nothing this tool collects, so those lines
# never reach the tokenizer.
OPS_OF_INTEREST = SNAPSHOT_OPS | DEST_OPS

# An escape is always a backslash plus one following byte (`\ `, `\\`, `\n`,
# `\012`), so a token is a run of escapes and non-space bytes.  Consuming `\X`
# pairs is what keeps `\\` + the alignment space (a name ending in a backslash)
# apart from `\ ` (a space inside a name).
_TOKEN_PATTERN = re.compile(rb"(?:\\[\s\S]|[^ ])+")
_ESCAPE_PATTERN = re.compile(rb"\\([0-7]{3}|.)", re.DOTALL)
_ESCAPE_BYTES = {
    0x61: 0x07,  # \a
    0x62: 0x08,  # \b
    0x65: 0x1B,  # \e
    0x66: 0x0C,  # \f
    0x6E: 0x0A,  # \n
    0x72: 0x0D,  # \r
    0x74: 0x09,  # \t
    0x76: 0x0B,  # \v
    0x20: 0x20,  # \  (space)
    0x5C: 0x5C,  # \\
}


def _split_escaped(data: bytes) -> list:
    """Escape-aware split on the spaces that separate the fields.

    Runs in C: the per-byte Python loop this replaced made every pipeline
    serialise on the GIL, which is the difference between minutes and hours for
    a 64-snapshot `/home`.
    """
    return _TOKEN_PATTERN.findall(data)


def _unescape(raw: bytes) -> bytes:
    """Undo `string_print_escape_special` (see common/string-utils.c)."""
    if b"\\" not in raw:
        return raw

    def replace(match):
        text = match.group(1)
        if len(text) == 3 and text.isdigit():
            return bytes((int(text, 8),))
        return _ESCAPE_BYTES.get(text[0], text[0]).to_bytes(1, "big")

    return _ESCAPE_PATTERN.sub(replace, raw)


class SnappsError(Exception):
    """A fatal, user-visible failure."""


# --------------------------------------------------------------------------
# snapper / btrfs helpers
# --------------------------------------------------------------------------


def stderr_of(result: subprocess.CompletedProcess) -> str:
    return result.stderr.decode(errors="replace").strip()


def _check_euid() -> None:
    if os.geteuid() != 0:
        raise SnappsError("must be run as root")


def is_subvolume(path: str) -> bool:
    """Whether `path` is a btrfs subvolume (requires root, like the rest)."""
    return (
        subprocess.run(
            [BTRFS, "subvolume", "show", path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )


def subvolume_info(path: str) -> dict:
    """Parsed `btrfs subvolume show` output, or {} when not a subvolume."""
    result = subprocess.run(
        [BTRFS, "subvolume", "show", path],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return {}
    info = {}
    for line in result.stdout.decode(errors="replace").splitlines():
        key, sep, value = line.partition(":")
        if sep:
            info[key.strip()] = value.strip()
    return info


def subvolume_generation(path: str) -> int:
    info = subvolume_info(path)
    try:
        return int(info["Generation"])
    except (KeyError, ValueError):
        raise SnappsError(f"cannot read the generation of {path}") from None


def set_subvolume_ro(snapshot_root: str, readonly: bool) -> subprocess.CompletedProcess:
    """Set the `ro` property of a snapshot subvolume."""
    return subprocess.run(
        [
            BTRFS,
            "property",
            "set",
            "-ts",
            snapshot_root,
            "ro",
            "true" if readonly else "false",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )


def _reraise(error: OSError) -> None:
    raise error


def remove_recursive(path: str) -> None:
    """Equivalent of `rm -rf path`, without ever following symlinks."""
    if not os.path.lexists(path):  # also matches dangling symlinks
        return
    if os.path.islink(path) or not os.path.isdir(path):
        os.unlink(path)
        return
    for root, dirs, files in os.walk(path, topdown=False, onerror=_reraise):
        for name in files:
            os.unlink(os.path.join(root, name))
        for name in dirs:
            child = os.path.join(root, name)
            if os.path.islink(child):
                os.unlink(child)
            else:
                os.rmdir(child)
    os.rmdir(path)


def snapshot_relative_path(raw: str) -> str:
    """Validate PATH and normalise it to a path rooted at '/'."""
    if not raw.startswith("/"):
        raise ValueError(f"PATH must be absolute: {raw!r}")
    parts = [part for part in raw.split("/") if part not in ("", ".")]
    if not parts:
        raise ValueError("refusing to operate on the snapshot root")
    if ".." in parts:
        raise ValueError(f"PATH must not contain '..': {raw!r}")
    return "/" + "/".join(parts)


def resolves_inside(path: str, root: str) -> bool:
    """Whether `path` stays inside `root` once symlinks are resolved.

    The lexical `PATH.startswith(root)` checks in this file cannot see a
    symlink *inside* a snapshot, which would otherwise redirect a deletion into
    the live filesystem -- exactly what this tool promises never to touch.
    """
    resolved = os.path.realpath(path)
    return resolved == root or resolved.startswith(root + os.sep)


def snapshot_sort_key(name: str) -> tuple:
    return (0, int(name), "") if name.isdigit() else (1, 0, name)


# --------------------------------------------------------------------------
# snapshot discovery
# --------------------------------------------------------------------------


class Snapshot:
    __slots__ = ("id", "root", "gen")

    def __init__(self, snapshot_id: str, root: str, gen):
        self.id = snapshot_id
        self.root = root
        self.gen = gen


def load_snapshots(snapshot_dir: str) -> list:
    """Every numbered `<SNAPSHOT_DIR>/<n>/snapshot` subvolume, oldest first."""
    try:
        entries = os.listdir(snapshot_dir)
    except OSError as error:
        raise SnappsError(f"cannot read {snapshot_dir}: {error.strerror}") from None
    snapshots = []
    for name in entries:
        if not name.isdigit():
            continue
        root = os.path.join(snapshot_dir, name, "snapshot")
        info = subvolume_info(root)
        if not info:
            continue
        snapshots.append(Snapshot(name, root, info.get("Generation")))
    snapshots.sort(key=lambda snap: int(snap.id))
    return snapshots


def ref_path(snapshot_dir: str) -> str:
    """Where the temporary read-only reference snapshot lives.

    The reference is placed on the mount point of the filesystem that holds the
    live subvolume, which keeps it outside the live subvolume (and therefore out
    of every snapshot) for the usual `<SUBVOLUME>/.snapshots` layout.
    """
    live = os.path.dirname(snapshot_dir)
    return os.path.join(mount_point_of(live), REF_NAME)


def _unescape_mountinfo(field: str) -> str:
    out = []
    i = 0
    length = len(field)
    while i < length:
        char = field[i]
        if char == "\\" and i + 3 < length and field[i + 1 : i + 4].isdigit():
            out.append(chr(int(field[i + 1 : i + 4], 8)))
            i += 4
        else:
            out.append(char)
            i += 1
    return "".join(out)


def mount_point_of(path: str) -> str:
    """Longest mount point prefix of `path`, from /proc/self/mountinfo."""
    target = os.path.realpath(path)
    best = "/"
    with open("/proc/self/mountinfo", "r", errors="replace") as mountinfo:
        for line in mountinfo:
            fields = line.split(" ")
            if len(fields) < 5:
                continue
            point = _unescape_mountinfo(fields[4])
            if target == point or target.startswith(point.rstrip("/") + "/"):
                if len(point) > len(best):
                    best = point
    return best


# --------------------------------------------------------------------------
# reference snapshot lifecycle
# --------------------------------------------------------------------------

_active_ref = [None]
# In-flight `btrfs send`/`receive` processes.  They keep the reference
# subvolume busy, so the signal handler has to drop them before it can delete.
_active_children = set()
_children_lock = threading.RLock()


def _delete_ref(path: str) -> None:
    """Delete the reference subvolume. Best-effort: cleanup paths call this."""
    if not os.path.lexists(path) or not is_subvolume(path):
        return
    subprocess.run(
        [BTRFS, "subvolume", "delete", path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def _cleanup_ref() -> None:
    path, _active_ref[0] = _active_ref[0], None
    if path is not None:
        _delete_ref(path)


def _on_signal(signum, _frame) -> None:
    # `btrfs subvolume delete` fails while a `btrfs send` still has the
    # reference open, so the in-flight pipelines go first: otherwise an
    # interrupted run would leave the reference snapshot behind, pinning the
    # live data it captured.
    with _children_lock:
        children = list(_active_children)
    for child in children:
        try:
            child.kill()
        except OSError:
            pass
    for child in children:
        try:
            child.wait(timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            pass
    _cleanup_ref()
    signal.signal(signum, signal.SIG_DFL)
    os.kill(os.getpid(), signum)


def create_ref(ref: str, live: str) -> None:
    if os.path.lexists(ref) and not is_subvolume(ref):
        raise SnappsError(
            f"{ref} exists and is not a btrfs subvolume; snapps uses that name "
            "for its temporary read-only reference snapshot and will not touch "
            "anything else. Move it out of the way and retry."
        )
    if os.path.lexists(ref):
        # A reference can be left behind by a killed run, and it pins a copy of
        # the live data taken when it was made, so it has to go -- but say so
        # rather than quietly reclaiming somebody else's snapshot.
        _progress(
            f"removing the stale reference snapshot at {ref} left behind by an "
            f"earlier run (it holds a copy of {live} from when it was created)"
        )
    _delete_ref(ref)
    result = subprocess.run(
        [BTRFS, "subvolume", "snapshot", "-r", live, ref],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise SnappsError(f"cannot snapshot {live}: {stderr_of(result)}")
    _active_ref[0] = ref
    atexit.register(_cleanup_ref)
    for signum in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(signum, _on_signal)


def remove_ref(ref: str) -> None:
    _active_ref[0] = None
    _delete_ref(ref)


# --------------------------------------------------------------------------
# btrfs send / receive --dump parsing
# --------------------------------------------------------------------------


def _parse_dump_line(line: bytes):
    """(title, tokens) of one dump line, or None when the line is unusable."""
    if len(line) < 16:
        return None
    title = line[:16].strip()
    tokens = _split_escaped(line[16:].rstrip(b"\r\n"))
    if not tokens:
        return None
    return title, tokens


def _relative(path: str, subvol_name: str):
    """Strip the send stream's `./<subvolume>/` prefix; None when unusable."""
    prefix = "./" + subvol_name + "/"
    if path.startswith(prefix):
        path = path[len(prefix) :]
    elif path.startswith("./"):
        parts = path.split("/", 2)
        path = parts[2] if len(parts) > 2 else ""
    # Everything below is joined onto a snapshot root and passed to lstat, so
    # only plain, single-slash-separated names may get through.
    if not path or path.startswith("/"):
        return None
    parts = path.split("/")
    if any(part in ("", ".", "..") for part in parts) or parts[0] == REF_NAME:
        return None
    return path


def diff_paths(ref: str, root: str, subvol_name: str, progress=None):
    """Paths the snapshot `root` holds that the reference does not have.

    `btrfs send --no-data -p REF ROOT` emits a metadata-only stream describing
    exactly the difference between the two subvolumes; `btrfs receive --dump`
    turns it into one text line per operation.  Paths that only exist in the
    reference show up as unlink/rmdir and are deliberately ignored: they are
    live data, not reclaimable snapshot content.

    Returns `(paths, shared, cloned)`: `shared` are the paths that the stream
    announced with a `link` operation -- entries pointing at an inode some other
    path already references (a hard link added inside the snapshot, or -- very
    commonly -- a file that was *renamed in the live subvolume* after the
    snapshot, which the kernel reports as `link ./s/old-name dest=new-name`).
    `cloned` maps a path to the number of bytes the stream says it shares with
    another file (`clone ... len=`), which is how reflink duplicates and
    fully-deduplicated files show up.  Removing one directory entry that either
    of those describes can never free its data.
    """
    err_send = tempfile.TemporaryFile()
    err_recv = tempfile.TemporaryFile()
    paths = set()
    shared = set()
    cloned = {}
    try:
        send = subprocess.Popen(
            [BTRFS, "send", "--no-data", "-p", ref, root],
            stdout=subprocess.PIPE,
            stderr=err_send,
        )
        try:
            recv = subprocess.Popen(
                [BTRFS, "receive", "--dump"],
                stdin=send.stdout,
                stdout=subprocess.PIPE,
                stderr=err_recv,
            )
        finally:
            send.stdout.close()
        with _children_lock:
            _active_children.update((send, recv))
        try:
            with recv.stdout:
                lines = 0
                for line in recv.stdout:
                    lines += 1
                    if not lines & 8191 and progress is not None:
                        progress.add_lines(lines)
                        lines = 0
                    # A dump is mostly chown/chmod/utimes/unlink lines that
                    # carry nothing we collect: keeping them out of the
                    # tokenizer roughly halves the parsing cost.
                    if line[:16].strip() not in OPS_OF_INTEREST:
                        continue
                    parsed = _parse_dump_line(line)
                    if parsed is None:
                        continue
                    title, tokens = parsed
                    # Must run before the filter below: `rename` is not a data
                    # operation, yet it carries the only real name a new
                    # directory, symlink, empty file or special file ever gets
                    # in the stream.
                    if title in DEST_OPS:
                        for token in tokens[1:]:
                            if token.startswith(b"dest="):
                                dest = _relative(
                                    os.fsdecode(_unescape(token[5:])), subvol_name
                                )
                                if dest is not None:
                                    paths.add(dest)
                    if title not in SNAPSHOT_OPS:
                        continue
                    relative = _relative(
                        os.fsdecode(_unescape(tokens[0])), subvol_name
                    )
                    if relative is None:
                        continue
                    paths.add(relative)
                    if title == b"link":
                        shared.add(relative)
                    elif title == b"clone":
                        length = _token_int(tokens[1:], b"len=")
                        if length is not None:
                            cloned[relative] = cloned.get(relative, 0) + length
                if lines and progress is not None:
                    progress.add_lines(lines)
            recv.wait()
            send.wait()
            # `btrfs receive --dump` stops reading the moment it consumes the
            # end-of-stream marker (common/send-stream.c breaks out of the read
            # loop there), so a `btrfs send` that still had the tail of its
            # final block queued is killed by SIGPIPE even though the dump is
            # complete.  A genuine failure always shows up somewhere else: a
            # truncated stream makes receive exit non-zero ("unexpected EOF in
            # stream" / "failed to dump the send stream"), and a real send error
            # is a status that is neither 0 nor SIGPIPE.
            if recv.returncode != 0 or send.returncode not in (0, -signal.SIGPIPE):
                raise SnappsError(
                    f"cannot diff {root} against {ref}: "
                    f"send(rc={send.returncode}) {_read_tempfile(err_send).strip()} "
                    f"receive(rc={recv.returncode}) "
                    f"{_read_tempfile(err_recv).strip()}"
                )
        finally:
            with _children_lock:
                _active_children.difference_update((send, recv))
    finally:
        err_send.close()
        err_recv.close()
    return paths, shared, cloned


def _token_int(tokens, prefix: bytes):
    """Value of the first `prefix<decimal>` token, or None."""
    for token in tokens:
        if token.startswith(prefix):
            try:
                return int(token[len(prefix) :])
            except ValueError:
                return None
    return None


def _read_tempfile(handle) -> str:
    handle.seek(0)
    return handle.read().decode(errors="replace")


# --------------------------------------------------------------------------
# btrfs extent ioctls: compression-exact sizes and global sharing
# --------------------------------------------------------------------------
#
# The metadata stream says *which* entries a snapshot holds on its own; it says
# nothing about how many bytes deleting one of them would free.  Two facts are
# needed for that, and `st_blocks` gets neither of them right:
#
#   * how many bytes a file's extents occupy on disk, compression included, and
#   * whether anything else on the filesystem references those extents.
#
# Both come from `BTRFS_IOC_TREE_SEARCH_V2`, the ioctl compsize is built on.
# For a size it is one call against the file's own subvolume tree, pinned to
# that inode's EXTENT_DATA items, reading `disk_num_bytes` of each
# `btrfs_file_extent_item`.  For sharing it is one call per extent into the
# extent tree, reading `btrfs_extent_item.refs`, the global reference count:
# `refs == 1` means nothing else references those bytes, so deleting the entry
# frees them.  Quota is never involved, and no file data is read.
#
# The extent-tree calls dominate (one random descent each), so they are issued
# in bytenr order, `_BTRFS_SEARCH_BATCH` extents per ioctl, which turns them
# into sequential leaf reads instead of one random descent per extent, and
# their results are cached by bytenr across snapshots -- the same extents recur
# in every snapshot that shares them.
#
# The ioctl needs root (EPERM otherwise) and a btrfs file; `extent_support()`
# probes for it once per run and the `st_blocks` heuristic is used when it is
# unavailable, or when `--fast` asks for it.

_BTRFS_IOCTL_MAGIC = 0x94
# struct btrfs_ioctl_search_key: 7 * u64 + 4 * u32 + 4 * u64.
_BTRFS_SEARCH_KEY_FMT = "<7Q4I4Q"
_BTRFS_SEARCH_KEY_SIZE = 104
# struct btrfs_ioctl_search_header: transid, objectid, offset, type, len.
_BTRFS_SEARCH_HDR_FMT = "<QQQII"
_BTRFS_SEARCH_HDR_SIZE = 32
# struct btrfs_extent_item: refs, generation, flags.
_BTRFS_EXTENT_ITEM_SIZE = 24
# struct btrfs_file_extent_item, up to and including `type`.
_BTRFS_FILE_EXTENT_HDR_FMT = "<QQBBHB"
_BTRFS_FILE_EXTENT_HDR_SIZE = 21
# ... and the full packed struct, which is what a non-inline extent needs.
_BTRFS_FILE_EXTENT_SIZE = 53
_BTRFS_EXTENT_DATA_KEY = 108
_BTRFS_EXTENT_ITEM_KEY = 168
_BTRFS_SHARED_DATA_REF_KEY = 184
_BTRFS_EXTENT_TREE = 2
_BTRFS_FILE_EXTENT_INLINE = 0
# _IOWR(BTRFS_IOCTL_MAGIC, 17, struct btrfs_ioctl_search_args_v2): the flexible
# buffer member makes the struct 112 bytes (the 104-byte key plus buf_size).
_BTRFS_IOC_TREE_SEARCH_V2 = 0xC0709411
_BTRFS_SEARCH_BATCH = 512
_BTRFS_SEARCH_BUF = 1 << 16
# How wide a bytenr range one extent-tree search may cover.  A range search
# returns *every* extent item in the range, not just the ones asked about, so
# batching by count alone degenerates into sweeping gigabytes whenever the
# wanted extents are scattered (which is the normal case: a snapshot's files
# were allocated at unrelated times).  Bounding the span keeps each search
# proportional to the extents actually wanted.
_BTRFS_REF_SPAN = 256 << 20
# bytenr -> refs for the whole run.  The cap keeps a 64-snapshot run bounded;
# a cleared cache only costs time, never correctness.
_REF_CACHE_LIMIT = 1 << 21
# Extent refcounts are only worth computing when the wanted set is small or
# dense: a range search returns every extent item in the span it covers, so
# scattered wanted bytenrs pay far more parsing than the answers are worth.
# Beyond this many scanned items the pass gives up rather than crawl.
_REF_SCAN_LIMIT = 400_000_000
_ref_cache: dict = {}


def _iter_search(
    fd: int,
    tree: int,
    min_objectid: int,
    max_objectid: int,
    min_type: int,
    max_type: int,
    count: int = _BTRFS_SEARCH_BATCH,
    buf_size: int = _BTRFS_SEARCH_BUF,
):
    """Yield `(objectid, offset, type, item)` for a key range, paging by cursor.

    The kernel reports how many items it wrote into the flexible result buffer,
    never how many bytes, so a batch shorter than the requested count is the
    only exhaustion signal -- parsing on to the end of the buffer would re-read
    the same batch for ever.  Paging advances the `(objectid, offset)` cursor
    rather than the offset alone, or items at higher objectids would be skipped
    whenever a batch spans several inodes.
    """
    cursor_objectid, cursor_offset = min_objectid, 0
    while True:
        key = struct.pack(
            _BTRFS_SEARCH_KEY_FMT,
            tree,
            cursor_objectid,
            max_objectid,
            cursor_offset,
            (1 << 64) - 1,
            0,
            (1 << 64) - 1,
            min_type,
            max_type,
            count,
            0,
            0,
            0,
            0,
            0,
        )
        buffer = bytearray(_BTRFS_SEARCH_KEY_SIZE + 8 + buf_size)
        buffer[:_BTRFS_SEARCH_KEY_SIZE] = key
        struct.pack_into("<Q", buffer, _BTRFS_SEARCH_KEY_SIZE, buf_size)
        fcntl.ioctl(fd, _BTRFS_IOC_TREE_SEARCH_V2, buffer, True)
        found = struct.unpack_from(_BTRFS_SEARCH_KEY_FMT, buffer, 0)[9]
        data = bytes(buffer[_BTRFS_SEARCH_KEY_SIZE + 8 :])
        position = 0
        last = None
        for _ in range(found):
            if position + _BTRFS_SEARCH_HDR_SIZE > len(data):
                break
            _transid, objectid, offset, item_type, length = struct.unpack_from(
                _BTRFS_SEARCH_HDR_FMT, data, position
            )
            position += _BTRFS_SEARCH_HDR_SIZE
            item = data[position : position + length]
            position += length
            last = (objectid, offset)
            yield objectid, offset, item_type, item
        if found < count or last is None:
            return
        cursor_objectid, cursor_offset = last[0], last[1] + 1


def iter_extent_usage(fd: int, inode: int):
    """Yield `(bytenr, disk_num_bytes)` per data extent of `inode`.

    Holes are skipped (they occupy nothing) and so is inline data: an inline
    extent lives in the file's own metadata item, so deleting that one file
    frees no data block at all.
    """
    for _objectid, _offset, _type, item in _iter_search(
        fd, 0, inode, inode, _BTRFS_EXTENT_DATA_KEY, _BTRFS_EXTENT_DATA_KEY
    ):
        if len(item) < _BTRFS_FILE_EXTENT_HDR_SIZE:
            continue
        _generation, _ram, _comp, _enc, _other, kind = struct.unpack_from(
            _BTRFS_FILE_EXTENT_HDR_FMT, item, 0
        )
        if kind == _BTRFS_FILE_EXTENT_INLINE or len(item) < _BTRFS_FILE_EXTENT_SIZE:
            continue
        bytenr, disk_num_bytes = struct.unpack_from(
            "<QQ", item, _BTRFS_FILE_EXTENT_HDR_SIZE
        )
        if bytenr == 0:  # a hole
            continue
        yield bytenr, disk_num_bytes


def _extent_refs(fd: int, bytenrs) -> dict:
    """`{bytenr: refs}` for a bytenr list, filling `_ref_cache` as it goes.

    One ioctl per `_BTRFS_SEARCH_BATCH` extents of the sorted set, so the
    extent tree is walked forward instead of descended into at random for every
    single extent.  A bytenr with no extent item in range (freed between the
    size pass and this one) is recorded as None, i.e. "not known to be
    exclusive", which under-reports rather than over-reports.
    """
    wanted = {bytenr for bytenr in bytenrs if bytenr not in _ref_cache}
    scanned = 0
    if wanted:
        if len(_ref_cache) > _REF_CACHE_LIMIT:
            _ref_cache.clear()
        ordered = sorted(wanted)
        start = 0
        while start < len(ordered):
            # Grow the chunk while it stays both small in count and narrow in
            # span, so the search reads roughly the extents it is asked about.
            span_end = ordered[start] + _BTRFS_REF_SPAN
            end = start + 1
            while (
                end < len(ordered)
                and end - start < _BTRFS_SEARCH_BATCH
                and ordered[end] <= span_end
            ):
                end += 1
            chunk = ordered[start:end]
            scanned += len(chunk)
            if scanned > _REF_SCAN_LIMIT:
                raise SnappsError(
                    "the extent refcount pass would scan "
                    f"{scanned:,}+ extent-tree items for {len(ordered):,} extents; "
                    "use the default mode (or --fast) instead"
                )
            for objectid, _offset, item_type, item in _iter_search(
                fd,
                _BTRFS_EXTENT_TREE,
                chunk[0],
                chunk[-1],
                _BTRFS_EXTENT_ITEM_KEY,
                _BTRFS_SHARED_DATA_REF_KEY,
            ):
                if item_type != _BTRFS_EXTENT_ITEM_KEY:
                    continue
                if len(item) < _BTRFS_EXTENT_ITEM_SIZE or objectid in _ref_cache:
                    continue
                _ref_cache[objectid] = struct.unpack_from("<Q", item, 0)[0]
            start = end
        # A bytenr with no extent item in its range was freed underneath us.
        for bytenr in ordered:
            _ref_cache.setdefault(bytenr, None)
    return {bytenr: _ref_cache.get(bytenr) for bytenr in bytenrs}


def extent_support(root: str) -> bool:
    """Whether the extent ioctls work here: root, btrfs, and a live ioctl.

    Probing once per run keeps one snapshot from being reported with one
    mechanism and the next with the other, whose numbers do not mean the same
    thing.
    """
    try:
        fd = os.open(root, os.O_RDONLY)
    except OSError:
        return False
    try:
        # An empty range: the call succeeding is the whole point.
        for _ in _iter_search(
            fd, 0, 0, 0, _BTRFS_EXTENT_DATA_KEY, _BTRFS_EXTENT_DATA_KEY, count=1
        ):
            pass
        return True
    except OSError:
        return False
    finally:
        os.close(fd)


# --------------------------------------------------------------------------
# per-entry facts and exclusivity
# --------------------------------------------------------------------------



def exact_entries(root: str, paths, progress=None, refcounts: bool = True) -> list:
    """Rows whose size column is the bytes deleting them would really free.

    One EXTENT_DATA query per file gives each extent's on-disk (compressed)
    size; one batched extent-tree query per 512 extents gives their global
    reference counts.  An entry's number is the sum of its exclusively-owned
    extents, so a partially shared file contributes exactly its private bytes
    -- which is the case `st_blocks` cannot express, and the reason a 10 MiB
    file of zeros is reported as 320 KiB rather than 10 MiB.  Inline extents
    (whose data lives in metadata) and entries with more than one link
    contribute nothing: deleting one directory entry frees no data block.
    """
    rows = []
    pending = []  # [(row index, [(bytenr, disk_num_bytes), ...])]
    seen = 0
    unsized = 0
    try:
        fd = os.open(root, os.O_RDONLY)
    except OSError as error:
        raise SnappsError(f"cannot open {root}: {error.strerror}") from None
    try:
        for relative in sorted(paths):
            if progress is not None:
                seen += 1
                if not seen & 8191:
                    progress.add_paths(8192)
            try:
                st = os.lstat(os.path.join(root, relative))
            except OSError:
                continue  # raced with the deletion of the snapshot
            if stat.S_ISDIR(st.st_mode):
                rows.append((relative, True, 0, 0, 0, 0))
                continue
            index = len(rows)
            rows.append((relative, False, 0, st.st_ino, st.st_size, st.st_mtime_ns))
            if st.st_nlink > 1:
                continue  # another link keeps every extent alive
            try:
                extents = list(dict.fromkeys(iter_extent_usage(fd, st.st_ino)))
            except OSError:
                unsized += 1
                continue
            if not extents:
                continue
            if refcounts:
                pending.append((index, extents))
            else:
                row = rows[index]
                total = sum(size for _bytenr, size in extents)
                rows[index] = (row[0], row[1], total, row[3], row[4], row[5])
        if pending:
            bytenrs = sorted(
                {bytenr for _index, extents in pending for bytenr, _size in extents}
            )
            if progress is not None:
                progress.add_extents(len(bytenrs))
            refs = _extent_refs(fd, bytenrs)
            for index, extents in pending:
                freed = 0
                for bytenr, disk_num_bytes in extents:
                    if refs.get(bytenr) == 1:
                        freed += disk_num_bytes
                if freed:
                    row = rows[index]
                    rows[index] = (row[0], row[1], freed, row[3], row[4], row[5])
            del pending
    finally:
        os.close(fd)
    if progress is not None and seen:
        progress.add_paths(seen & 8191)
    if unsized:
        _progress(
            f"{unsized} entr{'y' if unsized == 1 else 'ies'} in {root} could not be "
            "sized exactly and count as 0 bytes"
        )
    return rows


def _extent_size(fd: int, st) -> int:
    """On-disk bytes of every extent an inode references, compression included.

    One EXTENT_DATA query per inode; no extent-tree access, so this stays cheap
    (~15 us/file) and is what replaces `st_blocks`, which counts the file's
    logical blocks and therefore over-reports compressed data by the
    compression ratio (10 MiB of zeros is 320 KiB, not 10 MiB).
    """
    total = 0
    seen = set()
    for bytenr, disk_num_bytes in iter_extent_usage(fd, st.st_ino):
        if bytenr in seen:
            continue
        seen.add(bytenr)
        total += disk_num_bytes
    return total


def stat_entries(
    root: str, paths, shared: frozenset, cloned: dict, progress=None, sizes: bool = False
) -> list:
    """(path, is_dir, blocks, ino, size, mtime_ns) for every diffed path.

    Entries in `shared` hold no data of their own: their inode is referenced by
    another path (in the snapshot or in the live subvolume), so deleting this
    one directory entry frees nothing and they are reported with 0 bytes.  The
    same goes for a file the stream reports as cloned end to end (`cloned`),
    i.e. one whose extents are shared with another file, and for an inode with
    more than one link, where removing this entry alone frees nothing.

    With `sizes`, the byte count comes from the file's own extents instead of
    `st_blocks`.  That is compression-exact and still requires no extent-tree
    walk: how much of a file is shared is then decided by the identity and
    link/clone rules above, exactly as in the `st_blocks` mode.
    """
    rows = []
    seen = 0
    fd = os.open(root, os.O_RDONLY) if sizes else None
    unsized = 0
    try:
        for relative in sorted(paths):
            if progress is not None:
                seen += 1
                if not seen & 8191:
                    progress.add_paths(8192)
            try:
                st = os.lstat(os.path.join(root, relative))
            except OSError:
                continue  # raced with the deletion of the snapshot, or a temp name
            if stat.S_ISDIR(st.st_mode):
                rows.append((relative, True, 0, 0, 0, 0))
                continue
            if sizes:
                try:
                    blocks = _extent_size(fd, st)
                except OSError:
                    unsized += 1
                    blocks = st.st_blocks * 512
            else:
                blocks = st.st_blocks * 512
            if (
                st.st_nlink > 1
                or relative in shared
                or cloned.get(relative, 0) >= st.st_size > 0
            ):
                blocks = 0
            rows.append(
                (
                    relative,
                    False,
                    blocks,
                    st.st_ino,
                    st.st_size,
                    st.st_mtime_ns,
                )
            )
    finally:
        if fd is not None:
            os.close(fd)
    if progress is not None and seen:
        progress.add_paths(seen & 8191)
    if unsized:
        _progress(
            f"{unsized} entr{'y' if unsized == 1 else 'ies'} in {root} could not be "
            "sized from their extents; st_blocks was used instead"
        )
    return rows


class ExclusiveKeys:
    """Identities that appear in more than one snapshot, and nothing else.

    snapper snapshots share inodes: an unchanged file has one inode with the
    same size and mtime in every snapshot that contains it, and its extents are
    shared, so deleting it from one snapshot frees nothing.  Only an identity
    `(path, inode, size, mtime)` that exists in exactly one snapshot is
    reclaimable.

    A 64-snapshot `/home` produces tens of millions of rows, so the rows
    themselves cannot be held in memory: only the 64-bit `hash` of the identity
    is kept.  A hash collision can only make an exclusive entry look shared,
    i.e. under-report, never over-report.
    """

    def __init__(self):
        self._seen = set()
        self._shared = set()

    @staticmethod
    def _identity(row):
        return hash((row[0], row[3], row[4], row[5]))

    def add(self, rows):
        seen, shared = self._seen, self._shared
        for row in rows:
            if row[1]:  # directories carry no data and never share an identity
                continue
            key = hash((row[0], row[3], row[4], row[5]))
            if key in seen:
                shared.add(key)
            else:
                seen.add(key)

    def blocks_of(self, row) -> int:
        """The bytes deleting this entry would free, 0 when it shares them."""
        if row[1] or self._identity(row) in self._shared:
            return 0
        return row[2]


# --------------------------------------------------------------------------
# ncdu JSON for gdu
# --------------------------------------------------------------------------


def _write_json_string(out, value: str) -> None:
    out.write(json.dumps(value, separators=(",", ":")))


def _write_dir(out, name: str, children: dict) -> None:
    """`[{"name": NAME}, ...children]`: gdu reads directories as arrays."""
    out.write('[{"name":')
    _write_json_string(out, name)
    out.write("}")
    for child in sorted(children):
        value = children[child]
        out.write(",")
        if isinstance(value, dict):
            _write_dir(out, child, value)
        else:
            out.write('{"name":')
            _write_json_string(out, child)
            out.write(',"asize":%d,"dsize":%d}' % (value, value))
    out.write("]")


def build_trie(rows, freed) -> dict:
    """One snapshot's tree: nested dicts for directories, byte counts for files.

    `freed` maps a row to the bytes deleting it would free.  In exact mode the
    rows already carry that number; in the `st_blocks` mode the cross-snapshot
    identity decision (`ExclusiveKeys.blocks_of`) is applied here rather than
    stored, so the rows on disk stay independent of it.
    """
    children = {}
    for row in rows:
        path, is_dir = row[0], row[1]
        parts = path.split("/")
        node = children
        for part in parts[:-1]:
            child = node.get(part)
            if not isinstance(child, dict):
                child = node[part] = {}
            node = child
        leaf = parts[-1]
        if is_dir:
            node.setdefault(leaf, {})
        else:
            node[leaf] = freed(row)
    return children


def write_report(
    out, snapshot_dir: str, rows_iter, freed, scope, expected: int
) -> None:
    """Stream the ncdu document gdu imports, one snapshot at a time.

    `rows_iter` yields `(snapshot_id, rows)`; each snapshot's rows are released
    before the next is read, so peak memory is one snapshot's worth of rows no
    matter how many snapshots or rows there are in total.
    """
    out.write('[1,2,{"progname":"snapps","progver":')
    _write_json_string(out, VERSION)
    out.write(',"timestamp":%d},[{"name":' % int(time.time()))
    _write_json_string(out, snapshot_dir)
    out.write("}")
    written = 0
    for snapshot_id, rows in rows_iter:
        written += 1
        if scope is not None:
            prefix = scope + "/"
            rows = [row for row in rows if row[0] == scope or row[0].startswith(prefix)]
        if not rows:
            # A leaf, so gdu pins the zeros instead of recomputing them.
            out.write(',{"name":')
            _write_json_string(out, snapshot_id)
            out.write(',"asize":0,"dsize":0,"items":1}')
            continue
        out.write(",")
        _write_dir(out, snapshot_id, build_trie(rows, freed))
    out.write("]]\n")
    if written != expected:
        raise SnappsError(
            f"only {written} of {expected} snapshots are available in the cache; "
            "rerun with --no-cache"
        )


class _Heartbeat(threading.Thread):
    """Say how far along the run is, every so often.

    One `btrfs send` over a million-inode `/home` takes minutes, and a snapshot
    only counts as done once its diff *and* its stat pass are finished, so the
    completed count alone can sit at zero for many minutes.  The line counter is
    the honest liveness signal.
    """

    def __init__(self, total: int, interval: float = 20.0):
        super().__init__(daemon=True)
        self._snapshots = total
        self._interval = interval
        self._finished = 0
        self._lines = 0
        self._paths = 0
        self._extents = 0
        self._count_lock = threading.Lock()
        self._shutdown = threading.Event()
        self._began = time.monotonic()

    def progress(self, done: int) -> None:
        self._finished = done

    def add_lines(self, count: int) -> None:
        with self._count_lock:
            self._lines += count

    def add_paths(self, count: int) -> None:
        with self._count_lock:
            self._paths += count

    def add_extents(self, count: int) -> None:
        with self._count_lock:
            self._extents += count

    def _counts(self):
        with self._count_lock:
            return self._lines, self._paths, self._extents

    def run(self) -> None:
        while not self._shutdown.wait(self._interval):
            lines, paths, extents = self._counts()
            _progress(
                f"still working: {self._finished}/{self._snapshots} snapshots done, "
                f"{lines:,} dump lines read, {paths:,} entries statted, "
                f"{extents:,} extents resolved, "
                f"{int(time.monotonic() - self._began)}s elapsed"
            )

    def stop(self) -> None:
        self._shutdown.set()


# --------------------------------------------------------------------------
# cache
# --------------------------------------------------------------------------


def cache_path(snapshot_dir: str) -> str:
    digest = hashlib.sha256(os.fsencode(os.path.abspath(snapshot_dir))).hexdigest()
    return os.path.join(CACHE_DIR, digest + ".jsonl")


class CacheWriter:
    """Spill each snapshot's rows to disk as they are produced.

    One JSON object per line: a header (schema, the live generation, and every
    snapshot's generation) followed by one record per snapshot.  Keeping the
    rows on disk instead of in memory is what makes a 64-snapshot `/home` with
    a million differing entries per snapshot tractable at all.
    """

    def __init__(
        self, snapshot_dir: str, live_gen, snapshots, keep_cache: bool, mode: str
    ):
        self._mode = mode
        self._final = cache_path(snapshot_dir)
        self._spill = self._final + ".spill"
        self._keep_cache = keep_cache
        self._handle = None
        try:
            # Owner-only: the rows are snapshot paths, which are not necessarily
            # readable by other users.
            os.makedirs(CACHE_DIR, mode=0o700, exist_ok=True)
            handle, tmp = tempfile.mkstemp(prefix="snapps-cache-", dir=CACHE_DIR)
            # "w+" so the report can be streamed back out of the same descriptor
            # even if the file is unlinked underneath us.
            self._handle = os.fdopen(handle, "w+")
            self._spill = tmp
        except OSError as error:
            raise SnappsError(
                f"cannot create a spill file in {CACHE_DIR}: {error.strerror}"
            ) from None
        header = {
            "schema": CACHE_SCHEMA,
            "live_gen": live_gen,
            "mode": self._mode,
            "snapshots": {snap.id: snap.gen for snap in snapshots},
        }
        self._write(header)

    def _write(self, record: dict) -> None:
        try:
            json.dump(record, self._handle, separators=(",", ":"))
            self._handle.write("\n")
        except OSError as error:
            # The rows only exist in this file, so losing them mid-run would mean
            # reporting a snapshot from a partial row set.
            raise SnappsError(
                f"cannot write to the spill file in {CACHE_DIR}: {error.strerror}"
            ) from None

    def write(self, snapshot_id: str, rows) -> None:
        self._write({"id": snapshot_id, "entries": rows})

    @property
    def spill_path(self) -> str:
        """Where the rows currently live (a throwaway file with --no-cache)."""
        return self._spill

    def keep(self):
        """Flush, publish the spill (best effort) and return a readable handle.

        Reading back through the open descriptor rather than by path means the
        report survives somebody removing the cache directory mid-run (a
        cleanup, a garbage collection) -- the rows exist in the descriptor
        either way.  With `--no-cache` the spill is a throwaway file that
        `view_main` removes once the report is written.
        """
        flush_and_seek(self._handle)
        if self._keep_cache:
            try:
                os.replace(self._spill, self._final)
            except OSError:
                pass
        return self._handle

    def discard(self) -> None:
        if self._handle is not None:
            try:
                self._handle.close()
            except OSError:
                pass
            self._handle = None
            try:
                os.unlink(self._spill)
            except OSError:
                pass


def flush_and_seek(handle) -> None:
    """Rewind a spill/cache handle so it can be read back from the start."""
    handle.flush()
    handle.seek(0)


def open_cache(snapshot_dir: str, live_gen: int, snapshots, mode: str):
    """The cache path when its header still applies, otherwise None.

    `live_gen` is the generation the live subvolume must have for the cached
    rows to describe it.  It is read at the very start of a run and written back
    unchanged at the end, because neither generation available *during* a run
    describes what the next run will see (measured: the reference's own
    generation was 27-29 while live sat at 23, and creating the reference does
    not move live at all).
    """
    path = cache_path(snapshot_dir)
    try:
        with open(path, "r") as handle:
            header = json.loads(handle.readline())
    except (OSError, ValueError):
        return None
    if not isinstance(header, dict) or header.get("schema") != CACHE_SCHEMA:
        return None
    if header.get("live_gen") != live_gen:
        return None
    if header.get("mode") != mode:
        # st_blocks, extent sizes and refcount-filtered bytes are not
        # interchangeable.
        return None
    cached = header.get("snapshots")
    if not isinstance(cached, dict):
        return None
    if set(cached) != {snap.id for snap in snapshots}:
        # A snapshot appearing or disappearing changes what every other one
        # shares with, so all rows have to be rebuilt.
        return None
    for snap in snapshots:
        if not snap.gen or str(cached.get(snap.id)) != str(snap.gen):
            return None
    return path


def iter_cached_rows(source):
    """Yield `(snapshot_id, rows)` per record, one snapshot in memory at a time.

    `source` is a path or an already-open handle; a handle is rewound and left
    open for the caller, which is what keeps the report working when the cache
    file is deleted underneath a running process.
    """
    if hasattr(source, "read"):
        flush_and_seek(source)
        handle, owned, label = source, False, getattr(source, "name", "<handle>")
    else:
        try:
            handle, owned = open(source, "r"), True
        except OSError as error:
            raise SnappsError(
                f"cannot read the row store {source}: {error.strerror}"
            ) from None
        label = source
    try:
        handle.readline()  # header, already validated by open_cache()
        for line in handle:
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except ValueError:
                raise SnappsError(f"cache is corrupt: {label}") from None
            if not isinstance(record, dict) or not isinstance(
                record.get("entries"), list
            ):
                raise SnappsError(f"cache is corrupt: {label}")
            yield record.get("id"), [tuple(row) for row in record["entries"]]
    finally:
        if owned:
            handle.close()


# --------------------------------------------------------------------------
# entry points
# --------------------------------------------------------------------------


def _progress(message: str) -> None:
    print(f"snapps: {message}", file=sys.stderr, flush=True)


def _diff_one(ref: str, snap, progress, mode: str) -> list:
    """Paths this snapshot holds that the reference does not, with their facts."""
    paths, shared, cloned = diff_paths(
        ref, snap.root, os.path.basename(snap.root), progress
    )
    if mode == "refs":
        # Refcounts answer sharing directly, so the link and clone hints the
        # stream provided are not needed.
        return exact_entries(snap.root, paths, progress)
    return stat_entries(
        snap.root, paths, frozenset(shared), cloned, progress, sizes=mode == "sizes"
    )


def collect(snapshots, ref: str, jobs: int, on_snapshot, mode: str) -> None:
    """Diff every snapshot in parallel and hand each result to `on_snapshot`.

    The rows are handed over and then dropped, so nothing accumulates: a
    `/home` with 64 snapshots and a million differing entries each would need
    tens of gigabytes if they were all kept.
    """
    total = len(snapshots)
    heartbeat = _Heartbeat(total)
    heartbeat.start()
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
            futures = {
                pool.submit(_diff_one, ref, snap, heartbeat, mode): snap
                for snap in snapshots
            }
            for done, future in enumerate(
                concurrent.futures.as_completed(futures), start=1
            ):
                snap = futures[future]
                rows = future.result()
                heartbeat.progress(done)
                on_snapshot(snap, rows, done, total)
                del rows
    finally:
        heartbeat.stop()


def view_main(argv) -> int:
    parser = argparse.ArgumentParser(
        prog="snapps",
        description="Browse snapper snapshots with gdu: every snapshot with the "
        "space it holds by itself, and the differing files and folders inside "
        "it with what deleting each would free.",
        epilog="Use `snapps rm SNAPSHOT_DIR PATH` to delete a path from every "
        "snapshot.",
    )
    parser.add_argument(
        "snapshot_dir",
        metavar="SNAPSHOT_DIR",
        help="directory containing the snapshot directories",
    )
    parser.add_argument(
        "path",
        metavar="PATH",
        nargs="?",
        default=None,
        help="absolute path to restrict the browser to",
    )
    parser.add_argument(
        "--dump",
        action="store_true",
        help="write the gdu import JSON to stdout instead of browsing",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=0,
        metavar="N",
        help="snapshots to diff at a time (default: 8, or the CPU count if "
        "lower); each one runs a btrfs send/receive pipeline and a stat pass",
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        help="size entries by st_blocks instead of their extents (compression "
        "is then ignored)",
    )
    parser.add_argument(
        "--extent-refs",
        action="store_true",
        help="also read the global refcount of every extent, so partial "
        "sharing is exact -- but this walks the extent tree and can take a "
        "long time on a large filesystem",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="recompute the diffs even if a valid cache exists",
    )
    args = parser.parse_args(argv)

    try:
        _check_euid()
        snapshot_dir = os.path.abspath(args.snapshot_dir)
        if not os.path.isdir(snapshot_dir):
            raise SnappsError(f"not a directory: {snapshot_dir}")
        live = os.path.dirname(snapshot_dir)
        info = subvolume_info(live)
        if not info:
            raise SnappsError(f"not a btrfs subvolume: {live}")
        if info.get("Subvolume ID") == "5":
            raise SnappsError(
                f"{live} is the btrfs top-level subvolume, which cannot be "
                "snapshotted or sent"
            )
        scope = None
        if args.path is not None:
            try:
                scope = snapshot_relative_path(args.path)[1:]
            except ValueError as error:
                raise SnappsError(str(error)) from None
        snapshots = load_snapshots(snapshot_dir)
        if not snapshots:
            raise SnappsError(f"no snapshots in {snapshot_dir}")
    except SnappsError as error:
        print(f"snapps: {error}", file=sys.stderr)
        return 1

    # One mode for the whole run: the three ways of sizing an entry are not
    # interchangeable, so a snapshot must never be sized one way and the next
    # another.  "sizes" is extent-exact and cheap; "blocks" needs no ioctls at
    # all; "refs" additionally resolves global sharing, at extent-tree cost.
    if args.fast:
        mode = "blocks"
    elif args.extent_refs:
        mode = "refs"
    else:
        mode = "sizes"
    if mode != "blocks" and not extent_support(live):
        _progress(
            "extent ioctls unavailable (they need root on btrfs); falling back to "
            "st_blocks, which ignores compression"
        )
        mode = "blocks"
    if mode == "refs":
        _progress(
            "resolving global extent refcounts as well: exact sharing, but it "
            "walks the extent tree"
        )

    live_gen = subvolume_generation(live)
    exclusive = ExclusiveKeys()
    if args.jobs > 0:
        jobs = args.jobs
    else:
        # One snapshot per worker: the kernel side runs in the btrfs
        # send/receive processes and the extent ioctls release the GIL, so
        # these really do overlap.
        jobs = min(8, os.cpu_count() or 4)

    cached = None
    if not args.no_cache:
        cached = open_cache(snapshot_dir, live_gen, snapshots, mode)
        if cached:
            _progress(f"using the cache in {CACHE_DIR} (--no-cache recomputes)")

    if cached is None:
        ref = ref_path(snapshot_dir)
        _progress(
            f"diffing {len(snapshots)} snapshot(s) against {ref}: one btrfs send "
            f"and one stat pass over the subvolume per snapshot, {jobs} at a time; "
            "this takes minutes and is cached for the next run"
        )
        create_ref(ref, live)
        writer = CacheWriter(
            snapshot_dir, live_gen, snapshots, not args.no_cache, mode
        )
        try:

            def on_snapshot(snap, rows, done, total):
                if mode != "refs":
                    # "refs" rows already carry their own sharing decision.
                    exclusive.add(rows)
                writer.write(snap.id, rows)
                _progress(
                    f"[{done}/{total}] snapshot {snap.id}: {len(rows)} differing "
                    f"entr{'y' if len(rows) == 1 else 'ies'}"
                )

            collect(snapshots, ref, jobs, on_snapshot, mode)
        except BaseException:
            writer.discard()
            raise
        finally:
            remove_ref(ref)
        rows_handle = writer.keep()
    else:
        # Opened once and kept open, so the report still works if the cache
        # file disappears while the run is in progress.
        try:
            rows_handle = open(cached, "r")
        except OSError as error:
            print(
                f"snapps: cannot read the cache {cached}: {error.strerror}",
                file=sys.stderr,
            )
            return 1

    # In `st_blocks` mode the rows on disk carry no cross-snapshot exclusivity
    # decision, so a cache hit has to be scanned once to rebuild it before the
    # report is written.  Exact rows need nothing.
    if cached is not None and mode != "refs":
        for _snapshot_id, rows in iter_cached_rows(rows_handle):
            exclusive.add(rows)
            del rows

    freed = (lambda row: row[2]) if mode == "refs" else exclusive.blocks_of

    try:
        if args.dump:
            try:
                write_report(
                    sys.stdout,
                    snapshot_dir,
                    iter_cached_rows(rows_handle),
                    freed,
                    scope,
                    len(snapshots),
                )
                sys.stdout.flush()
            except BrokenPipeError:
                # `snapps --dump DIR | head` and friends: redirect the
                # interpreter's final flush to /dev/null so it does not print a
                # broken-pipe traceback on shutdown.
                devnull = os.open(os.devnull, os.O_WRONLY)
                os.dup2(devnull, sys.stdout.fileno())
                os.close(devnull)
                return 1
            return 0

        try:
            handle, path = tempfile.mkstemp(prefix="snapps-", suffix=".json")
        except OSError as error:
            print(
                f"snapps: cannot create a temporary file: {error.strerror}",
                file=sys.stderr,
            )
            return 1
        try:
            with os.fdopen(handle, "w") as stream:
                write_report(
                    stream,
                    snapshot_dir,
                    iter_cached_rows(rows_handle),
                    freed,
                    scope,
                    len(snapshots),
                )
            try:
                return subprocess.run(
                    [
                        GDU,
                        "-f",
                        path,
                        "--no-delete",
                        "--no-view-file",
                        "--no-spawn-shell",
                    ]
                ).returncode
            except FileNotFoundError:
                print(f"snapps: {GDU} not found in PATH", file=sys.stderr)
                return 1
        finally:
            os.unlink(path)
    finally:
        rows_handle.close()
        if args.no_cache:
            # --no-cache borrows the cache directory for a throwaway spill only.
            try:
                os.unlink(writer.spill_path)
            except OSError:
                pass


def rm_main(argv) -> int:
    parser = argparse.ArgumentParser(
        prog="snapps rm",
        description="Remove a file or directory from every snapper snapshot "
        "(equivalent to `snapperS -d DIR rm --recursive -f PATH`).",
    )
    parser.add_argument(
        "snapshot_dir",
        metavar="SNAPSHOT_DIR",
        help="directory containing the snapshot directories",
    )
    parser.add_argument(
        "path",
        metavar="PATH",
        help="absolute path to remove, relative to each snapshot root",
    )
    args = parser.parse_args(argv)

    if os.geteuid() != 0:
        print("snapps: must be run as root", file=sys.stderr)
        return 1

    try:
        relative = snapshot_relative_path(args.path)
    except ValueError as error:
        print(f"snapps: {error}", file=sys.stderr)
        return 2

    snapshot_dir = os.path.abspath(args.snapshot_dir)
    if not os.path.isdir(snapshot_dir):
        print(f"snapps: not a directory: {snapshot_dir}", file=sys.stderr)
        return 2

    removed = 0
    for name in sorted(os.listdir(snapshot_dir), key=snapshot_sort_key):
        snapshot_root = os.path.join(snapshot_dir, name, "snapshot")
        target = snapshot_root + relative
        # Defensive: never leave the snapshot directory, whatever `name` is.
        if not target.startswith(snapshot_root + os.sep) or not os.path.lexists(target):
            continue
        # Only ever modify real snapshot subvolumes.
        if not is_subvolume(snapshot_root):
            continue
        # A symlink *inside* the snapshot must not redirect the deletion into
        # the live filesystem.  Only the parent directory is resolved: the
        # final component is removed as a directory entry, never followed, so
        # deleting a symlink itself stays legitimate.
        real_root = os.path.realpath(snapshot_root)
        if not resolves_inside(os.path.dirname(target), real_root):
            print(
                f"snapps: refusing to delete {target}: it resolves outside "
                f"{snapshot_root}",
                file=sys.stderr,
            )
            continue

        result = set_subvolume_ro(snapshot_root, readonly=False)
        if result.returncode != 0:
            print(
                f"snapps: cannot make {snapshot_root} writable: {stderr_of(result)}",
                file=sys.stderr,
            )
            return 3
        try:
            remove_recursive(target)
        finally:
            result = set_subvolume_ro(snapshot_root, readonly=True)
            if result.returncode != 0:
                print(
                    f"snapps: warning: {snapshot_root} left writable: "
                    f"{stderr_of(result)}",
                    file=sys.stderr,
                )
        removed += 1
        print(f"removed {relative} from {snapshot_root}", file=sys.stderr)

    _progress(f"removed from {removed} snapshot(s)")
    return 0


def main() -> int:
    argv = sys.argv[1:]
    if argv and argv[0] == "rm":
        return rm_main(argv[1:])
    return view_main(argv)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SnappsError as error:
        print(f"snapps: {error}", file=sys.stderr)
        sys.exit(1)
