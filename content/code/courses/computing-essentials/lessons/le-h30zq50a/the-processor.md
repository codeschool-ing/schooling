---
title: The processor, and what "faster" actually means
version: 1
---

The processor — the CPU — does one thing, several billion times a second: it takes an
instruction, carries it out, and takes the next one. Add these two numbers. Compare them. If the
first is bigger, jump somewhere else. Every program you have ever run is a very long list of
instructions at roughly that level.

Two numbers get quoted about processors, and they are quoted as though they were the same kind
of number. They are not.

## Clock speed is how fast one worker goes

**3.2 GHz** means the processor takes 3.2 billion steps a second. Higher is faster, for one
thing happening at a time.

It is the number shops put in the biggest type, and it is the one that has stopped moving.
Processors were 3 GHz in 2005 and they are 3-to-5 GHz now, because pushing the clock higher
makes heat faster than it makes speed. Everything that got better in the twenty years since got
better the other way.

## Cores are how many workers there are

A **core** is a complete processor in its own right. A 6-core CPU can genuinely carry out six
instructions at the same instant, not take turns quickly.

That is the number that grew: one core, then two, then six, eight, sixteen. And the reason it is
quoted second is that it only helps when there is more than one thing to do — which is almost
always true of a whole computer and often false of a single program.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two panels. On the left, one core at 5 gigahertz with a single task bar running the full width, finishing at ten seconds. On the right, four cores at 3 gigahertz: the top row shows one task split across all four, each finishing at about four seconds, and below it a second case where one task that cannot be split sits on one core alone and the other three are empty, finishing at seventeen seconds. A note reads that more cores help when there is more than one thing to do, and do nothing at all when there is not.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The same work, on two machines, twice — and the second case is the one nobody is warned about.</text><rect x=\"14\" y=\"38\" width=\"200\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"114\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">1 core · 5 GHz</text><rect x=\"28\" y=\"76\" width=\"172\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">one task, all of it</text><text x=\"114\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">10 s</text><text x=\"114\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">fast at one thing</text><text x=\"114\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">and only one</text><rect x=\"244\" y=\"38\" width=\"462\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"475\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">4 cores · 3 GHz</text><text x=\"258\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">work that splits</text><rect x=\"258\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"454\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"552\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">4 s</text><text x=\"258\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">work that does not split</text><rect x=\"258\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"454\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"552\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"668\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">17 s</text><text x=\"258\" y=\"166\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three cores idle, and no clock speed to make up for them</text><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">More cores help when there is more than one thing to do. They do nothing at all when there is not.</text></svg>", "caption": "The four-core machine is slower at the bottom task than the one-core machine beside it, and nothing printed on either box would tell you that."}
```

Look at the bottom row of that drawing, because it is the answer to a real question. Somebody
buys a machine with more cores, runs the one program they care about, and it is *slower* than
the old one. Nothing is broken. Their program does not split, so it runs on one core at 3 GHz
where the old machine ran it on one core at 5.

## What the model numbers mean, roughly

`Intel Core i5-13400` and `AMD Ryzen 5 7600` are the same shape of name:

| piece | what it says |
|---|---|
| `Core i5` / `Ryzen 5` | the tier — 3 is entry, 5 is mainstream, 7 and 9 are more |
| `13`400 / `7`600 | the generation — bigger is newer, and only comparable within one brand |
| 13`400` / 7`600` | the position inside that generation |

**The tier is more informative than the clock speed**, which is the opposite of how shops
present it. An i5 of this year's generation will beat an i7 from six years ago at nearly
everything, and the i7 will have the bigger number printed on it.

## What it needs to be fast, and does not control

A processor spends a great deal of its life doing nothing at all, waiting for something to
arrive. It cannot fix that by being faster, and the next three sections are about where it
waits.
