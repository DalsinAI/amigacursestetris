/* Included before Tetris' (brenns10) files in the Amiga build and the host
 * tests (-include): its 10 ms pause (nanosleep) as acurses_sleep (on the
 * Amiga, dos.library Delay through amiga/console_amiga.c); the game's own
 * loop keeps its rate with amiga/ticks.c (amiga/patches/0001).
 * Copyright (c) 2026 AmiCradle Team. BSD-3-Clause, like Tetris (brenns10). */
#ifndef AMIGA_PRELUDE_H
#define AMIGA_PRELUDE_H
#include <time.h>
void acurses_sleep(int ms);
#define nanosleep(t, rem) \
	(acurses_sleep((int)((t)->tv_sec * 1000 + (t)->tv_nsec / 1000000)), 0)
int amiga_ticks_due(int period_ms);
#endif
