---
title: The power supply, and why it is the part that takes others with it
version: 1
---

Everything in the machine runs on low-voltage direct current. The wall gives high-voltage
alternating current. The **power supply** — the PSU — is the box that converts one into the
other and hands it out at the three voltages the components expect.

It is the least interesting component and the one most worth not economising on, for a reason
that is specific rather than superstitious.

## Why a cheap one is a different kind of risk

A processor that fails, fails. A power supply that fails can put the wrong voltage onto
everything attached to it on the way out, and everything attached to it is the whole machine.
It is the one component whose failure is not contained.

Good ones contain it themselves: **over-voltage, over-current and short-circuit protection** are
circuits that shut the supply down rather than pass the fault along. They are present in decent
units and absent in the cheapest ones, which is most of what you are paying for.

## The 80 PLUS badge, decoded

`80 PLUS Bronze`, `Gold`, `Platinum` — these rate **efficiency**, which is how much of the power
drawn from the wall reaches the components instead of becoming heat.

| badge | roughly, at half load |
|---|---|
| 80 PLUS | 82% |
| Bronze | 85% |
| Gold | 90% |
| Platinum | 92% |

Two things follow, and the second is the one people miss. A less efficient supply costs more to
run — and it also **makes more heat inside the case**, which the cooling then has to remove.
Efficiency is a noise figure as much as an electricity bill.

The badge is also a rough proxy for build quality, which is why it is worth reading at all: a
manufacturer who paid to be certified Gold is usually not the one who left out the protection
circuits.
