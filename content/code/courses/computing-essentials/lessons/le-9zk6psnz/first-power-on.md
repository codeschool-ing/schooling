---
title: The first power-on, and the blank screen that means nine things
version: 1
---

Press the button and one of three things happens: it draws a picture, it does nothing at all, or
**the fans spin and the screen stays black.** The third is the common one and it is the one that
feels like a disaster.

It is not. It is a list.

## Test it on the box, before it is in the case

The most useful habit in building computers: **power the board up outside the case**, sitting on
its own cardboard box, with only the processor, the cooler, one memory module and the power
supply attached.

Two reasons, and the second is the important one. A case adds a dozen ways to be wrong — a
standoff under no hole, a shorted front panel, a screw behind the board — and the bench test
removes all of them at once. And if it does work on the box and not in the case, **the case is
the fault**, which is a sentence you cannot reach any other way.

There is no power button on a bare board. Briefly touch a screwdriver across the two `PWR_SW`
pins; that is all the button does.

## What POST is, and what it tells you

When power arrives, the firmware runs a **power-on self test** before anything else exists. It
finds the processor, sizes the memory, and looks for something to display on. If it fails, it
reports before any operating system could have loaded.

Three ways it reports, and you want at least one of them:

- **A debug display** — two digits on better boards, and the manual lists every code.
- **Debug LEDs** — four lights labelled `CPU`, `DRAM`, `VGA`, `BOOT`. The one still lit is the
  stage it stopped at, which is the single most useful diagnostic on a modern board.
- **Beeps**, if a speaker is fitted. One short beep is usually success; a repeating pattern is a
  code.

A board with none of the three tells you nothing, which is why fitting the speaker is worth the
thirty seconds.

## Working down the blank screen

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Six numbered checks, each with what it rules out beside it. In order: does anything spin at all, is the eight-pin EPS plugged in, one memory module in slot two, the monitor on the board rather than the card, clear the firmware settings, and out of the case on the box. A note says each check removes a whole family of causes rather than testing one part.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A blank screen, worked down instead of guessed at</text><text x=\"76\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what to check</text><text x=\"680\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and what it rules out</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"79\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"76\" y=\"79\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">does anything spin at all?</text><text x=\"680\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the supply and the power switch</text><rect x=\"24\" y=\"104\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><text x=\"76\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">is the 8-pin EPS plugged in?</text><text x=\"680\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the most commonly missed cable</text><rect x=\"24\" y=\"146\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><text x=\"76\" y=\"163\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one memory module, in slot 2</text><text x=\"680\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one module, or one slot</text><rect x=\"24\" y=\"188\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><text x=\"76\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the monitor on the board, not the card</text><text x=\"680\" y=\"205\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the graphics card</text><rect x=\"24\" y=\"230\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><text x=\"76\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">clear the firmware settings</text><text x=\"680\" y=\"247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">something somebody saved</text><rect x=\"24\" y=\"272\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"289\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"76\" y=\"289\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">out of the case, on the box</text><text x=\"680\" y=\"289\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a standoff under no hole</text><text x=\"24\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Each line removes a whole family of causes. Guessing at one part tests one part.</text></svg>", "caption": "The order matters as much as the list: each step is chosen to make the next one mean something."}
```

**One memory module, in the second slot from the processor**, is the check people skip and it
finds more faults than the rest of the list. A board will refuse to POST on a single bad module,
on a module in the wrong slot, and occasionally on two modules that each work alone.

**The monitor on the motherboard's own socket** separates the graphics card from everything else
in one move — and if the processor has no integrated graphics, that check does not exist for you,
which is worth knowing before you need it.

## Two sounds that are not faults

A new build often **powers on, runs for two seconds, switches off, and starts again.** That is
memory training: the board is measuring the modules and settling on timings. It happens on the
first boot and after changing memory settings, and it can take thirty seconds.

A cooler at full speed for the first few seconds is also normal. The board runs every fan flat
out until it has read a temperature.

## What to do when it does work

Nothing yet. **Leave the case open**, check that the processor fan is turning and that the
graphics card's fans are not stuck against a cable, and go into the firmware. The next section is
what to change there, and the answer is less than you would think.
