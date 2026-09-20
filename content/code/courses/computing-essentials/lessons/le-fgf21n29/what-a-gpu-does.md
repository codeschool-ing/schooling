---
title: What a graphics card actually does
version: 1
---

A processor is built to do one complicated thing after another, very fast. A **graphics
processor** is built for the opposite: the same simple thing to a million pieces of data at
once.

That is the whole difference, and every consequence follows from it.

A screen at 1920×1080 is about two million pixels. Sixty times a second, something has to decide
a colour for each one. The decisions are nearly identical and they do not depend on each other —
which is precisely the work a CPU is bad at and a GPU is built for.

| | processor | graphics processor |
|---|---|---|
| cores | 6 to 16, complicated | thousands, simple |
| good at | one hard thing at a time | one easy thing, everywhere |
| bad at | a million small identical jobs | anything with a decision in it |

## Which is why it stopped being about graphics

The name is now half wrong. "The same simple operation across an enormous array" describes
drawing a frame, and it also describes training a neural network, multiplying large matrices,
and mining cryptocurrency. A graphics card is a machine for doing arithmetic in bulk, and
pictures were just the first thing anybody wanted in bulk.

## VRAM, and why it is quoted separately

A graphics card carries its own memory — **VRAM** — because it needs the textures and the frame
it is building to be right beside those thousands of cores. Going out to the machine's main
memory would put the two-minute step of the last lesson in the middle of every frame.

When a card is described as `8 GB`, that is its own memory and it has nothing to do with the
`16 GB` elsewhere in the specification. Running out of it does not slow the card down gently: it
falls back to main memory, and the frame rate drops off a cliff.
