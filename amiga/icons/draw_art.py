#!/usr/bin/env python3
"""Tetris' picture for its GlowIcons (art/tetris.png), drawn here:
upstream's picture is a screen recording. A dark well with a few rows of
coloured blocks at the bottom (one row about to clear) and a T piece
falling into its gap.
64 x 64, RGBA, solid or see-through.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. BSD-3-Clause like Tetris (brenns10), Copyright (c) 2026 AmiCradle Team."""
import struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                px[y][x] = c
    C = {"i": (60, 210, 230, 255), "j": (60, 90, 230, 255), "l": (235, 235, 235, 255),
         "o": (235, 210, 50, 255), "s": (70, 200, 80, 255), "t": (210, 70, 210, 255),
         "z": (230, 60, 60, 255)}
    S = 6                                           # a cell: 6 x 6, a dark line round it
    def cell(cx, cy, k):
        x0, y0 = 8 + cx * S, 8 + cy * S
        rect(x0, y0, x0 + S - 1, y0 + S - 1, C[k])
        rect(x0, y0, x0 + S - 1, y0 + 1, tuple(min(255, v + 50) for v in C[k][:3]) + (255,))
    rect(2, 2, 62, 62, (140, 140, 150, 255))        # the well's wall
    rect(6, 2, 58, 58, INK)
    WELL = ["........",
            "...ttt..",                             # the T falling
            "....t...",
            "........",
            "........",
            "zz......",
            "jzz..oo.",
            "jjjs.ool",
            "iiiissll"]
    for cy, row in enumerate(WELL):
        for cx, k in enumerate(row):
            if k != ".":
                cell(cx, cy, k)
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "amiga/icons/art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "tetris.png")
