---
title: Quality inside the flow, not at the end of it
version: 1
---

**Without sprints there is no sprint review and no end of the cycle to test at, so quality has to be built
into each step a card passes through.** Kanban has two tools for that, both from the factory it came from:
written policies on the board, and stopping the line.

## Policies written on the board

"Make policies explicit" is one of the core practices, and for a tester it is the important one. A
**policy** is the rule for leaving a column, written where everybody can see it, at the top of the column.
Cine Aurora's board carries these:

| column | a card may leave when |
|---|---|
| building | the code is reviewed and the automated checks pass |
| waiting for test | Lia, or whoever is testing, has pulled it |
| testing | each example in the card passes, and it has been explored for half an hour |
| done | Célia has seen it working at the box office |

Look at what that is: **lesson 12's definition of done, split by column**. Each column has its own exit
criteria, and a card that does not meet them does not move, however urgent it feels. Lesson 21 gives the same
idea a name of its own, entry and exit criteria, for whole test cycles.

A policy also settles arguments before they start. When Rafael asked whether a one-line fix could skip
"testing", the answer was on the board: no column says "unless it is small".

## Stopping the line

Toyota's production system has a second idea that Kanban teams borrow: **jidoka**, usually translated as
*automation with a human touch*. A machine that detects something wrong stops itself, and any worker who sees
a defect may pull a cord that stops the line. The point is that a defect is fixed where it appears, instead of
being passed down the line to become somebody else's problem, more expensive at every station.

On a board, stopping the line looks like this:

- a card with a problem gets a **blocked** marker, a red sticker on a physical board, and stays where it is;
- the blocked card counts against the column's limit, so the column fills up and the problem becomes everybody's
  problem fast;
- the team asks the retrospective's question, **why was it possible?**, while the card is still blocked,
  rather than at the end of a cycle that Kanban does not have.

## Urgent work, without breaking the board

Defects found in production do not wait in "ready". Kanban handles them with **classes of service**: an
*expedite* lane at the top of the board for a card that skips the queue. Cine Aurora's policy for it is two
lines long: only a defect that charges a customer the wrong price or stops a sale may use it, and only one card
may be in it at a time. Without that second line, everything becomes urgent, and the lane becomes the board.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l13-lanes\" aria-label=\"A Kanban board with four columns, building, waiting for test, testing and done, each with its exit policy written under the name: reviewed and checks pass; a tester pulled it; examples pass and explored; Célia saw it. Above the standard lane is an expedite lane, one card at most, holding the card wrong price on Sundays in testing. In the standard lane, the card session list sorted in testing carries a red blocked marker.\"><rect x=\"100.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"168.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">building</text><text x=\"168.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">reviewed, checks pass</text><rect x=\"245.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"313.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">waiting for test</text><text x=\"313.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">a tester pulled it</text><rect x=\"390.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testing</text><text x=\"458.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">examples pass, explored</text><rect x=\"535.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">done</text><text x=\"603.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">Célia saw it</text><path d=\"M10.0 56.0 L96.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M10.0 120.0 L96.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M104.0 56.0 L233.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M104.0 120.0 L233.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M249.0 56.0 L378.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M249.0 120.0 L378.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M394.0 56.0 L523.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M394.0 120.0 L523.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M539.0 56.0 L668.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M539.0 120.0 L668.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"14.0\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">expedite</text><text x=\"14.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">1 card at most</text><text x=\"14.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">standard</text><rect x=\"400.0\" y=\"70.0\" width=\"117.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">wrong price on Sundays</text><rect x=\"110.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"168.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">refund button</text><rect x=\"400.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">session list sorted</text><rect x=\"545.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">receipt seat</text><rect x=\"400.0\" y=\"172.0\" width=\"117.0\" height=\"18.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--amber)\">blocked</text></svg>", "caption": "Policies at the top of each column, an expedite lane for the defect that cannot wait, and a blocked card that stays where it is until the team deals with it."}
```

## Cadences instead of events

Kanban still has meetings; it calls them cadences, and the team picks their rhythm. Cine Aurora has three:
a short stand-up at the board every morning that walks the board from right to left, from the cards nearest
done back to the newest, so finishing comes before starting; a weekly **replenishment** meeting where Joana
chooses what goes into "ready"; and a monthly review of the flow measures, where Lia brings the cumulative
flow diagram. The retrospective's question is asked there too, about every card that was blocked.
