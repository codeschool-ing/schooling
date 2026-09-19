---
title: Printers, and the only device here sold at a loss
version: 1
---

A printer is the one thing in this lesson whose purchase price tells you almost nothing about
what it will cost you. Some are sold below what they cost to build, and the manufacturer earns
the difference back on the supplies. That is not a scandal; it is the business model, and it is
printed nowhere on the box.

So the number to compare is not the price. It is the **cost per page**.

## Inkjet and laser are not two grades of the same thing

| | inkjet | laser |
|---|---|---|
| how it works | sprays liquid ink onto paper | fuses powdered toner with heat |
| buys cheap | yes, often very | no |
| cost per page, mono | high | low, often ten times lower |
| colour | good, and the reason to own one | adequate, and expensive |
| photographs | genuinely good | no |
| left unused for a month | heads dry and clog | nothing happens |
| noise and warm-up | quiet, instant | louder, a few seconds to warm |

The last-but-one row is the one people discover the expensive way. **An inkjet used once a month
is the worst possible way to own one**: the heads dry between uses, the cleaning cycle spends ink
to unclog them, and a set of cartridges can be emptied without printing much at all.

## The arithmetic, honestly

Take a cheap inkjet and a mono laser, and count what each has cost after a run of pages:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A chart with pages printed along the bottom, from zero to five thousand, and total spent up the side. Two straight lines. The inkjet line starts low, because the printer is cheap, and climbs steeply. The laser line starts higher and climbs very slowly. They cross at about eight hundred pages, marked with a dot and a dashed line down to the axis, after which the inkjet line is the higher of the two and keeps getting further ahead.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">What each printer has cost you, after a run of pages</text><text x=\"24\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">total spent</text><path d=\"M80 56 L80 250 L660 250\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M174 250 L174 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><path d=\"M80 232 L660 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M80 208 L660 190\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"174\" cy=\"206\" r=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"656\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">inkjet: cheap to buy, expensive to feed</text><text x=\"656\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">laser: dear to buy, cheap to feed</text><text x=\"80\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"660\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5000</text><text x=\"370\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pages printed</text><text x=\"24\" y=\"298\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The lines cross at about 800 pages. Everything to the right of that is the cheap printer costing more.</text></svg>", "caption": "The dot is the whole decision. If you will print more than a few hundred pages in the life of the machine, the cheap printer is the expensive one."}
```

The crossing point moves with the models and the prices, and it is usually somewhere in the
**high hundreds of pages**. Under that, the cheap printer really is cheaper. Over it, every page
widens the gap and never closes it.

## Which to buy, stated plainly

- **You print a few pages a month, in black.** A mono laser. It will not dry out, the toner will
  last years, and you will forget it exists.
- **You print photographs or colour work.** An inkjet, and a good one. This is the job laser is
  bad at.
- **You print occasionally and in colour.** This is the hard case. An ink-tank inkjet — the kind
  refilled from bottles rather than cartridges — has a far lower cost per page and still dries out
  if left alone. Print something monthly on purpose.
- **You print twice a year.** Do not own a printer.

## Two things on the box that mean less than they look

**Pages per minute** is measured on a draft-quality page of sparse text. Nobody prints that page.

**"Starter" cartridges** ship with many printers at a fraction of a full cartridge's capacity, so
the first replacement arrives much sooner than the first cartridge suggested it would. Check the
capacity of what is in the box before you judge the running cost from it.

## The one that is not about money

**A printer on a network is a computer on your network.** It has an operating system, it very
rarely gets updates, and many models will happily accept a print job from anyone who can reach
them. If yours is shared over Wi-Fi, it belongs behind the same password as everything else, and
a printer offering an open web page on port 80 is a thing to turn off rather than a feature.
