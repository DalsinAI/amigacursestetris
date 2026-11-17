#!/bin/sh
# Host tests for the Amiga port of Tetris (brenns10): upstream's game
# (amiga/patches applied, __amigaos__ set, so the Amiga's code paths are
# the ones built: the tick clock of amiga/ticks.c, the save beside the
# game, the last words in the window) with amiga/curses.c over a plain
# terminal (tests/host/console_host.c), played with scripted keys;
# tests/host/vt.py reads back the screen as the Amiga's console would
# show it:
#  - the tick clock: about one tick per 10 ms however long the sleeps
#    take; F1 (CSI 0~) comes as KEY_F(1), boss mode's key;
#  - the window's close ends the game;
#  - the board, Score, Level and Lines; a piece falls in on its own;
#  - the left and right keys move the falling piece; down drops it;
#  - p pauses; q ends the game with the game over and the points;
#  - s saves the game beside it; the next start carries it on (the
#    dropped piece is still at the bottom) and the save is gone.
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/tetris (patched) sh tests/host/test_tetris.sh
# Copyright (c) 2026 AmiCradle Team. BSD-3-Clause, like Tetris (brenns10).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/tetris-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -Iamiga/include -Iamiga"
for f in curses keys ticks; do $CC $MINE -c -o "$T/$f.o" "amiga/$f.c"; done
$CC $MINE -c -o "$T/con.o" tests/host/console_host.c
for f in main tetris util; do
    $CC -std=gnu99 -w -D__amigaos__ -DTETRIS_SAVE='"tetris.save"' -include amiga/include/amiga_prelude.h \
        -Iamiga/include -Iamiga -c -o "$T/up-$f.o" "$UP/src/$f.c"
done
$CC -o "$T/tetris" "$T"/up-*.o "$T/curses.o" "$T/keys.o" "$T/ticks.o" "$T/con.o"

fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

cat > "$T/units.c" <<'C'
#include <stdio.h>
#include "curses.h"
#include "amiga_prelude.h"
int main(void)
{
	unsigned long t0;
	int n = 0, c;
	initscr();
	t0 = acurses_ms();
	while (acurses_ms() - t0 < 500) {
		n += amiga_ticks_due(10);
		acurses_sleep(15);	/* a slow frame, as the Amiga's Delay */
	}
	keypad(stdscr, TRUE);
	c = getch();
	endwin();
	printf("%d %d\n", n, c);
	if (n < 42 || n > 58) return 1;	/* 50 in 0.5 s */
	return c == KEY_F(1) ? 0 : 2;
}
C
$CC $MINE -o "$T/units" "$T/units.c" "$T/curses.o" "$T/keys.o" "$T/ticks.o" "$T/con.o"
if printf '\2330~' | "$T/units" > "$T/units.out"; then
    ok "the tick clock: 10 ms ticks over slow frames ($(grep -o '[0-9]* [0-9]*$' "$T/units.out" | cut -d' ' -f1) in 0.5 s); F1 is KEY_F(1)"
else bad "units: $(tail -n 1 "$T/units.out")"; fi

run() {	# output, then the steps: keys (printf format) and pauses (s:SECONDS)
    out=$1; shift
    (cd "$T" && for step in "$@"; do
        case $step in s:*) sleep "${step#s:}" ;; *) printf "$step" ;; esac
    done | timeout 30 ./tetris > "$out" 2>&1)
}
want() { name=$1; out=$2; shift 2
    if python3 "$HERE/vt.py" "$out" "$@" > "$T/vt.txt"; then ok "$name"; else bad "$name"; cat "$T/vt.txt"; fi; }
blocks() {	# the board's reversed (block) cells as "row:col" lines
    python3 "$HERE/vt.py" "$1" --blocks 2>/dev/null | sed -n '1,24p' | cut -c1-22 \
        | awk '{ for (i = 1; i <= length($0); i++) if (substr($0, i, 1) == "#") print NR ":" i }'
}
leftmost() { blocks "$1" | cut -d: -f2 | sort -n | head -n 1; }
lowest() { blocks "$1" | cut -d: -f1 | sort -n | tail -n 1; }

if run "$T/close.out" s:0.3; then ok "the window's close ends the game"; else bad "the end of the input did not end it"; fi
want "the board, Score, Level and Lines" "$T/close.out" --want "Score" --want "Level" --want "Lines"
run "$T/fall.out" s:0.3
r0=$(lowest "$T/fall.out")
run "$T/fall2.out" s:2
r1=$(lowest "$T/fall2.out")
if [ -n "$r0" ] && [ -n "$r1" ] && [ "$r1" -gt "$r0" ]; then ok "a piece falls in on its own (row $r0 to $r1)"; else bad "falling: ${r0:-none} to ${r1:-none}"; python3 "$HERE/vt.py" "$T/fall2.out" --blocks; fi
x0=$(leftmost "$T/fall.out")
run "$T/left.out" s:0.3 '\033[D' s:0.1 '\033[D' s:0.1 '\033[D' s:0.2
x1=$(leftmost "$T/left.out")
if [ -n "$x0" ] && [ -n "$x1" ] && [ "$x1" -lt "$x0" ]; then ok "left moves the piece (column $x0 to $x1)"; else bad "left: ${x0:-none} to ${x1:-none}"; fi
run "$T/right.out" s:0.3 '\033[C' s:0.1 '\033[C' s:0.1 '\033[C' s:0.2
x2=$(leftmost "$T/right.out")
if [ -n "$x2" ] && [ "$x2" -gt "$x0" ]; then ok "right moves it (column $x0 to $x2)"; else bad "right: ${x0:-none} to ${x2:-none}"; fi
run "$T/drop.out" s:0.3 '\033[B' s:0.3
r2=$(lowest "$T/drop.out")
if [ -n "$r2" ] && [ "$r2" -eq 23 ]; then ok "down drops it to the bottom row"; else bad "drop: lowest row ${r2:-none}"; python3 "$HERE/vt.py" "$T/drop.out" --blocks; fi
run "$T/pause.out" s:0.3 p s:0.3
want "p pauses" "$T/pause.out" --want "PAUSED"
run "$T/quit.out" s:0.3 '\033[B' s:0.2 q s:0.3
want "q: game over and the points in the window" "$T/quit.out" --want "Game over!" --want "points" --want "Press a key."
rm -f "$T/tetris.save"
run "$T/save.out" s:0.3 '\033[B' s:0.3 s s:0.2 y s:0.3
want "s saves: the message in the window" "$T/save.out" --want "Game saved." --want "Press a key."
if [ -s "$T/tetris.save" ]; then ok "the save is beside the game"; else bad "no tetris.save"; fi
run "$T/resume.out" s:0.3
r3=$(lowest "$T/resume.out")
if [ "${r3:-0}" -eq 23 ] && [ ! -e "$T/tetris.save" ]; then
    ok "the next start carries the saved game on (the dropped piece) and the save is gone"
else bad "resume: lowest row ${r3:-none}, save $( [ -e "$T/tetris.save" ] && echo left || echo gone)"; fi
run "$T/fresh.out" s:0.3
r4=$(lowest "$T/fresh.out")
if [ -n "$r4" ] && [ "$r4" -lt 10 ]; then ok "the start after that is a new game"; else bad "fresh: lowest row ${r4:-none}"; fi

if [ "$fails" = 0 ]; then echo "host tests: all passed"; else echo "host tests: $fails failed"; exit 1; fi
