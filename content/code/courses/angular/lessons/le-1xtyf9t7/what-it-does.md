---
title: What change detection is
version: 1
---

**Change detection is Angular walking its tree of components, evaluating every expression in every
template it visits, and changing the DOM wherever a value differs from last time.** It is how
`{{ planned }}` on the page follows `planned` in the class. Two questions decide everything about it:
*when* does Angular walk, and *which* components does it visit. The answers changed over Angular's
history, and that change is what this lesson is about.

The walk is visible if a template calls a method that reports each call. A bench, again:

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests --inline-template --inline-style
CREATE src/app/bench/bench.ts (193 bytes)
```

`--inline-template` and `--inline-style` put the template and the styles inside the class's file,
which suits a component of a few lines, and this lesson writes several.

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  template: `
    <h2>Bench</h2>
    <p>{{ label() }}</p>
    <button type="button" (click)="nothing()">Do nothing</button>
  `,
})
export class Bench {
  protected label(): string {
    console.log('label() called');
    return 'a template expression';
  }

  protected nothing(): void {}
}
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

Load the page, and click a button that changes nothing:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Do nothing'
[vite] connecting...
[vite] connected.
label() called
label() called
Angular is running in development mode.
label() called
-- click Do nothing
label() called
label() called
Bench

a template expression

Do nothing
```

`label()` was called before anybody clicked, more than once, and again after a click that changed
nothing. Every time Angular walks to this component it evaluates the expression, because the only way
to know whether a plain method's answer changed is to ask it. In development mode it also walks a
second time, straight after each walk, to check that nothing moved in between; the section on
`NG0100` is about what that second walk catches.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A tree of four components: App at the top, Week under it, and under Week a summary and a list. A walk starts at App and visits each component from the top down, evaluating its template&#x27;s expressions. On the right, the same tree with the list marked OnPush and not marked: the walk skips it and everything below it.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">default: every component, every walk</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OnPush: only what was marked</text><rect x=\"120\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"120\" y=\"110\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><rect x=\"30\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><rect x=\"210\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseCard</text><line x1=\"180\" y1=\"76\" x2=\"180\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,108.0 176.9,100.6 183.1,100.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"160\" y1=\"146\" x2=\"100\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,178.0 105.0,171.8 108.0,177.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"200\" y1=\"146\" x2=\"260\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,178.0 252.0,177.3 255.0,171.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"480\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"480\" y=\"110\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><rect x=\"390\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard</text><line x1=\"540\" y1=\"76\" x2=\"540\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,108.0 536.9,100.6 543.1,100.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"146\" x2=\"460\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,178.0 465.0,171.8 468.0,177.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"560\" y1=\"146\" x2=\"620\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"620.0,178.0 612.0,177.3 615.0,171.8\" fill=\"var(--wire)\"></polygon><text x=\"630\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OnPush, not marked: skipped</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"255\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line></svg>", "caption": "A walk goes from the root down. An OnPush component that nothing marked is skipped, with everything under it."}
```

That is why lesson 4 called a method in a template cheap only when the method is cheap, and why
lesson 6's `computed` exists: a computed is asked too, and answers from memory unless something it
read has changed.
