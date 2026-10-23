---
title: The application you build
version: 1
---

**Every lesson from 2 to 24 adds to one application, a study planner, in one folder, `~/planner`.**
It is small on purpose: two screens and a handful of records, so that each lesson's new idea is the
only new thing on the page. By lesson 24 it has routing, forms, a server to talk to, state, tests and
server-side rendering, and you will have written every file in it.

## What it does

A student lists the courses they are studying, opens one, adds study sessions to it with a date and
a number of minutes, marks them done, and sees the total for the week.

| screen | address | what is on it |
|---|---|---|
| **the week** | `/` | the week's total, planned and done, and each course with its own minutes this week |
| **a course** | `/courses/git` | that course's sessions, each with its date, its minutes and a box to mark it done, and a form to add one |

A week runs from Monday to Sunday, and the planner counts the week that contains today. Today is
whatever the computer says, which is a problem for a course whose transcripts have to match yours,
so `look` has a `--today` option that sets the browser's date. The transcripts use Friday 23 October
2026.

## The data

Three courses and six sessions, in October 2026. Lesson 2 saves them as `public/courses.json`, a file
the dev server hands to the browser as it is, and from lesson 12 a small server of your own holds
them, so that adding a session survives a reload.

| session | course | date | minutes | done |
|---|---|---|---|---|
| 1 | JavaScript | Tuesday 13 October | 45 | yes |
| 2 | HTML and CSS | Monday 19 October | 30 | yes |
| 3 | JavaScript | Tuesday 20 October | 60 | yes |
| 4 | Git | Thursday 22 October | 25 | no |
| 5 | JavaScript | Saturday 24 October | 50 | no |
| 6 | HTML and CSS | Tuesday 27 October | 40 | no |

With today on the 23rd, the week is the 19th to the 25th, so sessions 2 to 5 are in it. **165
minutes planned, 90 of them done**: those are the first two numbers the application will print, in
lesson 6, and it is worth having worked them out by hand before a program does.

## The pieces

An Angular application is a tree of components, each one a class with a template, each one drawing
a part of the screen and containing the parts below it. The planner's tree, as lessons 3 to 8 build
it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The planner&#x27;s component tree. App at the top. Under it, the two screens: Week, which contains a week summary and one course card per course, and CoursePage, which contains a session list made of session rows, and a form to add a session.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"360.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the shell</text><rect x=\"110\" y=\"96\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><text x=\"200.0\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">screen: /</text><rect x=\"430\" y=\"96\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CoursePage</text><text x=\"520.0\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">screen: /courses/:id</text><line x1=\"330\" y1=\"60\" x2=\"220\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"220.0,94.0 226.1,88.8 228.0,94.8\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"60\" x2=\"500\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"500.0,94.0 492.0,94.8 493.9,88.8\" fill=\"var(--wire)\"></polygon><rect x=\"20\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"95.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">planned and done</text><rect x=\"190\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseCard</text><text x=\"265.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one per course</text><rect x=\"380\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionList</text><text x=\"455.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the course's sessions</text><rect x=\"550\" y=\"190\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">AddSession</text><text x=\"625.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a form</text><line x1=\"170\" y1=\"142\" x2=\"95\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,188.0 99.7,181.5 102.9,186.8\" fill=\"var(--wire)\"></polygon><line x1=\"230\" y1=\"142\" x2=\"265\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"265.0,188.0 258.1,184.0 263.0,180.2\" fill=\"var(--wire)\"></polygon><line x1=\"490\" y1=\"142\" x2=\"455\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,188.0 457.0,180.2 461.9,184.0\" fill=\"var(--wire)\"></polygon><line x1=\"550\" y1=\"142\" x2=\"625\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"625.0,188.0 617.1,186.8 620.3,181.5\" fill=\"var(--wire)\"></polygon><rect x=\"380\" y=\"254\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionRow</text><line x1=\"455\" y1=\"236\" x2=\"455\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,252.0 451.9,244.6 458.1,244.6\" fill=\"var(--wire)\"></polygon><text x=\"540\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one per session</text></svg>", "caption": "Each box is a component you write; each line down is one template using another."}
```

Each box is a file you write, and each line down is one component using another in its template.
`App` is the shell that stays on screen; the router of lesson 17 decides which of the two screens
sits inside it.

## The same application, three more times

The `frontend` track forks here: React, Angular, Vue or Svelte, and you take one. The four courses
build **this same planner**, with the same two screens and the same six sessions. Somebody who took
the React course recognises every screen of yours and none of your code, and that is deliberate.
Lesson 25 puts the four side by side, and because the application is the same, the differences you
see there are the frameworks' and not the examples'.
