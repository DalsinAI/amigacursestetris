/* The game's clock on the Amiga. Upstream's loop ticks the game, then
 * sleeps 10 ms (nanosleep); the game's speed is counted in those ticks.
 * The Amiga's Delay and DateStamp move in 50ths of a second, so a 10 ms
 * sleep takes 20 ms and the game would run at half speed: this sleeps
 * until a tick is due and says how many are due (the loop runs the rest
 * at once), so the pieces fall as fast as upstream's. After a long stall
 * (a requester, a busy machine) at most 10 are made up.
 * Copyright (c) 2026 AmiCradle Team. BSD-3-Clause, like Tetris (brenns10). */
unsigned long acurses_ms(void);
void acurses_sleep(int ms);

int amiga_ticks_due(int period_ms)
{
	static unsigned long last;
	unsigned long period = period_ms > 0 ? (unsigned long)period_ms : 1, now = acurses_ms();
	unsigned long n;

	if (!last)
		last = now;
	if (now - last < period) {
		acurses_sleep((int)(period - (now - last)));
		now = acurses_ms();
	}
	n = (now - last) / period;
	if (n < 1)
		n = 1;
	if (n > 10) {
		n = 10;
		last = now;
	} else {
		last += n * period;
	}
	return (int)n;
}
