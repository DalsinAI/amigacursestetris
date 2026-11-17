Tetris for GFOS
===============

Stephen Brennan's Tetris (2015): the falling-blocks game in a console
window, with the next piece, a held piece, levels and a score.

The cursor keys move (left, right), turn (up) and drop (down) the piece;
Space holds it (or swaps it with the held one); p pauses; s saves the game
and leaves; b is boss mode (F1 comes back); q ends the game.

A saved game waits in the drawer as tetris.save and carries on the next
time the game starts; the Installer keeps it when it updates the drawer.

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; no FPU. The game
runs in an 80 x 24 console window, in colour on a screen with eight pens:
no SDL (upstream's background music is optional and left out), no ACGame,
no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream as it is, with our curses
(amiga/curses.c, shared with our other console ports); its keys now also
read the function keys (boss mode leaves with F1). Upstream's loop ticks
the game, then sleeps 10 ms, and the game's speed is counted in those
ticks; the Amiga's clock moves in 50ths of a second, so a 10 ms sleep
would take 20 ms and the game would run at half speed: amiga/ticks.c
sleeps until a tick is due and runs every tick that is due. The one
patch, amiga/patches/0001, uses it, keeps the save beside the game
(PROGDIR:tetris.save, where upstream writes to the current directory and
needs the file named on the command line to carry on) and shows the game
over and save messages in the game's window before it closes.

Tests: tests/host/test_tetris.sh builds the game on the build machine
over a plain terminal with the Amiga code paths, plays it with scripted
keys and pauses and reads back the screen (the window's close, the board
and score boxes, the piece falling, left, right, drop, p, q and the game
over, s and the save, the next start carrying it on, then a new game),
and checks the tick clock's rate over slow sleeps and the F1 key.

Credits
-------
Tetris (c) 2015 Stephen Brennan, BSD-3-Clause (LICENSE.txt;
ReadMe-Tetris is upstream's README).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team, BSD-3-Clause like Tetris (brenns10).
