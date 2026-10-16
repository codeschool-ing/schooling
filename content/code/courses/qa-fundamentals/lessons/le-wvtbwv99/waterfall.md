---
title: The waterfall, and what its author actually said
version: 1
---

**The waterfall model is the sequence most people picture when they think of building software
properly:** gather all the requirements, then design the whole system, then write all the code, then test
it, then hand it over. Each phase finishes before the next begins, and each produces documents the next
one works from. Work flows downhill, one step at a time, which is where the name comes from.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 270\" role=\"img\" data-fig=\"l09-waterfall\" aria-label=\"Five phases drawn as steps going down and to the right: requirements, design, implementation, testing, operation. Each phase hands a document to the next: specification, design document, code, test report. A dashed arrow runs back up from testing to requirements, labelled going back costs more the further down you are.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"79.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirements</text><path d=\"M138.0 37.0 L152.0 37.0 L152.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"158.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">specification</text><rect x=\"142.0\" y=\"64.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"201.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">design</text><path d=\"M260.0 81.0 L274.0 81.0 L274.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"280.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">design document</text><rect x=\"264.0\" y=\"108.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">implementation</text><path d=\"M382.0 125.0 L396.0 125.0 L396.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"402.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">code</text><rect x=\"386.0\" y=\"152.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testing</text><path d=\"M504.0 169.0 L518.0 169.0 L518.0 195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"524.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">test report</text><rect x=\"508.0\" y=\"196.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">operation</text><path d=\"M400 187 C 330 245, 110 240, 79 56\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"250.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">going back costs more the further down you are</text></svg>", "caption": "The waterfall as it is usually drawn. Testing is the fourth step, the first moment the system meets anything but its own documents."}
```

## Where testing sits

In the waterfall, testing is a phase, and it comes late: after every line has been written. Everything
lessons 3 and 5 described follows from that position. Defects found in testing were made months earlier,
in a requirement or a design that the whole system was then built on. The tester receives a finished
product all at once, under a deadline that has usually already slipped by the time code reaches them, and
the testing phase becomes the one that gets squeezed.

## What Royce wrote

The model is usually credited to **Winston Royce**, whose 1970 paper *Managing the Development of Large
Software Systems* contains the famous diagram of phases flowing downward. What is less often repeated is
the sentence right under it, in which Royce calls this approach **risky and inviting failure**, precisely
because testing comes at the end and is the first moment anything is checked against reality. The rest of
the paper proposes fixes: going back to earlier phases, building a pilot version first, involving the
customer throughout.

So the model that bears his name is, to a large extent, the one he warned against. It spread anyway,
because a sequence of phases with a document at the end of each is easy to plan, easy to put in a
contract and easy to report on.

## Why it is still worth knowing

Calling the waterfall obsolete is common and only half right. It still fits some places, and you will
work in them:

- **regulated domains**, such as medical devices, aviation and banking, where an auditor needs evidence
  that each requirement was designed, built and tested, in order, with records;
- **fixed-price contracts**, where the customer pays for a specified result and the specification has to
  be agreed before work starts;
- **hardware alongside software**, where the physical part cannot be changed every two weeks and the
  software has to be ready for a fixed date.

And even teams that never use it inherit its vocabulary: requirements, design, implementation, testing,
release. The next lessons are mostly about rearranging those same activities, not about inventing new ones.

## What a tester does inside one

Inside a waterfall project, a tester's best move is lesson 1's: get involved **before** the testing phase.
Read the requirements as they are written and ask lesson 2's four questions. Write test plans and test
cases while the design is being written, from the requirement, so that testing can start the day the code
arrives. That is the idea the V model turns into a diagram, in the next section.
