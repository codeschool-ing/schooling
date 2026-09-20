---
title: The audio jack, which is from 1878 and still catches people out
version: 1
---

The `3.5 mm` jack is the oldest connector on any machine here — a smaller version of a plug
invented for telephone switchboards in the nineteenth century. It has survived because it is
cheap, passive and needs no agreement between the two ends at all.

Which is also why it goes wrong in ways nothing reports.

## The colours, which are a convention

On a desktop's back panel:

- **green** — line out. Speakers or headphones.
- **pink** — microphone in.
- **blue** — line in. A signal that is already at full level, from a mixer or an instrument.

Plugging headphones into blue produces silence with no error. Plugging a microphone into green
produces silence with no error. **Nothing in the chain can tell it has the wrong hole**, because
the socket is a piece of metal.

## Three rings or two, and the headset problem

Count the black bands on the plug:

| | bands | carries |
|---|---|---|
| **TS** | one | one channel. Instruments |
| **TRS** | two | left and right. Ordinary headphones |
| **TRRS** | three | left, right and a microphone. Phone headsets |

A laptop usually has **one** socket, and it is a TRRS one that does both jobs. A desktop usually
has **two**, and they are TRS.

So a phone headset with one plug, used on a desktop, gives you sound and no microphone — and
there is no setting that fixes it, because the microphone's wire is not connected to anything.
The adapter that splits one TRRS into two TRS plugs costs almost nothing and is the only answer.

**Worse, there are two wirings of TRRS** — one used by Apple and one by an older standard — that
swap the microphone and the ground. A headset on the wrong one gives distorted sound or a
microphone nobody can hear.

## Optical, which is in the same hole on some machines

Some desktops and most televisions have an **optical** output (`S/PDIF`, or `TOSLINK`) that
carries digital sound down a fibre. On a few machines it shares the green socket: a square
adapter goes into the same hole, and if you look into it you can see a faint red light.

It is worth knowing exists, because **it carries no electricity between the two devices**, which
removes the ground loop that causes a hum in a system with several powered boxes in it.

## USB audio, and why it sounds better for free

Plugging headphones into a USB socket or using a USB microphone moves the conversion between
sound and numbers **out of the computer's case**, where it was sitting beside a power supply and
a graphics card. The hiss and the faint whine that follows the mouse pointer are both interference
picked up in there.

That is the whole of the improvement, and it is a real one: the same headphones on a `10` USD USB
adapter are often quieter than on a motherboard's green socket.
