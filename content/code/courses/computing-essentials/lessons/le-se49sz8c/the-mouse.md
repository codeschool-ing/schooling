---
title: The mouse, and why a bigger DPI number is not a better mouse
version: 1
---

A mouse is a camera. Underneath it is a small sensor photographing the surface thousands of times
a second and comparing each picture to the last one to work out which way the mouse moved and how
far. That is all it does.

Knowing that explains almost every mouse problem, because a camera needs something to look at.

## DPI is sensitivity, not quality

**DPI** — dots per inch — is how many steps the pointer moves for each inch you move the mouse. A
higher number means the pointer travels further for the same hand movement.

That is a **preference**, not a grade. A box claiming `16 000 DPI` is claiming a setting nobody
uses: at that sensitivity, moving the mouse one centimetre crosses the whole screen and back.
Most people work between 800 and 1600.

What DPI does not tell you:

- whether the sensor tracks accurately at speed;
- whether it drops out on a shiny surface;
- whether the pointer drifts when the mouse is lifted and put down.

Those are the things a good sensor gets right, and none of them is a number on the box.

## Polling rate, which is real and small

The **polling rate** is how often the mouse reports to the computer: `125 Hz` is every eight
milliseconds, `1000 Hz` is every one. Going from 125 to 1000 is a difference you can feel if you
are looking for it and cannot see if you are not.

It is the same shape of claim as a monitor's refresh rate, with the same honest answer: real for
fast games, irrelevant for everything else.

## Pointer acceleration, and the setting worth turning off

By default most systems move the pointer **further when you move the mouse faster**, so that a
quick flick crosses the screen and a slow movement is precise. It sounds helpful and it means the
same physical movement produces two different results depending on how fast you did it.

Turn it off — Windows calls it *enhance pointer precision* — and your hand learns one fixed
relationship instead of a moving one. Almost everybody who turns it off keeps it off.

## What actually goes wrong with a mouse

| symptom | what it usually is |
|---|---|
| pointer jumps or freezes | a glass or gloss surface; the sensor has nothing to photograph |
| pointer drifts slowly | dirt on the sensor window, or a very uniform surface |
| double-click from one click | the switch is worn out — this is mechanical and it is terminal |
| lag over wireless | a battery below about 15%, or a 2.4 GHz dongle behind the machine |

The last one is worth expanding, because it is where the usual advice is wrong.

## Wireless is fine now, and the reason people think it is not

A modern `2.4 GHz` dongle adds about one millisecond, which is less than a single frame at 60 Hz.
Bluetooth adds more and is more variable, which is why gaming mice ship a dongle rather than
relying on it.

What actually causes the lag people blame on wireless is **the dongle's position**: plugged into
the back of a desktop, with the metal case between it and the mouse, the signal has to go around
the machine. A short extension cable bringing the dongle to the desk fixes it, and costs nothing.

**A wired mouse never has that problem and never has a flat battery**, which remains a decent
argument for one on a desk you never move.
