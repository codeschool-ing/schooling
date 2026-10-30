---
title: A library you call, a framework that calls you
version: 1
---

**React does one job.** Given what your app knows right now, it works out what the screen should
show, and changes the page until it shows that. Which address shows which screen, how data
arrives from a server, how a form checks what was typed, how the code is built and how it is
tested: React decides none of it. Angular ships every one of those in the same box, written by the
same team, released together under one version number.

The picture most people arrive with is that React is a smaller Angular, the same kind of thing with
fewer parts. **The difference is not size. It is who decides.**

## Who calls whom

The usual way to tell the two words apart is to ask which code calls which. **A library is code you
call**: you decide when, and it does its job and returns. **A framework is code that calls yours**:
it owns the program's shape, and your code fills in the places it leaves open.

React sits on both sides of that line, and the project you create later in this lesson shows where.
This is the file that starts it:

```
ana@dev:~/planner$ cat src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

You call React once, on the last four lines: find the element with the id `root`, and render the
component `App` into it. From then on **React calls `App`**, every time something it depends on
changes, and you never call it yourself. For drawing the screen, React behaves like a framework.
For everything else it is a library: it never calls your router, because it does not know you
have one.

## What Angular decides for you

An Angular project is created by Angular's own command-line tool, and it arrives with a router, an
HTTP client, a forms module, a way of handing services to the components that need them, and a
build, all from packages named `@angular/…` that move together. There is one way to do each thing,
and the documentation teaches that way.

A React project arrives with React. Everything else is a package you pick, from a different team,
on its own release schedule:

```schooling-figure
{"svg": "<svg data-fig=\"who-decides\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Seven jobs an app needs, from drawing the screen to running tests. In a React project only the first two come from the react package, and the other five are packages chosen separately, each with the lesson of this course that adds it. In an Angular project all seven come from Angular's own packages, inside one boundary.\"><text x=\"330\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">a React project</text><text x=\"600\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">an Angular project</text><rect x=\"222\" y=\"44\" width=\"216\" height=\"78\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"482\" y=\"44\" width=\"236\" height=\"268\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"12\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">drawing the screen</text><rect x=\"230\" y=\"50\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">react</text><rect x=\"490\" y=\"50\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/core</text><text x=\"12\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">state in a component</text><rect x=\"230\" y=\"88\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">react</text><rect x=\"490\" y=\"88\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/core</text><text x=\"12\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">which address, which screen</text><rect x=\"230\" y=\"126\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">react-router · 17</text><rect x=\"490\" y=\"126\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/router</text><text x=\"12\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data from a server</text><rect x=\"230\" y=\"164\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">@tanstack/react-query · 11</text><rect x=\"490\" y=\"164\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/common/http</text><text x=\"12\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">forms and validation</text><rect x=\"230\" y=\"202\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">react-hook-form · 10</text><rect x=\"490\" y=\"202\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/forms</text><text x=\"12\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build and dev server</text><rect x=\"230\" y=\"240\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vite · 20</text><rect x=\"490\" y=\"240\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/cli</text><text x=\"12\" y=\"291\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tests</text><rect x=\"230\" y=\"278\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vitest · 22</text><rect x=\"490\" y=\"278\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/cli</text><text x=\"330\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dashed: a package you choose</text></svg>", "caption": "Who decides each job. The numbers are the lessons of this course that add each piece."}
```

Neither arrangement is better in general, and lesson 24 comes back to this question with all four
of the track's options side by side. What this one costs you is **choices**. A React developer
meets questions an Angular developer never has to answer: which router, which way of fetching
data, which form library. A wrong choice is not fatal, and an unmaintained one is a migration
later. The upside is that each piece can be swapped on its own, and React itself stays small
enough to learn in full.

## Frameworks built on React

Because React leaves so much open, other teams have built frameworks around it that close those
questions for you. **Next.js** and **React Router** in its framework mode are the two you will meet
most often, and React's own documentation recommends starting a new app with one of them. It also
documents the other road: a build tool such as Vite, and the pieces added one at a time.

This course takes the second road first, on purpose. Every piece a framework would hide is one you
add yourself, in the lesson that explains it, so that when lesson 18 hands you Next.js you can see
what it is doing for you. The next section lists the pieces and the lesson each one arrives in.
