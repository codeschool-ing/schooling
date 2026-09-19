---
title: Cooling, and the failure that looks like a slow computer
version: 1
---

Every watt a component draws becomes heat. A 400 W machine is a 400 W heater, and the cooling
system's only job is to move that heat from where it is made to outside the case.

It almost never fails outright. It **stops being enough**, and the symptom is specific enough to
diagnose from across a room.

## Thermal throttling

Modern processors and graphics cards watch their own temperature. Past a limit — usually around
100 °C for a CPU — they reduce their clock speed to make less heat. That is **throttling**, and
it is a protection rather than a fault.

What it looks like from a chair:

- the machine is fast for the first five or ten minutes, then noticeably slower;
- it recovers after being left alone for a while;
- the fans are loud before the slowdown, not after.

That pattern is almost diagnostic. A genuinely slow machine is slow from the first second. **A
machine that is fast and then is not has a heat problem**, and the commonest cause is dust.

## Air, and why direction matters

The standard arrangement is fans at the front pulling cool air in and fans at the back and top
pushing warm air out. Heat rises, so out-at-the-top is working with physics rather than against
it.

Two arrangements go wrong, and both are common:

- **every fan blowing inward.** Pressure builds, air has nowhere to leave, and the case fills
  with warm air that has nowhere to go.
- **a fan fitted backwards.** Fans have an arrow on the frame for this reason, and it is the
  easiest mistake to make and to miss.

## Paste, and the only part of this that wears out

Between a processor and its cooler is a thin layer of **thermal paste**, because two flat metal
surfaces touch at far fewer points than they look like they do. The paste fills the gaps.

It dries out over years. A five-year-old machine that throttles under load and is not dusty is
usually asking for paste, and that is a twenty-minute job rather than a new computer.
