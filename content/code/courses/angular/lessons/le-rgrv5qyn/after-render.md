---
title: After the DOM is drawn
version: 1
---

**`afterNextRender` runs a function once, after Angular has next written the DOM, and is the place for
code that needs the elements to exist and be laid out: measuring, focusing, handing an element to a
library that draws into it.** `afterEveryRender` runs after every such write. Both replace most uses of
`ngAfterViewInit`, and both run only in the browser, which matters in lesson 23, where the page is first
drawn on a server that has no layout and no focus.

```typescript
// src/app/bench/bench.ts
import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  viewChild,
} from '@angular/core';

@Component({
  selector: 'app-bench',
  template: `
    <h2>Bench</h2>
    <p #para>A paragraph to measure.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly para = viewChild.required<ElementRef<HTMLElement>>('para');

  constructor() {
    console.log('constructor: the paragraph exists?', document.querySelector('app-bench p') !== null);
    afterNextRender(() => {
      console.log('after render: it is', this.para().nativeElement.offsetHeight, 'pixels tall');
    });
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
constructor: the paragraph exists? false
after render: it is 18 pixels tall
Angular is running in development mode.
Bench

A paragraph to measure.
```

In the constructor the paragraph does not exist yet; after the next render it does, laid out, with a
height the browser computed. Reading `offsetHeight` asks the browser to lay the page out, so do it in
`afterNextRender` and not in a computed or a template, where it would run during a check.

`afterNextRender` also takes phases, `earlyRead`, `write`, `mixedReadWrite` and `read`, so that code
that only reads layout runs after code that changes it, and the browser lays the page out once rather
than once per component. You will need them when two components measure and resize each other, and not
before.
