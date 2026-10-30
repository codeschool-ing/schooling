---
title: Four places for a value, and how long each lasts
version: 1
---

**Choosing where a value lives is choosing what it survives.** This lesson met two places and
lesson 2 drew a table of four; here they are again with the planner's values in them, because the
choice comes up for every piece of state the app will ever have.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-lifetimes\" aria-label=\"Four bars against four events, recomposition, rotation, process death and the app swiped away. remember stops at rotation. ViewModel stops at process death. rememberSaveable stops at swiped away. The database bar runs past all four.\"><defs><marker id=\"l04-lifetimes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><line x1=\"250\" y1=\"50\" x2=\"250\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"250\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recomposition</text><line x1=\"380\" y1=\"50\" x2=\"380\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"380\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rotation</text><line x1=\"510\" y1=\"50\" x2=\"510\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"510\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">process death</text><line x1=\"640\" y1=\"50\" x2=\"640\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><text x=\"640\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">swiped away</text><text x=\"150\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">remember</text><rect x=\"165\" y=\"70\" width=\"215\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"380\" y1=\"66\" x2=\"380\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rememberSaveable</text><rect x=\"165\" y=\"105\" width=\"475\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"640\" y1=\"101\" x2=\"640\" y2=\"127\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"149\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ViewModel</text><rect x=\"165\" y=\"140\" width=\"345\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"510\" y1=\"136\" x2=\"510\" y2=\"162\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"150\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">database</text><rect x=\"165\" y=\"175\" width=\"511\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><line x1=\"680\" y1=\"184\" x2=\"712\" y2=\"184\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l04-lifetimes-ah-phosphor)\"></line><text x=\"165\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a bar runs while the value survives; it stops at the event that loses it</text></svg>", "caption": "How long a value lives in each of the four places, measured in the events that end it."}
```

| where | survives | the planner keeps there |
|---|---|---|
| `remember` | recomposition | an animation's progress, a scroll position the user will not miss |
| `rememberSaveable` | rotation and process death, through the `Bundle` | what the user is typing or picking: a draft's minutes, an open dialog |
| a `ViewModel`, lesson 10 | rotation, while the process lives | the screen's data, loaded once and shared by its composables |
| a database, lesson 15 | everything except uninstalling | courses and sessions: the student's work |

**The question to ask of a value is what it would cost the user to lose it.** A scroll position lost
on rotation is a small annoyance; minutes half-entered lost on rotation is a form somebody types
twice; a week of sessions lost to process death is a reason to uninstall the app. Each answer points
at a row.

## Two mistakes in opposite directions

**Too short a life.** The minutes picker of section 06 with plain `remember` loses its number when the
phone turns. The fix is one word, and section 04 measured it.

**Too long a life, or too much in it.** Putting the list of courses in `rememberSaveable` survives a
rotation, and writes every course into the `Bundle` each time the activity stops, toward the 50 kB
limit lesson 2 quoted, for data that a database already holds and could load again. `rememberSaveable`
is for what only the user's fingers produced and nothing else can rebuild.

The rest of the course follows this table. Lesson 10 moves the screen's data into a `ViewModel` and
keeps `rememberSaveable` for the drafts; lesson 15 puts the sessions in Room; lesson 16 decides which
of the two the screen trusts.
