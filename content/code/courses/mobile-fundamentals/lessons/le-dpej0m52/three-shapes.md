---
title: Four shapes every app is built from
version: 1
---

**An app's screens are arranged in a few fixed shapes, and every app you have used is some
combination of them: a stack, tabs, a drawer, and a sheet over the top.** The picture most people
bring from the web is a single line of history, where *back* undoes the last click. A phone app has
more structure than that. Some screens sit on top of others, some sit side by side, and some are only
there for a moment, and *back* means something different in each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l10-shapes\" aria-label=\"Four navigation shapes, each drawn as a phone screen. A stack: three screens piled up, courses at the root, a course on it and a new-session form on top; only the top one shows, opening pushes and back pops. Tabs: two piles side by side, Courses and Week, with a bar at the bottom to switch between them; each keeps its own pile. A drawer: a panel of destinations slid in over the screen from the left. A sheet: a panel risen from the bottom over the current screen, for one task, with the screen under it unchanged.\"><defs><marker id=\"l10-shapes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"90\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">stack</text><rect x=\"20\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">tabs</text><rect x=\"200\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">drawer</text><rect x=\"380\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">sheet</text><rect x=\"560\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"34\" y=\"150\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">courses</text><rect x=\"42\" y=\"116\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"94.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">course:sql</text><rect x=\"50\" y=\"82\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"102.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">new-session</text><text x=\"86\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(root)</text><text x=\"90\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">push · back pops</text><rect x=\"210\" y=\"120\" width=\"60\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">courses</text><rect x=\"210\" y=\"90\" width=\"60\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">course:sql</text><rect x=\"276\" y=\"120\" width=\"54\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"303.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">week</text><text x=\"270\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each tab keeps</text><text x=\"270\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its own pile</text><rect x=\"206\" y=\"222\" width=\"128\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">Courses</text><text x=\"302\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Week</text><text x=\"270\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tab bar</text><rect x=\"382\" y=\"34\" width=\"92\" height=\"226\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destination 1</text><text x=\"392\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destination 2</text><text x=\"392\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destination 3</text><text x=\"428\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">slides in</text><text x=\"428\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">over the screen</text><path d=\"M440 200 L466 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-ah-phosphor)\"></path><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the screen under it</text><rect x=\"564\" y=\"120\" width=\"132\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one short task</text><text x=\"630\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">closing it changes</text><text x=\"630\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">nothing underneath</text><path d=\"M630 116 L630 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-ah-phosphor)\"></path></svg>", "caption": "Four shapes, and what back means in each: a stack pops its top screen, tabs pop inside the tab showing, and a drawer or a sheet closes."}
```

## The stack

**A stack is a pile of screens where only the top one shows.** Opening a screen *pushes* it on top;
going back *pops* it off and shows the one under it, as it was left. The planner's Courses list is the
bottom of a stack; tapping a course pushes its detail screen, and tapping "new session" there pushes a
form on top of that. Three screens are in the pile, and the student sees one.

The word for the screen at the bottom is the **root**, or the *start destination* in Android's
navigation library. It is the screen the stack can never pop, because there would be nothing under it
to show. Which screens are on the pile is part of an app's state, the kind lesson 5 saves for the
moment the system takes the process away.

## Tabs

**Tabs are a few stacks side by side, with a bar to switch between them.** The planner has two, Courses
and Week. The common mistake is to think of a tab as one screen. It is a whole stack, and switching
tabs leaves it exactly where it was: the student who was three screens deep in Courses, taps Week, and
taps Courses again, finds the form they were filling in. Apple's Human Interface Guidelines describe tab
bars as letting people switch sections "while preserving the current navigation state within each
section", and Android's navigation library calls the same thing *multiple back stacks*.

**Tapping the tab that is already showing means something too.** By convention it takes that tab back
to its root, so a student who is lost deep inside a tab has a one-tap way home. Apple's documentation
for its tab bar controller says a tap on a tab displays that tab's root view, "even if the tab was
already selected". React Navigation's bottom tabs do the same by default, popping a nested stack to its
first screen on a second press. Tabs suit a handful of top-level sections a person uses often, and on a phone both
companies put the bar that switches between them at the bottom, within reach of a thumb: Apple's tab bar
and Material's navigation bar.

## The drawer

**A drawer is a panel of destinations that slides in from the side, over the content.** Material Design
has one, the navigation drawer, opened by a menu button or a swipe from the edge. It holds more
destinations than a tab bar can, and it hides them, which is its cost: a section nobody can see is a
section fewer people find. Apple's guidelines have no drawer. Their nearest thing is a sidebar, for the
wider screens of an iPad or a Mac, and on an iPhone they point at a tab bar instead. Each destination in
a drawer is the root of a stack, just as each tab is.

## The sheet, and other things that are modal

**A sheet, or a modal screen, rises over everything else for one short task and then goes away.** It
does not join the stack it covers: closing it returns the student to exactly where they were, and
nothing under it moved. Apple's guidelines describe a sheet as a scoped task "closely related to their
current context", and say people expect to dismiss one with a button in the top toolbar or by swiping
down. The planner's "new session" form could be a sheet instead of a pushed screen. That is a design
choice. Pushed, it is a step deeper into a course; as a sheet, it is a quick thing done on top of
whatever was showing.

| shape | what the student sees | what *back* does | the planner's example |
|---|---|---|---|
| stack | the top screen of a pile | pops one screen | Courses, a course, a new session |
| tabs | a bar of sections, each a stack | pops inside the current tab | Courses and Week |
| drawer | a hidden list of sections | closes the drawer if it is open | none; two sections fit in tabs |
| sheet | a panel over the current screen | dismisses the sheet | the new-session form, if drawn that way |

The rest of this lesson is about the column in the middle, because it is where the two platforms part.
