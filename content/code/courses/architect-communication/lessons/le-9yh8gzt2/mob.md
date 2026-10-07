---
title: Mob programming: the whole team at one keyboard
version: 1
---

**Mob programming, now often called ensemble programming, is a whole team working on one task, at one
screen, with one person typing and everybody else navigating, rotating every few minutes.** It sounds
like the least efficient arrangement possible, and for the right task it is the most efficient one a
team has.

## Where it came from

Woody Zuil described the practice from his team at Hunter Industries, which around 2011 began working
this way all day and found that the problems that usually slowed it down (waiting for answers, waiting
for reviews, misunderstandings between people working separately) largely disappeared. The team kept
doing it for years and wrote about it widely.

## How a session runs

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Five people in a ring, Bruna, Diego, Paulo, Rafael and Lívia, with Bruna highlighted as the current driver and dashed arrows passing the role to the next person every 4 to 10 minutes. Beside the ring: one driver types what the others decide; one navigator speaks for the group at a time; a short retrospective at the end.\"><defs><marker id=\"mobrotatio-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"202.0\" y=\"27.0\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Bruna</text><rect x=\"301.8609342109911\" y=\"99.55321559063051\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"349.8609342109911\" y=\"117.55321559063051\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Diego</text><rect x=\"263.71745149070966\" y=\"216.94678440936949\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"311.71745149070966\" y=\"234.94678440936949\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Paulo</text><rect x=\"140.28254850929034\" y=\"216.94678440936949\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"188.28254850929034\" y=\"234.94678440936949\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rafael</text><rect x=\"102.13906578900887\" y=\"99.55321559063054\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"150.13906578900887\" y=\"117.55321559063054\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Lívia</text><path d=\"M288 73 L312 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M335 162 L326 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M265 235 L235 235\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M174 190 L165 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M188 90 L212 73\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><text x=\"250\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the driver moves on</text><text x=\"250\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every 4 to 10 minutes</text><text x=\"430\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one driver types</text><text x=\"430\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what the others decide;</text><text x=\"430\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one navigator speaks</text><text x=\"430\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for the group at a time</text><text x=\"430\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a short retrospective</text><text x=\"430\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">at the end</text></svg>", "caption": "A mob session on the outbox reader. The rotation is on a timer so that everybody types and nobody drifts off."}
```

- **One driver**, at the keyboard, types what the navigators decide. In strong style, the driver does
  not add ideas of their own while driving.
- **Everybody else navigates**, but one speaks for the group at a time, usually the person on the
  driver's left or whoever is next to drive.
- **The driver rotates on a timer**, often every four to ten minutes, so everybody types and nobody
  disengages.
- **A short retrospective** at the end: what worked, what to change next time.

## When Marola uses it

Bruna's team mobs for a few hours on a small number of tasks, and the pattern is clear:

- **the first version of something new**, where the whole team will have to maintain it and every
  design decision is worth making together: the outbox reader from lesson 9 was mobbed for two days;
- **an incident's follow-up**, where the fix touches several people's areas and everybody needs to
  understand it;
- **onboarding**, in a new engineer's first week, so they see how the whole team works in one go.

It does not mob on routine work, and it never mobs for a full week; the team found that more than
about three hours a day left people too tired for anything else.

## The cost, honestly

Five engineers on one task for two days is ten engineer-days. The question is what it replaced: a
design discussion, a review cycle with three rounds of comments, two people learning the code later
under pressure, and a handover document nobody reads. For the outbox reader, Bruna's estimate was that
the mob replaced about the same ten days of that work, and **finished with five people who understood
the code instead of one.** For a routine change it would have replaced nothing.
