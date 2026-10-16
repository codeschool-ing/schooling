---
title: The quality of the way it was made
version: 1
---

**Product quality is a property of the thing; process quality is a property of how the thing gets
made.** The two are linked, and the link is weaker than most process documents imply. That gap is
where a tester earns a living.

## The bet process quality makes

The idea is old and comes from factories. If the way you make something is sound, repeatable and
checked at each step, the things it makes will be good, and you will not need to inspect every one at
the end. W. Edwards Deming spent a career arguing exactly that: **inspection at the end does not
improve quality**, it only sorts the good from the bad, and the cost of the bad has already been paid.
Build quality into the process and there is less to sort.

Software adopted the idea in two families of frameworks you will see named in job adverts and
contracts:

- **ISO 9001**, the general standard for quality management systems in any industry. A company that is
  certified has shown an auditor that it defines its processes, follows them, records that it did, and
  improves them. It says nothing specific about software.
- **CMMI**, Capability Maturity Model Integration, which grew from work at Carnegie Mellon for the US
  Department of Defense in the late 1980s. It rates an organisation on five maturity levels, from
  **initial**, where success depends on heroes, through managed, defined and quantitatively managed, to
  **optimizing**, where the process is measured and improved continuously.

Inside a single team, the same bet takes smaller forms: a definition of done every change must meet, a
review before every merge, an automated test suite that runs on every change, a retrospective after
every sprint. Each is a statement about **how** work is done, and each is there because the team
believes doing work that way produces fewer defects.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l02-chain\" aria-label=\"Four boxes in a row: process, how it is made; the code, internal quality; the running product, external quality; in somebody’s hands, quality in use. Arrows above run left to right, labelled influences; arrows below run right to left, labelled depends on. Under each box is the Cine Aurora example: review before merge, the line age greater than 60, R$ 36,00 for a sixty-year-old, a pensioner overcharged.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"qa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"14.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"84.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">process</text><text x=\"84.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">how it is made</text><text x=\"84.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">review before merge</text><path d=\"M84.0 116.0 L84.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><rect x=\"186.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"256.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the code</text><text x=\"256.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">internal quality</text><text x=\"256.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">age &gt; 60</text><path d=\"M256.0 116.0 L256.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M157.0 76.0 L183.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M183.0 104.0 L157.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"358.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the running product</text><text x=\"428.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">external quality</text><text x=\"428.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">R$ 36,00 for sixty</text><path d=\"M428.0 116.0 L428.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M329.0 76.0 L355.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M355.0 104.0 L329.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"80.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in somebody’s hands</text><text x=\"600.0\" y=\"95.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quality in use</text><text x=\"600.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a pensioner overcharged</text><path d=\"M600.0 116.0 L600.0 154.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M501.0 76.0 L527.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><path d=\"M527.0 104.0 L501.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"170.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">influences</text><text x=\"170.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depends on</text></svg>", "caption": "The chain the standards draw. Each link makes the next more likely to be good and guarantees nothing: the review was done, and the pensioner was still overcharged."}
```

## Where the bet fails

The link from process to product runs one way and is probabilistic. A good process makes good products
**more likely**. It does not make them certain, and it can be followed perfectly while producing the
wrong thing every time.

Cine Aurora's team had a process: every change was reviewed by a second developer before it was merged.
The review of `tickets.py` happened. Tomás, the other developer, read `age > 60`, compared it with the
sentence *over-60s*, and approved it, because it matched. **The process was followed and the defect
went through**, because the process checked code against the requirement and nothing checked the
requirement against the world.

That is the general shape of a process failure: every step does what it says, and none of the steps
looks at the thing that went wrong. A certificate on the wall, an ISO 9001 audit or a CMMI level, tells
you the steps exist and are followed. It does not tell you the steps are the right ones.

## Measuring each

The two halves are measured differently, and confusing the two produces some of the theatre lesson 22
describes.

- **Product measures** look at the thing: defects found in it, how many escaped to customers, how fast
  it answers, how many users finish a purchase.
- **Process measures** look at the work: how many changes were reviewed, how long a change waits for a
  tester, how often the test suite runs, how long a defect takes to fix.

A process measure is only worth having if it is linked to a product measure somebody cares about.
"Every change was reviewed" is a fine fact; it was true of `age > 60`. What would make it useful is
knowing how many of the defects customers found had passed a review, which is a question that joins
the two and that very few teams ask.

## What a tester does with both

Test the product, and **question the process with what the product tells you**. Every defect that
reaches a customer passed through every step of the process; for each one, it is worth asking which
step could have caught it and why that step did not. The answer is sometimes a better test, and
sometimes a review checklist that gains one line: *does any boundary in the requirement read two ways?*
That one line is process quality, bought with one defect, and lesson 18 turns the question into a
method.
