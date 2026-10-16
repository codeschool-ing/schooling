---
title: The three amigos, and a map of examples
version: 1
---

**The three amigos is a short meeting, before a story is started, between the three perspectives a story
needs: business, development and testing.** The name was coined by George Dinwiddie around 2009. It is not a
fixed group of three people; it is three questions asked by whoever can ask them best.

| perspective | at Cine Aurora | the question it asks |
|---|---|---|
| business | Joana | what problem are we solving, and what is the rule? |
| development | Rafael or Tomás | how could we build it, and what would be hard? |
| testing | Lia | what could go wrong, and what about the case nobody mentioned? |

The meeting lasts twenty or thirty minutes per story. Its output is not a document. It is a set of examples
everybody agrees on, a short list of open questions with a name beside each, and a shared sense of whether the
story is small enough to build.

## Example mapping

A technique that keeps the meeting short and its output visible is **example mapping**, described by Matt Wynne
in 2015. It uses four colours of card:

- **yellow**: the story, one card at the top;
- **blue**: a **rule**, one card for each rule the story contains;
- **green**: an **example**, under the rule it illustrates;
- **red**: a **question** nobody in the room can answer yet.

The table is the map. Cine Aurora mapped the story *older customers and students pay half, without stacking with
Wednesday*, which collected two rules Joana had given at different times:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l17-map\" aria-label=\"An example map. At the top, the story card: older customers and students pay half, without stacking with Wednesday. Two rule cards under it. Rule one, 60 and over pay half, with three examples: 59 pays R$ 36,00, 60 pays R$ 18,00, 61 pays R$ 18,00. Rule two, half is the most, with three examples: an adult on Wednesday pays R$ 18,00, a student on Wednesday R$ 18,00, a child at a Wednesday 15:00 session R$ 14,00. To the right, one question card: is a session ever typed as 9:30? Lia asks Célia.\"><rect x=\"10.0\" y=\"10.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">older customers and students pay half, without stacking with Wednesday</text><rect x=\"10.0\" y=\"62.0\" width=\"230.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">60 and over pay half</text><rect x=\"20.0\" y=\"106.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">59 pays R$ 36,00</text><rect x=\"20.0\" y=\"148.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">60 pays R$ 18,00</text><rect x=\"20.0\" y=\"190.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">61 pays R$ 18,00</text><rect x=\"250.0\" y=\"62.0\" width=\"230.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">half is the most</text><rect x=\"260.0\" y=\"106.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">adult, Wed: R$ 18,00</text><rect x=\"260.0\" y=\"148.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">student, Wed: R$ 18,00</text><rect x=\"260.0\" y=\"190.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">child, Wed 15:00: R$ 14,00</text><rect x=\"500.0\" y=\"62.0\" width=\"170.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"585.0\" y=\"90.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">is a session ever typed as 9:30?</text><text x=\"585.0\" y=\"103.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Lia asks Célia</text><rect x=\"504.0\" y=\"193.0\" width=\"18.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">story: a yellow card</text><rect x=\"504.0\" y=\"215.0\" width=\"18.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rule: blue</text><rect x=\"504.0\" y=\"237.0\" width=\"18.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"244.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">example: green</text><rect x=\"504.0\" y=\"259.0\" width=\"18.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"530.0\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">question: red</text></svg>", "caption": "Cine Aurora’s map for one story. The six examples are its acceptance tests; the question has an owner and no answer yet."}
```

Reading the map is reading the story's health:

- **many red cards** means the story is not understood; it goes back to Joana before anybody builds it;
- **a rule with many green cards** is a rule that might be its own story;
- **a rule with no green card** has not been understood, however clear its sentence looks;
- **few cards of every colour** means the story is ready, and the green cards are its acceptance tests.

The red card on this map is lesson 4's: a session typed as *9:30*. Nobody could say whether the box office would
ever type it, so Lia took the question to Célia. It is a good example of what the meeting is for. It did not
answer the question; it made sure somebody owned it before the code was written.

## What the tester brings to the table

In lesson 12, Lia added the cases nobody thought of to the acceptance criteria. At the three amigos she does the
same thing, earlier, with two differences. Her questions arrive while the rule is still being decided, so some of
them change the rule rather than the tests. And every answer is written on a green card, in front of the person
who decided it, so nothing depends on anybody's memory of a conversation.
