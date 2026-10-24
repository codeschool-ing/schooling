---
title: Why a component needs a workshop
version: 1
---

**A component lives in more states than any single screen shows, and a workshop is a place to see all of
them at once.** The planner's session row is a date, a length and either the word *done* or a button. In
the running app you see whichever states the data happens to contain this week. A session longer than an
hour, a week with nothing planned, a row in the dark theme: each exists only when the data and the
settings line up, so each is the one nobody looked at before it shipped.

The common way to check a component is to run the app and click to the screen that uses it. That checks
the component **in one state, in one context**, after everything around it has loaded. A workshop turns
that around: the component on its own, every interesting state written down as an example, each one a
link somebody can open.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Left: the app at one moment shows the session row in one state, not done, light theme. Right: the workshop shows the same row in every written state, to do, done and long, each in the light and the dark theme, six frames side by side.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the app, this week</text><rect x=\"20\" y=\"34\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">JavaScript</text><text x=\"32\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10-15 · 45 min</text><rect x=\"132\" y=\"74\" width=\"76\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">Mark done</text><text x=\"32\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one state,</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">whatever the data holds</text><text x=\"260\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the workshop</text><rect x=\"260\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">To Do · light</text><text x=\"270\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min</text><rect x=\"260\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">To Do · dark</text><text x=\"270\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min</text><rect x=\"410\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done · light</text><text x=\"420\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min · done</text><rect x=\"410\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done · dark</text><text x=\"420\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min · done</text><rect x=\"560\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Long · light</text><text x=\"570\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 h 15 min</text><rect x=\"560\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Long · dark</text><text x=\"570\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 h 15 min</text><text x=\"260\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every state written down, in every theme</text></svg>", "caption": "The app shows the states its data happens to hold; the workshop shows every state somebody wrote down."}
```

## What Storybook is

**Storybook** is the workshop most teams use. It is an application that runs beside yours, reads files
of examples called **stories**, and draws each story in an isolated frame, with a sidebar of every
component and panels for documentation, controls and accessibility. It supports React, Angular, Vue,
Svelte and plain HTML through separate "frameworks", and the stories you write here would look almost
the same in any of them: a story is a component plus the arguments for one state of it.

| what you get | what it is for |
|---|---|
| one frame per story | a state seen without the app around it |
| controls | changing a story's arguments live, to try a state nobody wrote |
| a docs page per component | the documentation, generated from the stories and their comments |
| the accessibility panel | axe, run on the story you are looking at |
| a static build | the whole workshop as a folder of files, deployable like the planner |

Alternatives exist, smaller and framework-specific, such as Ladle for React and Histoire for Vue and
Svelte. They follow the same idea; Storybook's story format has become the common one, and the others
read it or something close to it.

## What it is for in this course

The design system needs three things a workshop gives. **One place where every component is visible**,
so a designer and a developer argue about the same thing. **Documentation that cannot fall out of date**,
because it is drawn from the code. And **a set of examples that tests can visit**, which turns lesson
3's pipeline into one that catches a component that changed by accident. The last of those is the
section on stories as tests.
