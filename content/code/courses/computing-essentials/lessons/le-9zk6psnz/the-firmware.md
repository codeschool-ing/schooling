---
title: The firmware, where two settings matter and thirty do not
version: 1
---

The screen you reach by pressing `Del` or `F2` at power-on is the **firmware** — `UEFI` on
anything modern, `BIOS` on anything older and in most people's vocabulary regardless. It is a
small program on the motherboard that runs before any operating system exists.

It has a hundred settings. Two of them are worth changing on a new build, one is worth checking,
and the rest are for people solving a specific problem.

## The one that is free performance

**`XMP`, or `EXPO` on AMD boards.** Memory ships running at a conservative speed that every board
is guaranteed to manage — typically `2133` or `2400 MHz` — regardless of what it was sold as. The
`3600 MHz` on the box is a *profile* stored in the module, and the board does not use it until
you say so.

One setting, one reboot, and the memory runs at the speed you paid for. **Leaving it off is the
single most common way a new build is slower than it should be**, and nothing anywhere reports
it — the machine works perfectly, a little slower, forever.

Expect the two-second on-off-on again while the board retrains.

## The one that is not optional

**The boot order**, which decides what the machine tries to start from. For the installation you
need the USB drive first; afterwards the internal drive. Most boards also have a one-off boot
menu on `F11` or `F12`, which is better than changing the setting twice.

## The one to check rather than change

**The date and time.** A board with a flat coin cell forgets them, and the symptom is not a wrong
clock — it is **web pages refusing to load with a certificate error**, because certificates have
dates on them and the machine thinks it is 2015. That is a confusing hour, and the cure is a
`CR2032` that costs almost nothing.

## Fan curves, briefly

The firmware decides how fast each fan spins at each temperature. The defaults are aggressive,
because a manufacturer would rather be loud than blamed for heat.

A gentler curve — idle fans below about `50 °C`, ramping from there — makes a machine much
quieter and costs a few degrees nobody notices. This is the one place where fiddling is
rewarding, and it is reversible.

## What not to touch

- **Voltages.** The place where a wrong number does permanent damage, and the only one in this
  list.
- **Secure Boot**, unless something needs it off. Leave it on; Windows expects it and Linux
  handles it now.
- **Overclocking.** A separate subject with a separate failure mode. The default settings are
  what everything was tested at.
- **Anything you cannot name.** A firmware full of changes nobody remembers making is the reason
  *clear the settings* is on the blank-screen list.

## Updating it

A firmware update fixes compatibility — a processor newer than the board, a memory kit it does
not recognise — and it is the one maintenance task that can **brick the board** if power is lost
during it.

So: update it if you have a reason, do not if you do not, and never during a storm. Many boards
can flash from a USB stick with no processor fitted, which is the feature that saves a build
where the board is older than the chip.
