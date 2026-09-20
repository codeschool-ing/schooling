---
title: Adapters, and the direction nobody tells you about
version: 1
---

An adapter is not a shape-changer. Some of them only rearrange wires; others contain a chip that
converts one signal into another, and **the second kind only works one way round**.

## Passive and active

A **passive** adapter connects pin to pin. It works when both ends already speak the same
language and only the plug differs — USB-C to USB-A, DisplayPort to Mini DisplayPort, a TRRS
splitter.

An **active** adapter converts. It has electronics in it, it sometimes needs power, and it costs
several times as much. HDMI to VGA is active, because one side is digital and the other is a
voltage.

**A passive adapter sold where an active one is needed is the commonest bad purchase here**, and
the symptom is a black screen with everything apparently connected.

## Direction, which is the part that surprises people

Converting **digital to analogue** is easy: the chip has all the information and throws some
away. Converting **analogue to digital** means guessing at what was lost.

So:

- `HDMI → VGA` works. A cheap adapter does it.
- `VGA → HDMI` needs a much better adapter, costs more, and the picture is never as good as the
  digital source it never had.

The two adapters look the same in a photograph and are labelled in small print. **Read which way
the arrow points.**

## What an adapter cannot invent

No adapter adds a capability the port does not have. Three cases worth naming, because all three
are sold:

- **USB-C to HDMI on a port with no Alt Mode.** Nothing happens. The port never had video wires.
- **USB-A to Ethernet** genuinely works, and runs at whatever the USB port is — a `480 Mb/s` USB
  2.0 socket cannot give you a gigabit.
- **A `100 W` charger through a `60 W` cable** charges at 60. The cable declares what it can
  carry and the negotiation respects it.

## Cables, and the one rule that saves the most time

**Change one thing at a time, and start with the cable.** It is the component that moves, gets
trodden on, wound tightly and pulled out by its wire, and it is the cheapest of the four things
in the chain to replace.

A useful habit: keep one cable of each kind that you *know* is good, and use it as the reference.
"It works with the good cable" ends the question in thirty seconds, where reinstalling a driver
takes an afternoon and proves nothing.

## And the labelling, which sounds trivial

USB-C cables cannot be told apart by looking, so a drawer of them is a drawer of unknowns. A
strip of tape with `40` or `charge only` written on it turns that drawer back into a set of
tools.

This is the same argument as the specification on a shop page: **a thing that cannot be
identified has to be tested every time**, and the test is slower than the label.
