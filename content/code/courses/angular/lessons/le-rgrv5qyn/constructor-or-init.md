---
title: Constructor or ngOnInit
version: 1
---

**Inputs are not set when the constructor runs, so code that reads an input belongs after it.** That
one fact is why `ngOnInit` exists, and most of the `ngOnInit` in older code is there for no other
reason. Read an input in the constructor and see what happens:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, OnInit, input } from '@angular/core';

@Component({
  selector: 'app-life',
  template: '<p>life: {{ label() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Life implements OnInit {
  readonly label = input.required<string>();

  constructor() {
    console.log('constructor sees', this.label());
  }

  ngOnInit(): void {
    console.log('ngOnInit sees', this.label());
  }
}

@Component({
  selector: 'app-bench',
  imports: [Life],
  template: '<h2>Bench</h2><app-life label="first" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] NG8118: `label` is a required `input` and does not have a value in this context. [plugin angular-compiler]

    src/app/bench/bench.ts:13:36:
      13 │     console.log('constructor sees', this.label());
         ╵                                     ~~~~~~~~~~
```

The compiler refused it, `NG8118`: it saw a required input read in a place where it cannot have a value
yet, and named the line. In code that is not checked this way, an `@Input` read in a constructor, for
instance, the same mistake builds and reads `undefined`, or fails while the page runs with lesson 8's
`NG0950`. Move the read into `ngOnInit` and it sees `first`.

**Signals move the question elsewhere.** A `computed` that reads the input does nothing until somebody
reads *it*, and by then the input is set, so the place it is declared stops mattering:

```typescript
protected readonly title = computed(() => `life: ${this.label()}`);
```

That is the planner's pattern since lesson 8: `CoursePage` declares `course` from `courseId()` in a
field, and never needs `ngOnInit`. What remains for the constructor is what it was always good at:
asking for things, which lesson 10 does with `inject()`, and setting up effects.

What remains for `ngOnInit` is older code, and one real case: work that must happen once, with the
inputs set, and that is not a value, such as sending an analytics event for the record a page opened.
An `effect` would run it again whenever the input changed, which may be exactly wrong.
