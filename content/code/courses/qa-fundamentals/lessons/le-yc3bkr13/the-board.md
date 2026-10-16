---
title: A board that shows where the work is waiting
version: 1
---

**Kanban is a way of managing work by making it visible, limiting how much of it is in progress, and
improving how it flows.** It has no sprints, no roles and no events of its own. A team starts from whatever
it does today, draws it on a board, and changes it a little at a time.

The word is Japanese for a signboard or card. At Toyota in the 1950s, Taiichi Ohno used cards to control
production: a station only made more parts when a card arrived asking for them, so no station could pile up
work the next one was not ready for. In software, David J. Anderson adapted the idea in the mid-2000s,
first with a maintenance team at Microsoft, and described the method in his 2010 book *Kanban*.

## Why Cine Aurora has a board as well as sprints

The price work runs in sprints. Another kind of work does not fit them: Célia's requests from the box office
and the defects found in production. They arrive any day, most are small, and some cannot wait two weeks.
Rafael and Lia handle that stream on a Kanban board, and the rest of this lesson follows it.

## The board

Each card is one piece of work. Each column is a step it goes through. Cine Aurora's board started like this:

| ready | building | waiting for test | testing | done |
|---|---|---|---|---|
| receipt shows the seat | refund button | session list sorted | matinée on holidays | |
| child price on the sign | | Wednesday banner | | |
| | | report total in bold | | |

Three things about the board are worth noticing, and the second matters most to a tester.

- **Testing is a column.** It is not hidden inside "in progress", so a card that is built but untested looks
  different from a card that is finished.
- **"Waiting for test" is a column too.** A card sitting there is not being worked on by anybody. Drawing the
  wait makes it visible, and the board above already shows a queue of three.
- **The board shows where work waits, not who is busy.** Everybody at Cine Aurora was busy. The board was
  what showed that a card spent most of its life waiting for somebody.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l13-board\" aria-label=\"A Kanban board with five columns: ready, building, waiting for test, testing and done. Ready holds two cards, building one, waiting for test three, testing one, done none. The waiting for test column is highlighted, with a note: nobody is working on these.\"><rect x=\"10.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">ready</text><rect x=\"18.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">receipt shows the seat</text><rect x=\"18.0\" y=\"86.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">child price on the sign</text><rect x=\"144.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">building</text><rect x=\"152.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">refund button</text><rect x=\"278.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"341.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">waiting for test</text><rect x=\"286.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">session list sorted</text><rect x=\"286.0\" y=\"86.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">Wednesday banner</text><rect x=\"286.0\" y=\"128.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">report total in bold</text><rect x=\"412.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testing</text><rect x=\"420.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">matinée on holidays</text><rect x=\"546.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"609.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">done</text><text x=\"341.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nobody is working on these</text></svg>", "caption": "Cine Aurora’s first board. Drawing the wait as a column of its own is what showed the queue."}
```

## A board is not a method yet

A team that draws columns and stops there has a to-do list on a wall. What makes it Kanban is what the
next sections add: a limit on how many cards each column may hold, measurements of how long cards take, and
policies written on the board that say what a card needs before it moves. Anderson lists them as the core
practices: **visualise the work, limit work in progress, manage flow, make policies explicit, implement
feedback loops, and improve collaboratively**. Visualising is the first and the easiest, and on its own it
changes very little.
