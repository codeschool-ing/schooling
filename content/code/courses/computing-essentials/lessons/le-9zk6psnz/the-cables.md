---
title: The cables, which is where a build actually fails
version: 1
---

Every part is seated by pressure and holds itself. **The cables are the only step with no
feedback**, and a connector that is nine tenths in looks exactly like one that is in.

## The six that must be connected

| | where it goes | what happens if it is missing |
|---|---|---|
| **24-pin ATX** | the long connector on the board's edge | nothing at all happens |
| **8-pin EPS** | top corner, near the processor | fans spin, no picture. The commonest miss |
| **PCIe power** | the graphics card, if it has a socket | fans spin, no picture, sometimes a card LED |
| **SATA power and data** | any drive that is not M.2 | the drive does not exist |
| **front panel** | the pin block at the bottom edge | the power button does nothing |
| **fan headers** | `CPU_FAN` for the cooler, the rest anywhere | some boards refuse to boot with no CPU fan |

The second row deserves its note. The **8-pin EPS** connector is the processor's own power, it is
separate from the 24-pin, and it sits in the most awkward corner of the case. Forgetting it gives
you a machine that lights up, spins every fan, and draws nothing on the screen — which looks
exactly like a dead motherboard.

It is also the connector most often confused with the **PCIe 8-pin** for a graphics card. They
are shaped differently and they will not cross over, but the cables look alike in a bundle and
both ends of a modular power supply are labelled in small print. **Read the label on the supply's
own socket**, not the one on the plug.

## The front panel, which is the fiddly bit

A small block of pins takes five or six tiny two-wire connectors:

- `PWR_SW` — the power button. **This is the only one that has to be right for the machine to
  start.**
- `RESET_SW` — the reset button.
- `PWR_LED` — the power light. Polarity matters: backwards and it simply does not light.
- `HDD_LED` — the drive activity light. Same.
- `SPEAKER` — the little beeper, if the case has one. **Fit it.** It is the difference between a
  blank screen and a blank screen with three beeps telling you what is wrong.

Switches have no polarity — `PWR_SW` works either way up. LEDs do. And if the board's pins are
unreadable, the manual has the diagram, which is the reason to have it open.

## Modular supplies, and the rule that matters

A modular power supply has detachable cables, and **the cables from one supply do not work on
another**, even from the same manufacturer, even when the plug fits. The pin assignments differ
and connecting them can destroy everything attached.

There is one rule and it is absolute: **use the cables that came in the box with that supply.**
This is the only place in a build where something that physically fits can cause real damage.

## Tidying, and when

Do it **after** the machine has been tested and is running. Cable management is entirely for
airflow and for the next person to open the case, and routing everything behind the tray before
you know the build works means undoing all of it to reach one connector.

One thing is worth doing before the test, though: make sure no cable can reach a fan blade. That
is the one failure a bench test will find loudly and expensively.
