# Tetris for GFOS

The AmiCradle Team's port of Stephen Brennan's curses Tetris
(github.com/brenns10/tetris) to GFOS: AmigaOS 3.2 with GFOpenUp,
68040/68060. It runs in its own 80 x 24 console window, in colour: no SDL,
no ACGame and no GFOpenGPU. It ships as a release archive with an
Installer and as the GFOpenUp part Parts/CursesTetris.

Upstream is fetched at build time (package/tetris.lock) and patched
(amiga/patches); this repository holds only the Amiga port. See
[AMIGA_PORT.md](AMIGA_PORT.md).

BSD-3-Clause, like Tetris (brenns10). Copyright (c) 2026 AmiCradle Team.
