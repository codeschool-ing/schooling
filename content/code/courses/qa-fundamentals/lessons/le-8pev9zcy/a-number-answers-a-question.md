---
title: A number answers a question, or it is decoration
version: 1
---

**A metric is worth collecting when it answers a question somebody needs answered to make a decision.** Everything
else on a dashboard is decoration, and decoration is not harmless: it takes time to collect, attention to read, and
it tends to become the thing people are judged by.

## From goal to question to number

Victor Basili and colleagues described a simple discipline for this in the 1980s, the **Goal, Question, Metric**
approach: start from a goal, ask the questions that would tell you whether you are reaching it, and only then choose
the numbers that answer those questions. The order is the point. Most bad metrics come from running it backwards:
starting from a number that is easy to collect and inventing a reason for it afterwards.

Cine Aurora ran it forwards for its own testing:

| goal | question | metric |
|---|---|---|
| customers are charged the right price | how many pricing defects reach customers? | defects found after release, by area |
| testing finds the defects that matter before release | of all the defects we know of, how many did we find first? | detection percentage |
| a defect that reaches a customer does not stay long | how quickly is a pricing defect fixed once known? | days from report to fix |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" data-fig=\"l22-gqm\" aria-label=\"Goal, question, metric, as three columns read left to right. Goal: right prices for customers; question: how many pricing defects reach customers; metric: escaped defects by area. Goal: defects found before release; question: how many did we find first; metric: detection percentage. Goal: escaped defects do not linger; question: how fast is a pricing defect fixed; metric: days from report to fix. Under the metrics: what decision would change if this number changed?\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">goal</text><text x=\"345.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">question</text><text x=\"585.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">metric</text><rect x=\"10.0\" y=\"32.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">right prices for customers</text><path d=\"M211.0 52.0 L229.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"32.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">how many pricing defects reach customers?</text><path d=\"M461.0 52.0 L479.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"32.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">escaped defects, by area</text><rect x=\"10.0\" y=\"84.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">defects found before release</text><path d=\"M211.0 104.0 L229.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"84.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">how many did we find first?</text><path d=\"M461.0 104.0 L479.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"84.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">detection percentage</text><rect x=\"10.0\" y=\"136.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">escaped defects do not linger</text><path d=\"M211.0 156.0 L229.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"136.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">how fast is a pricing defect fixed?</text><path d=\"M461.0 156.0 L479.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"136.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">days from report to fix</text><text x=\"690.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">what decision would change if this number changed?</text></svg>", "caption": "Run forwards, from goal to number. Most bad metrics come from running it backwards."}
```

Each number has a question above it and a goal above that. When somebody proposes a new number, the first question at
Cine Aurora is the one this lesson keeps returning to: **what decision would change if this number changed?**

## Numbers that sound useful and are not

Some test metrics are popular everywhere and answer almost nothing:

- **test cases written** or **test cases executed**: a hundred trivial cases and one careful one count as a hundred
  and one; the number rewards writing many small tests, not finding defects;
- **defects found per tester**: it rewards splitting one defect into five reports and punishes the tester who spent a
  day on the one subtle defect that mattered;
- **percentage of tests automated**: automated *what*? A suite can be ninety per cent automated and check nothing a
  customer would notice;
- **pass rate**: lesson 21 showed what a percentage of passing tests hides.

None of these is always useless. Each becomes useless, or worse, when it is reported without a question, and each
becomes harmful when somebody is rewarded for it, which is the next section.

## Measures that look outward

The numbers in Cine Aurora's table share something: they look at what reaches the customer, not at how busy the team
was. Activity is easy to count and says little about quality. A tester who ran four hundred tests last month has told
you how the month was spent. A team whose detection percentage went from 60% to 80% has told you something about its
customers' experience.
