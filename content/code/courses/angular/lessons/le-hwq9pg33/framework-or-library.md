---
title: Who calls whom
version: 1
---

**A framework is not a bigger library.** The difference is the direction of the call. Your code
calls a library: you decide when, with what, and what to do with the answer. A framework calls
your code: you write pieces in the shape it asks for, hand them over, and it decides when each one
runs.

You have already used both. In `javascript` lesson 21 you installed packages with npm and called
them; that is a library. In the browser, you wrote a function and passed it to
`addEventListener`, and the browser called it when somebody clicked. That second shape, where you
give up control of *when*, is what a framework does for a whole application.

## What Angular calls

Here is the smallest Angular component there is. Lesson 2 generates one like it and lesson 3 takes
it apart; for now, read it as a list of things you hand over:

```typescript
import { Component } from '@angular/core';

@Component({
  selector: 'app-week',
  template: '<p>This week: {{ minutes }} minutes</p>',
})
export class Week {
  minutes = 165;
}
```

Nothing in it runs anything. There is no `new Week()`, no call that puts the paragraph on the page,
no line that decides when `minutes` is read. Angular does all three. It finds `<app-week>` in a
page, builds a `Week`, reads `minutes` into the template, and reads it again whenever it decides
something may have changed. Lessons 6 and 7 are about exactly how it decides.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two columns. On the left, a library: your code is at the top and calls down into the library&#x27;s functions, and gets their answers back. On the right, a framework: Angular is at the top and calls down into your class, building it, reading its fields into the template, and reading them again when something changes.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a library</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a framework</text><line x1=\"360\" y1=\"12\" x2=\"360\" y2=\"238\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><rect x=\"70\" y=\"44\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">your code</text><text x=\"180\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decides when</text><rect x=\"70\" y=\"170\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the library</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">format(date)</text><line x1=\"150\" y1=\"96\" x2=\"150\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,168.0 146.9,160.6 153.1,160.6\" fill=\"var(--phosphor)\"></polygon><text x=\"144\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">calls</text><line x1=\"210\" y1=\"170\" x2=\"210\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"210.0,98.0 213.1,105.4 206.9,105.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"216\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answers</text><rect x=\"430\" y=\"44\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Angular</text><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decides when</text><rect x=\"430\" y=\"170\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your class</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">class Week { minutes = 165 }</text><line x1=\"470\" y1=\"96\" x2=\"470\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,168.0 466.9,160.6 473.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"474\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">builds it</text><line x1=\"540\" y1=\"96\" x2=\"540\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,168.0 536.9,160.6 543.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"544\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">reads minutes</text><line x1=\"610\" y1=\"96\" x2=\"610\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,168.0 606.9,160.6 613.1,160.6\" fill=\"var(--amber)\"></polygon><text x=\"614\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">reads it again</text></svg>", "caption": "You call a library and it answers. A framework calls you, and decides when."}
```

## What React leaves to you

React describes itself as a library for building user interfaces, and the description is
accurate. It turns your components into DOM and keeps them up to date. Routing, forms, talking to
a server, dependency injection, the build and the test runner are not in it: a React project picks
each one, and two React projects at two companies often picked differently.

Angular ships all of them, written by the same team, released together, on the same version
number:

| concern | in Angular | in a React project |
|---|---|---|
| rendering | `@angular/core` | React |
| routing | `@angular/router` (lessons 17 and 18) | React Router, TanStack Router, or a meta-framework |
| forms | `@angular/forms` (lessons 14 to 16) | React Hook Form, Formik, or by hand |
| server data | `HttpClient` (lesson 12) | `fetch`, TanStack Query, SWR |
| sharing objects | dependency injection (lessons 10 and 11) | context, or a state library |
| build and dev server | the Angular CLI (lesson 2) | Vite, Next.js, or another |
| tests | TestBed and Vitest (lesson 24) | Vitest or Jest, and Testing Library |

**The table is the whole argument of this lesson.** Every row on the left is a decision nobody on
an Angular team has to make, and every row on the right is a decision somebody on a React team did
make, once, and that the next person to join has to learn. Lesson 25 looks at React, Vue and
Svelte side by side with what you will know by then.

## The price of being called

Being called has a cost, and it is paid up front. You cannot write a useful Angular component
without knowing what a decorator is, what the `imports` list does, how a template binds to a
class and, soon after, how dependency injection hands a component what it needs. A React component
is a function returning markup, and a beginner's first one works before they know much else.

So Angular is slower to start and quicker to settle. The first week costs more, and the hundredth
component looks like the first, written the same way by whoever wrote it. The next section is
about who that trade suits.
