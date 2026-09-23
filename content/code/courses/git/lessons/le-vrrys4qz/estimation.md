---
title: Estimating, and what the number is for
version: 1
---

Once a ticket is ready, most teams put a size on it. The size helps planning (lesson 18) decide how much fits
in a sprint, and it tells the product owner what a ticket costs before they decide how important it is.

## Points, not hours

Many teams estimate in **story points**, a unit with no meaning except relative to other tickets. A 2 is
about twice a 1; a 5 is noticeably bigger than a 3. The usual scale is **1, 2, 3, 5, 8, 13**: the gaps grow
because the uncertainty grows, and nobody can honestly tell a 9 from a 10.

Why not hours? Because people are bad at predicting how long something takes and reasonably good at saying
whether it is bigger or smaller than something they already did. *"Like the holiday notice, but with a
form"* is an estimate anybody can make. *"Eleven hours"* is a guess dressed as a measurement, and it becomes
a deadline the moment somebody writes it down.

A **13 is a signal, not a size**: it usually means the ticket is too big or too unclear, and it goes back to
refinement to be split.

## Planning poker

The best-known way to estimate is **planning poker**. Everybody who will build or test the ticket holds a
card with each number, reads the ticket, and **everybody reveals at the same time**. The simultaneous reveal
is the whole point: nobody anchors on the first number said aloud, and a quiet person's worry gets the
same weight as a confident person's guess.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A round of planning poker on the ticket pay by Pix. At the first reveal, Ana shows 3, Bruno 13, Carla 3 and Diego 5. After the talk, in which Bruno explains that a refund is a manual form at the bank, the second reveal is 8, 8, 8 and 8.\"><defs><marker id=\"pk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">first reveal</text><rect x=\"220\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"248\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ana</text><rect x=\"330\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--amber)\">13</text><text x=\"358\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"440\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"468\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Carla</text><rect x=\"550\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"578\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">after the talk</text><rect x=\"220\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"248\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ana</text><rect x=\"330\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"358\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"440\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"468\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Carla</text><rect x=\"550\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"578\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego</text><path d=\"M358 118 L358 164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pk-ah)\"></path><text x=\"372\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Bruno knew a refund is a manual form at the bank</text></svg>", "caption": "The number that disagreed carried the information. Without the reveal, Bruno’s 13 would have been a quiet worry."}
```

The first round on *pay by Pix* was 3, 13, 3, 5. The team does not average it. The highest and lowest
explain their numbers, and Bruno's 13 turns out to be information nobody else had: refunds are a manual form
at the bank, so every Pix payment needs a way to be undone by hand. After two minutes of talk, the second
round agrees on 8, and the ticket gains an acceptance criterion about refunds.

## An estimate is not a promise

Points added up over a sprint give the team's **velocity**: roughly how much it finishes in two weeks. It is
useful for the team to plan the next sprint, and harmful the moment it is used to compare teams or judge
people, because points are relative to one team and anybody can inflate them. Some teams skip numbers
altogether and only check that each ticket is small, and they plan just as well.

What every version shares is the conversation. **A team that estimates in silence learns nothing; a team
that argues about a 3 and a 13 finds the refund problem on Tuesday instead of in production.**
