---
title: Choosing the diagram for the question
version: 1
---

**Each of the five diagrams answers a different kind of question, and the fastest way to pick one is
to look at the words in the question.** A question with *who* in it, a question with *and then*, a
question with *where*: each points at one notation.

| the question sounds like | the diagram | what it can show that the others cannot |
| --- | --- | --- |
| *who uses the system, and for what?* | **use case** | the boundary of the system and the actors outside it |
| *what is a booking made of? what must always be true?* | **class** | multiplicities, ownership and identity of domain concepts |
| *what happens, in what order, and who waits?* | **sequence** | time, waits and the moment between sent and answered |
| *what depends on what? what could be replaced?* | **component** | interfaces offered and required |
| *what runs where, and what crosses the network?* | **deployment** | machines, counts, protocols and physical placement |

## One scenario, five pictures

The best check that you have understood the five is to take one scenario through all of them, which
is Kruchten's +1 from lesson 1 in practice. For *a passenger buys a ticket*:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l02-five-views\" aria-label=\"One scenario, a passenger buys a ticket, seen through the five diagrams. Use case: the goal and the boundary. Class: what the booking is made of. Sequence: the order of the calls and who waits. Component: which interfaces the calls go through. Deployment: which calls cross the network.\"><rect x=\"200.0\" y=\"10.0\" width=\"320.0\" height=\"30.0\" rx=\"15\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a passenger buys a ticket</text><path d=\"M360.0 40.0 L76.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"12.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"76.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">use case</text><text x=\"76.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the goal and</text><text x=\"76.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the boundary</text><path d=\"M360.0 40.0 L218.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"154.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"218.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">class</text><text x=\"218.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what a booking</text><text x=\"218.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">is made of</text><path d=\"M360.0 40.0 L360.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"296.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sequence</text><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the order and</text><text x=\"360.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">who waits</text><path d=\"M360.0 40.0 L502.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"438.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"502.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">component</text><text x=\"502.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">which interfaces</text><text x=\"502.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the calls use</text><path d=\"M360.0 40.0 L644.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"580.0\" y=\"84.0\" width=\"128.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"644.0\" y=\"115.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">deployment</text><text x=\"644.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">which calls cross</text><text x=\"644.0\" y=\"144.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the network</text></svg>", "caption": "Walking one scenario through all five is how disagreements between them turn up, and sometimes the disagreement is in the code."}
```

- the **use case** says it is the passenger's goal and that it includes taking payment;
- the **class** diagram says what the booking it creates is made of;
- the **sequence** says which calls happen in which order and where the passenger waits;
- the **component** diagram says which interfaces those calls go through;
- the **deployment** diagram says which of those calls cross the network.

Walking the scenario through each one is also how you find disagreements. When Tainá did it for
the purchase, the sequence diagram had a call from Ticketing straight to the Pricing database, and
the component diagram said Ticketing reached Pricing only through `FareQuote`. One of them was
wrong, and it was the code: a shortcut added during the previous São João, still there.

## When UML is the wrong choice

UML is precise for readers who know it. **For readers who do not, its precision is invisible**, and
a hollow diamond is just a diamond. For the board, for Celeste, for a partner company's product
team, a keyed box diagram from lesson 1 or the C4 diagrams of lesson 3 will be read correctly more
often. Lesson 14 is about choosing the picture for the audience; this lesson has given you the five
pictures that engineers expect to be able to read.
