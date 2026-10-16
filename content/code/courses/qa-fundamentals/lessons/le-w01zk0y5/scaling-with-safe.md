---
title: SAFe, and what changes when there are many teams
version: 1
---

**Scrum, Kanban and XP describe one team. The Scaled Agile Framework, SAFe, describes how dozens of teams work on
one product together.** Dean Leffingwell published it in 2011, and it is now the most widely adopted of the
scaling frameworks, especially in banks, insurers and governments. It is large, detailed and has critics; a tester
in a big organisation is likely to meet it either way.

Cine Aurora has five people and no need for any of this. To see what SAFe changes, imagine Aurora bought by a
national chain that sells tickets for two hundred cinemas, with nine teams working on one ticketing system: one
for prices, one for seats, one for the website, one for the box office terminals, and so on.

## The release train

SAFe's central structure is the **Agile Release Train**, a long-lived group of agile teams, usually 50 to 125
people, that plan, build and deliver together on one shared schedule.

The train works in **Planning Intervals**, called Program Increments before 2023: usually 8 to 12 weeks, made
of several two-week iterations followed by an **Innovation and Planning iteration**. Every team plans the
interval together at the start, at a large event called PI Planning, and the whole train shows its integrated
work at a **System Demo** every iteration.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l14-train\" aria-label=\"Above, an Agile Release Train of five teams, prices, seats, website, box office and reports, with a System Team under them that runs the shared environment and the end-to-end checks. Below, one Planning Interval of eight to twelve weeks: PI Planning at the start, four iterations each ending in a System Demo, and an innovation and planning iteration at the end.\"><rect x=\"10.0\" y=\"10.0\" width=\"660.0\" height=\"112.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">an Agile Release Train: 50 to 125 people</text><rect x=\"24.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"83.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">prices</text><rect x=\"152.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"211.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">seats</text><rect x=\"280.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">website</text><rect x=\"408.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">box office</text><rect x=\"536.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reports</text><rect x=\"24.0\" y=\"80.0\" width=\"630.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">System Team: shared environment, end-to-end checks</text><text x=\"340.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">one Planning Interval, 8 to 12 weeks</text><rect x=\"10.0\" y=\"160.0\" width=\"86.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"53.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">PI Planning</text><rect x=\"104.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteration 1</text><circle cx=\"208.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"216.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteration 2</text><circle cx=\"320.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"328.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteration 3</text><circle cx=\"432.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"440.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"492.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteration 4</text><circle cx=\"544.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"552.0\" y=\"160.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"611.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">innovation and planning</text><text x=\"330.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">● System Demo</text></svg>", "caption": "Many teams, one schedule. The System Demo shows the integrated product every iteration, not each team’s piece."}
```

## What changes for testing

With nine teams, each one can be perfectly agile inside and the product can still be broken, because most of
what goes wrong goes wrong *between* teams. The price team changes how a discount is stored; the box office
team's terminals read the old format. Both teams' checks pass.

So SAFe adds testing that no single team owns:

- **a System Team**, which builds and runs the shared environment where all the teams' work is integrated, and
  the end-to-end checks that cross team boundaries;
- **the System Demo**, where the integrated product, not each team's piece, is shown working every iteration;
- **built-in quality**, which SAFe names as one of its foundations: every team is expected to do the practices
  of lesson 11 and of XP, so the train is not relying on the System Team to find problems late.

## The trap at scale

The Innovation and Planning iteration has a known misuse. Teams under pressure treat it as a **hardening
sprint**: two weeks at the end of every interval to test and fix everything that was not finished. SAFe's own
guidance warns against it, and for the reason this course has repeated since lesson 3: it is the waterfall's
testing phase, back again, with the same cost curve.

For a tester the signs are recognisable from lesson 11. If the System Demo shows work that was never integrated
before the demo, if defects found in one interval are planned for the next, if "done" for a team means "done
apart from integration", then the train has rebuilt the mini-waterfall on a larger scale.

## What a tester in SAFe actually does

Most of the job is the same as in any agile team: questions at planning, examples for acceptance criteria,
exploration, keeping the definition of done honest. What is new is the view across teams. A tester who asks at PI
Planning *which other team reads the data we are changing?* is doing at scale what Lia does at Cine Aurora's
planning when she asks how a story combines with the ones already built.
