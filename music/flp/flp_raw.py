"""Minimal raw reader/writer for FL Studio .flp event streams.

PyFLP's own save drops bytes from the playlist, so builds never call it.
This module keeps every event byte-for-byte and only rewrites the events a
build asks for. Works on any Python 3.

Event ids: 0-63 carry 1 byte, 64-127 2 bytes, 128-191 4 bytes, 192-255 a
varint length and that many bytes.
"""
from __future__ import annotations

import struct

TEMPO = 156          # DWORD+28: BPM * 1000
CHANNEL_NEW = 64     # WORD: starts a channel, value = channel iid
PATTERN_NEW = 65     # WORD+1: starts a pattern block, value = pattern iid
NOTES = 224          # DATA+16: pattern notes, 24 bytes each
PLAYLIST = 233       # DATA+25: playlist items, 32, 60 or 80 (FL 2024+) bytes each
PATTERN_BASE = 20480
CHANNEL_NAME = 203   # TEXT+11: channel display name, UTF-16LE, null-terminated

NOTE = struct.Struct("<IHHIHHBBBBBBBB")  # position flags channel length key group fine _ release midich pan vel modx mody


def item_size(data: bytes) -> int:
    """Playlist item size: 32 (old FL), 60 (FL 20-21) or 80 (FL 2024+). Picked
    as the size at which every item carries the pattern base 20480."""
    for size in (80, 60, 32):
        if len(data) % size == 0 and all(
                struct.unpack_from("<H", data, o + 4)[0] == PATTERN_BASE for o in range(0, len(data), size)):
            return size
    raise ValueError(f"unknown playlist item size ({len(data)} bytes)")


def utf16z(text: str) -> bytes:
    return text.encode("utf-16-le") + b"\0\0"


class Flp:
    def __init__(self, data: bytes):
        assert data[:4] == b"FLhd", "not an FL Studio project"
        hlen = struct.unpack_from("<I", data, 4)[0]
        self.header = data[: 8 + hlen]
        self.format, self.n_channels, self.ppq = struct.unpack_from("<hHH", data, 8)
        assert data[8 + hlen: 12 + hlen] == b"FLdt"
        pos = 16 + hlen
        self.events: list[list] = []  # [id, bytes]
        while pos < len(data):
            eid = data[pos]
            pos += 1
            if eid < 64:
                size = 1
            elif eid < 128:
                size = 2
            elif eid < 192:
                size = 4
            else:
                size, shift = 0, 0
                while True:
                    b = data[pos]
                    pos += 1
                    size |= (b & 0x7F) << shift
                    shift += 7
                    if not b & 0x80:
                        break
            self.events.append([eid, data[pos: pos + size]])
            pos += size

    @classmethod
    def load(cls, path: str) -> "Flp":
        with open(path, "rb") as f:
            return cls(f.read())

    def to_bytes(self) -> bytes:
        body = bytearray()
        for eid, payload in self.events:
            body.append(eid)
            if eid >= 192:
                n = len(payload)
                while True:
                    b = n & 0x7F
                    n >>= 7
                    body.append(b | (0x80 if n else 0))
                    if not n:
                        break
            body += payload
        return self.header + b"FLdt" + struct.pack("<I", len(body)) + bytes(body)

    def save(self, path: str) -> None:
        with open(path, "wb") as f:
            f.write(self.to_bytes())

    # --- helpers ---
    def value(self, i: int) -> int:
        eid, payload = self.events[i]
        return int.from_bytes(payload, "little")

    def find(self, eid: int) -> list[int]:
        return [i for i, e in enumerate(self.events) if e[0] == eid]

    def set_tempo(self, bpm: float) -> None:
        for i in self.find(TEMPO):
            self.events[i][1] = struct.pack("<I", int(round(bpm * 1000)))

    def channel_events(self, iid: int, eid: int) -> list[int]:
        """Indexes of event `eid` inside channel `iid`'s block."""
        current, out = None, []
        for i, (e, _) in enumerate(self.events):
            if e == CHANNEL_NEW:
                current = self.value(i)
            elif e in (PATTERN_NEW,):
                current = None
            elif e == eid and current == iid:
                out.append(i)
        return out

    def rename_channel(self, iid: int, name: str) -> None:
        idx = self.channel_events(iid, CHANNEL_NAME)
        if not idx:
            raise LookupError(f"channel {iid} has no name event")
        self.events[idx[0]][1] = utf16z(name)

    def notes_event(self, pattern_iid: int) -> int:
        """Index of the notes event inside pattern `pattern_iid`'s block(s)."""
        current = None
        for i, (eid, payload) in enumerate(self.events):
            if eid == PATTERN_NEW:
                current = self.value(i)
            elif eid == CHANNEL_NEW:
                current = None
            elif eid == NOTES and current == pattern_iid:
                return i
        raise LookupError(f"pattern {pattern_iid} has no notes; put one note per channel in it and save in FL")

    def set_notes(self, pattern_iid: int, notes: list[tuple]) -> None:
        """notes: (position_ticks, rack_channel, length_ticks, key, velocity[0-128], pan[0-128])."""
        out = bytearray()
        for pos, ch, length, key, vel, pan in sorted(notes):
            out += NOTE.pack(pos, 0x4000, ch, max(1, length), key, 0, 120, 0, 64, 0, pan, vel, 128, 128)
        self.events[self.notes_event(pattern_iid)][1] = bytes(out)

    def get_notes(self, pattern_iid: int) -> list[tuple]:
        data = self.events[self.notes_event(pattern_iid)][1]
        return [NOTE.unpack_from(data, o) for o in range(0, len(data), NOTE.size)]

    def set_pattern_clips(self, pattern_iid: int, length_ticks: int, start: int | None = 0) -> int:
        """Every playlist clip of the pattern gets this length, with explicit
        start/end offsets (FL otherwise renders to its own idea of the end)."""
        changed = 0
        for i in self.find(PLAYLIST):
            data = bytearray(self.events[i][1])
            size = item_size(data)
            for o in range(0, len(data), size):
                item_index = struct.unpack_from("<H", data, o + 6)[0]
                if item_index == PATTERN_BASE + pattern_iid:
                    if start is not None:
                        struct.pack_into("<I", data, o, start)
                    struct.pack_into("<I", data, o + 8, length_ticks)
                    struct.pack_into("<ii", data, o + 24, 0, length_ticks)
                    changed += 1
            self.events[i][1] = bytes(data)
        return changed
