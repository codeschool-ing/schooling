---
title: Heat, dust, and what the fan is telling you
version: 1
---

Heat is the most common hardware problem in the world and almost nobody recognises it, because
what it produces is *the machine got slow* — which everybody files under software.

## What a processor does when it is too hot

It slows itself down. Deliberately, by design, to protect itself: the clock drops, the work takes
longer, and nothing anywhere says so. This is **thermal throttling**, and a machine doing it can
be running at a third of its speed with no message and no error.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"A bar chart of one machine speed at five points in time. At zero and five minutes it runs at a hundred per cent, at forty-one and fifty-eight degrees. At ten minutes it is at eighty-five per cent and seventy-four degrees. At twenty minutes, fifty-five per cent and eighty-eight degrees. At forty minutes, thirty-five per cent and ninety-five degrees.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same machine, every ten minutes</text><text x=\"24\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside each bar is the speed as a percentage; above it, the temperature in degrees</text><path d=\"M70 220 L690 220\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"80\" y=\"70\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"115.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">100</text><text x=\"115.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41</text><text x=\"115.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"200\" y=\"70\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"235.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">100</text><text x=\"235.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">58</text><text x=\"235.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"320\" y=\"92\" width=\"70\" height=\"128\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">85</text><text x=\"355.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">74</text><text x=\"355.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><rect x=\"440\" y=\"138\" width=\"70\" height=\"82\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"475.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">55</text><text x=\"475.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">88</text><text x=\"475.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><rect x=\"560\" y=\"168\" width=\"70\" height=\"52\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"595.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">35</text><text x=\"595.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">95</text><text x=\"595.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"24\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes</text><text x=\"80\" y=\"264\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">full speed</text><text x=\"320\" y=\"264\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">slowing itself down to survive</text><text x=\"24\" y=\"294\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nothing on the screen says any of this is happening. The only symptom is that everything takes longer.</text></svg>", "caption": "Forty minutes in, this machine is doing a third of the work it did at the start, and it has reported nothing at all."}
```

If it gets hotter still, it switches off. Not a shutdown with a warning — an instant loss of
power, as though somebody pulled the plug, because that is the last protection there is.

## The signature

**Fine when cold, slow after twenty minutes.** That sentence is the one worth memorising. A
machine that is fast in the morning and unusable by mid-afternoon, or fast for ten minutes after
every restart, is a machine that is overheating, and nothing you uninstall will change it.

Two more that go with it:

- **the fan is always loud**, especially at idle, which means the machine has been trying and
  failing to cool itself for a while;
- **it switches off under load** — a game, a video call, exporting something — and is fine again
  once it has cooled.

## Dust is the cause, and it is mechanical

A heatsink works by having air pass through a dense stack of thin fins. Dust packs the gaps
between them into a felt, and once it does, the fan can spin at full speed moving air that goes
nowhere.

For a desktop this is a can of compressed air and ten minutes, once a year. For a laptop it is
harder — the intake is a slot on the underside, the stack is inside, and a full clean means
opening it. **Blowing into the vents from outside is worth doing and is not the same job**; it
moves the loose dust and leaves the felt.

Two things that help without opening anything: **lift the back of a laptop** so air can reach the
underside at all, and **do not use it on a bed or a sofa**, where the intake is pressed into
fabric.

## Thermal paste, briefly, and honestly

Between the processor and the heatsink there is a layer of paste, and after five to ten years it
dries out and conducts badly. Replacing it is a genuine repair that genuinely works.

It is also the point where a home job becomes a real one: the heatsink has to come off, the old
paste has to be cleaned off both surfaces, and the new layer has to be the right amount. It is
worth knowing the term so you can recognise a fair quote. It is not the first thing to try.

## The noises, and which one is urgent

- **A fan that rattles or buzzes** is a bearing going. Annoying, cheap, and not urgent.
- **A fan that changes pitch with load** is a fan doing its job.
- **A click, or a rhythmic tick, from a spinning hard disk** is not a fan at all, and it is the
  next section, and it is the urgent one.
