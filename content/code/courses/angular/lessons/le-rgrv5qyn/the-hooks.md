---
title: The hooks, in the order Angular calls them
version: 1
---

**A lifecycle hook is a method with a reserved name that Angular calls at a particular moment in a
component's life: after its inputs are set, after its view is drawn, before it is destroyed.** There
are eight of them, plus two functions that do the same job for drawing. Older Angular code leans on
them heavily, and signals have made most of them unnecessary, so this lesson shows each one firing,
in order, and then sorts them into the few you need and the ones you will only read.

A component that logs every hook, and a bench that shows it, renames it and removes it:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import {\n  AfterContentChecked,\n  AfterContentInit,\n  AfterViewChecked,\n  AfterViewInit,\n  ChangeDetectionStrategy,\n  Component,\n  DoCheck,\n  OnChanges,\n  OnDestroy,\n  OnInit,\n  SimpleChanges,\n  input,\n  signal,\n} from '@angular/core';\n\n@Component({\n  selector: 'app-life',\n  template: '<p>life: {{ label() }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Life\n  implements OnChanges, OnInit, DoCheck, AfterContentInit, AfterContentChecked, AfterViewInit, AfterViewChecked, OnDestroy\n{\n  readonly label = input('');", "note": "Each hook has an interface of the same name without the `ng`. `implements` is optional, and it makes the compiler check each method's name and signature."},
 {"code": "  constructor() {\n    console.log('constructor');\n  }\n  ngOnChanges(changes: SimpleChanges): void {\n    console.log('ngOnChanges:', Object.keys(changes).join(', '));\n  }\n  ngOnInit(): void {\n    console.log('ngOnInit');\n  }\n  ngDoCheck(): void {\n    console.log('ngDoCheck');\n  }\n  ngAfterContentInit(): void {\n    console.log('ngAfterContentInit');\n  }\n  ngAfterContentChecked(): void {\n    console.log('ngAfterContentChecked');\n  }\n  ngAfterViewInit(): void {\n    console.log('ngAfterViewInit');\n  }\n  ngAfterViewChecked(): void {\n    console.log('ngAfterViewChecked');\n  }\n  ngOnDestroy(): void {\n    console.log('ngOnDestroy');\n  }\n}", "note": "Every hook logs its own name. `ngOnChanges` also logs which inputs changed."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Life],\n  template: `\n    <h2>Bench</h2>\n    <button type=\"button\" (click)=\"label.set('renamed')\">Rename</button>\n    <button type=\"button\" (click)=\"shown.set(false)\">Remove</button>\n    @if (shown()) {\n      <app-life [label]=\"label()\" />\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected readonly label = signal('first');\n  protected readonly shown = signal(true);\n}", "note": "The bench can rename `Life` through its input, and remove it with the `@if`."}
]}
```

The bench goes into `App` the way lesson 8's did:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

Load, rename, remove:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Rename' --do 'click Remove'
[vite] connecting...
[vite] connected.
constructor
ngOnChanges: label
ngOnInit
ngDoCheck
ngAfterContentInit
ngAfterContentChecked
ngAfterViewInit
ngAfterViewChecked
Angular is running in development mode.
-- click Rename
ngOnChanges: label
ngDoCheck
ngAfterContentChecked
ngAfterViewChecked
-- click Remove
ngOnDestroy
Bench
RenameRemove
```

The order is the life story:

1. **`constructor`**: the object exists. Its inputs have not been set yet.
2. **`ngOnChanges`**: the inputs were set, here `label`. It runs before `ngOnInit`, and again every time
   an input changes, as `Rename` showed.
3. **`ngOnInit`**: once, after the first `ngOnChanges`. The inputs are there.
4. **`ngDoCheck`**: on every check of the component, even when nothing changed.
5. **`ngAfterContentInit`** and **`ngAfterContentChecked`**: the projected content of lesson 8 is
   ready, once, then after every check.
6. **`ngAfterViewInit`** and **`ngAfterViewChecked`**: the component's own template is drawn, once,
   then after every check.
7. **`ngOnDestroy`**: once, when the `@if` removed it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A time line of one component&#x27;s life. Once, at creation: constructor, then ngOnChanges, ngOnInit, ngAfterContentInit and ngAfterViewInit, with ngDoCheck and the two Checked hooks in between. Then, on every later check: ngOnChanges if an input changed, ngDoCheck, ngAfterContentChecked and ngAfterViewChecked. At the end, once: ngOnDestroy.\"><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,120.0 692.6,123.1 692.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><rect x=\"20\" y=\"20\" width=\"300\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">once, when created</text><text x=\"30.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">constructor</text><text x=\"30.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnChanges</text><text x=\"30.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnInit</text><text x=\"30.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngDoCheck</text><text x=\"180.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentInit</text><text x=\"180.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentChecked</text><text x=\"180.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewInit</text><text x=\"180.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewChecked</text><line x1=\"170.0\" y1=\"108\" x2=\"170.0\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><rect x=\"340\" y=\"20\" width=\"220\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">on every later check</text><text x=\"350.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnChanges*</text><text x=\"350.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngDoCheck</text><text x=\"350.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentChecked</text><text x=\"350.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewChecked</text><line x1=\"450.0\" y1=\"108\" x2=\"450.0\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"20\" width=\"120\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">once, when removed</text><text x=\"590.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnDestroy</text><line x1=\"640.0\" y1=\"108\" x2=\"640.0\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"450\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">* only if an input changed</text><rect x=\"340\" y=\"170\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repeats: how often depends on</text><text x=\"450\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OnPush and zone.js (lesson 7)</text></svg>", "caption": "ngOnInit and the two Init hooks run once; ngDoCheck and the Checked hooks run on every check; ngOnDestroy runs once, at the end."}
```

After `Rename`, four hooks ran again: `ngOnChanges` for the new input, and then `ngDoCheck` and the two
`...Checked` hooks, which run on **every** check of the component, whatever caused it. In this OnPush
component in a zoneless application that is rarely. In a default component of a zone.js application,
lesson 7's walk after every event, it is after every click and every timer anywhere on the page, which
is the warning about those three: code in them runs far more often than anything changes.
