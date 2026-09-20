---
title: Four parts, and one of them is not a part
version: 1
---

Open any desktop computer and the same four things are in there. Not four of the hundreds of
components on the board — four **roles**, and every other chip in the machine exists to serve
one of them.

- The **processor** does the work. Every calculation, every comparison, every instruction your
  programs are made of.
- **Memory** — RAM — is what it is working on right now. Open documents, running programs, the
  page you are reading.
- **Storage** — an SSD or a hard disk — is what survives being switched off. Your files, your
  programs as installed, the operating system itself.
- The **motherboard** is what connects the other three.

That last one is the odd one out, and it is worth being clear about why straight away: **the
motherboard does no work.** It calculates nothing and remembers nothing. It is the building the
other three work in — the wiring, the sockets, the routes between them. People list it as a
fourth component because it is the largest object in the case, which is exactly backwards.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Three panels side by side above a wide bar. The left panel, processor, says it does the work. The middle panel, memory, holds three small blocks labelled what is open right now and is marked as cleared every time the power goes. The right panel, storage, holds five stacked rows and is marked as surviving the power going. Between storage and memory a long arrow points left, labelled opening a file, about a hundred thousand times slower than reading memory; a fainter arrow points back, labelled saving. Under all three, a bar reads motherboard, the building and not a worker.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Three of the four do work. The fourth is the room they do it in.</text><rect x=\"14\" y=\"44\" width=\"150\" height=\"126\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">processor</text><rect x=\"49\" y=\"84\" width=\"80\" height=\"50\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"89\" y=\"109\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">CPU</text><text x=\"89\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">does the work</text><rect x=\"218\" y=\"44\" width=\"220\" height=\"126\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"328\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">memory</text><rect x=\"236\" y=\"84\" width=\"58\" height=\"34\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"299\" y=\"84\" width=\"58\" height=\"34\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"362\" y=\"84\" width=\"58\" height=\"34\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"328\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">what is open right now</text><text x=\"328\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">cleared every time the power goes</text><rect x=\"492\" y=\"44\" width=\"214\" height=\"126\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"599\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">storage</text><rect x=\"512\" y=\"82\" width=\"174\" height=\"9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"512\" y=\"94\" width=\"174\" height=\"9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"512\" y=\"106\" width=\"174\" height=\"9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"512\" y=\"118\" width=\"174\" height=\"9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"512\" y=\"130\" width=\"174\" height=\"9\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"599\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">survives the power going</text><path d=\"M488 96 L444 96\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M442 96 L450 92 L450 100 Z\" fill=\"var(--amber)\"></path><path d=\"M444 124 L488 124\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M490 124 L482 120 L482 128 Z\" fill=\"var(--wire)\"></path><text x=\"466\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--amber)\">opening</text><text x=\"466\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">saving</text><path d=\"M168 96 L214 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M216 96 L208 92 L208 100 Z\" fill=\"var(--wire)\"></path><path d=\"M214 124 L168 124\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M166 124 L174 120 L174 128 Z\" fill=\"var(--wire)\"></path><rect x=\"14\" y=\"186\" width=\"692\" height=\"30\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"201\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">motherboard — the building, not a worker</text><text x=\"14\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Opening a file crosses the amber arrow, and that crossing is about a hundred thousand times slower than reading memory.</text></svg>", "caption": "The amber arrow is the expensive one, and nearly everything that feels slow is a machine standing on it."}
```

## The desk, and why that metaphor earns its place

Most explanations of this reach for an office, and so does this one, because the analogy holds
further than most.

A worker at a desk. The **desk surface** is memory: big enough for a few open documents, and
completely cleared every night. The **filing cabinet** beside it is storage: far bigger, far
slower to reach into, and still full in the morning.

The metaphor pays off in three places, and all three are things beginners get told as rules
without reasons:

**Why closing programs helps.** A crowded desk means the worker spends their time shuffling
paper instead of working. That is not a figure of speech — it is exactly what a computer does
when memory fills up, and the next section but two gives it its real name.

**Why an SSD feels like a new computer.** It is not the desk that changed. It is the distance to
the cabinet.

**Why "it lost my work" is always about the desk.** Anything that was only ever on the desk is
gone when the lights go out. *Saving* is the act of walking it to the cabinet. This is the single
most expensive thing in this lesson to not know.

## What this lesson will let you do

By the end you should be able to read a line like this off a shop page —

```
Intel Core i5-13400 · 16 GB DDR4 · 512 GB NVMe SSD
```

— and say which of the four parts each piece is, roughly what it means, and which one is most
likely to be the thing that disappoints you. That is a genuinely useful skill and it is four
lessons' worth of vocabulary away, not four years'.
