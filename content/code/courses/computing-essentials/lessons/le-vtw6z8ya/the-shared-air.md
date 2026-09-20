---
title: Range, speed and power, which pull against each other
version: 1
---

Everything in this lesson is a radio except one, and every radio is making the same three-way
trade. You cannot have all of it, and knowing which corner a technology sits in explains almost
everything else about it.

| | range | speed | power |
|---|---|---|---|
| **Wi-Fi** | a house | `100 Mb/s` to `1 Gb/s` in practice | a wall socket |
| **Bluetooth** | a room | `1` to `3 Mb/s` | a coin cell for months |
| **Bluetooth LE** | a room | `0.3 Mb/s` | a coin cell for years |
| **NFC** | 4 centimetres | `0.4 Mb/s` | none at all in the tag |
| **infrared** | line of sight | slow, and unused for data | a pair of AAA cells for years |

Read it as a diagonal: **the further it goes, the more it costs to run.** A device that has to
last a year on a battery cannot also reach across a house, which is why a door sensor uses
Bluetooth LE and a laptop does not.

## The air is shared, and this is the part people miss

A cable belongs to the two machines at its ends. **A radio channel belongs to everybody within
range of it**, which in a block of flats is several dozen households.

Two radios on the same channel do not collide and garble each other; they take turns. That is
polite and it means **the time available is divided among everybody using it**. A busy channel is
not noisy — it is a queue.

So the honest description of a slow evening connection is usually not *the router is weak*. It is
that the channel is full of neighbours, and that is why moving to a less crowded one often does
more than any purchase.

## Three things that weaken a radio signal, in order

1. **Distance.** Signal strength falls with the square of it: twice as far is a quarter as
   strong. That is arithmetic and no equipment changes it.
2. **What is in the way.** A plasterboard wall costs a little. Brick costs a lot. **Concrete with
   steel in it, tiled bathrooms and mirrors are close to walls of metal**, and a kitchen full of
   appliances is the worst room in most houses.
3. **Water.** Which includes people. A room that measures well when empty measures worse with
   forty people in it, and that is why a conference venue plans for bodies.

## What the numbers on the box mean

A router advertising `3000` is adding together every radio it has — say `600` on one band and
`2400` on another. **No single device ever gets that number.** It is the sum of speeds that
cannot be used at once by one client.

The figure you actually get is roughly half the negotiated link speed, because the radio spends
time listening, acknowledging and taking its turn. That is not a defect; it is what sharing
costs.
