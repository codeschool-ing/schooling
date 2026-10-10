---
title: The agile testing quadrants
version: 1
---

**When testing happens all the time, a team needs a way to see whether it is testing everything it should,
or only the parts that are easy.** The most widely used map for that is the **agile testing quadrants**,
proposed by Brian Marick in 2003 and made famous by Lisa Crispin and Janet Gregory in *Agile Testing*.

The map has two axes:

- **left and right**: tests that **support the team**, helping it build the thing right as it goes, against
  tests that **critique the product**, finding out whether what was built is good enough once it exists;
- **top and bottom**: tests that face the **business**, expressed in terms a product owner understands,
  against tests that face the **technology**, expressed in terms of code and infrastructure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l11-quadrants\" aria-label=\"A square divided into four quadrants. Columns: supporting the team on the left, critiquing the product on the right. Rows: business-facing on top, technology-facing below. Top left, Q2: examples and story tests. Top right, Q3: exploration, usability, acceptance. Bottom left, Q1: unit and component tests. Bottom right, Q4: performance, load, security.\"><text x=\"340.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">business-facing</text><text x=\"340.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">technology-facing</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">supporting the team</text><text x=\"540.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">critiquing the product</text><rect x=\"153.0\" y=\"43.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Q2</text><text x=\"245.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">examples, story tests</text><rect x=\"343.0\" y=\"43.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Q3</text><text x=\"435.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exploration, usability,</text><text x=\"435.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">acceptance</text><rect x=\"153.0\" y=\"153.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Q1</text><text x=\"245.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">unit and component tests</text><rect x=\"343.0\" y=\"153.0\" width=\"184.0\" height=\"104.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Q4</text><text x=\"435.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">performance, load,</text><text x=\"435.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">security</text></svg>", "caption": "Marick’s quadrants, as Crispin and Gregory drew them. Many good tests are born on the right, found by exploring, and kept on the left, as an example checked on every change."}
```

## The four, at Cine Aurora

| quadrant | what it holds | at Cine Aurora |
|---|---|---|
| **Q1**: technology-facing, supporting the team | unit and component tests, written by developers as they code | a test that `price(60, …)` is 1800, run on every change |
| **Q2**: business-facing, supporting the team | examples and story tests that say what a feature should do, often automated | "a student on a Wednesday pays R$ 18,00", written before the code with Joana |
| **Q3**: business-facing, critiquing the product | exploratory testing, usability, demonstrations, user acceptance | Lia exploring the seat map; Célia trying the shop at the counter |
| **Q4**: technology-facing, critiquing the product | performance, load, security and other characteristics from lesson 2 | three hundred buyers on a blockbuster's opening night |

The quadrants are numbered for reference, not for order. A team does not work through Q1 and then Q2; it
does some of all four in every cycle, in whatever proportion the product needs.

## What the map is for

The quadrants are a **checklist against blind spots**, like lesson 2's nine characteristics. A team that
automates heavily often has a full Q1 and Q2 and nothing in Q3, because exploration does not produce a
green tick. A team of manual testers often has a busy Q3 and an empty Q1, because nobody writes unit tests.
Drawing the team's actual testing on the map, honestly, shows the empty corner.

Two of this course's defects make the point. The stacking discount on Wednesday was found by Lia asking
what the rule did not say: that is Q3, critique, from the business side. Kept afterwards as an example
written with Joana, it moves to Q2, where it supports the team and is checked on every change. **Many good
tests start their life in Q3 and end it in Q2 or Q1**: found by exploring, kept by automating.

## What the map is not

It is not a list of who does what, although it is often read that way. Developers explore, testers write
examples, product owners take part in Q3. And it is not a measure of quality: a team with tests in all four
quadrants can still test the wrong things in each. It is a picture that makes one particular gap, a whole
category of testing nobody is doing, impossible to miss.
