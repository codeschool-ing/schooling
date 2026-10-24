---
title: Impure pipes, and what they cost
version: 1
---

**`pure: false` makes Angular call `transform` on every change detection of the component, whatever
the arguments.** It is the fix for the stale total, and an expensive one. One word changes in the
bench's pipe:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Pipe, PipeTransform } from '@angular/core';

let calls = 0;

@Pipe({ name: 'total', pure: false })
export class TotalPipe implements PipeTransform {
  transform(values: number[]): number {
    calls++;
    console.log(`total ran, call ${calls}`);
    return values.reduce((sum, value) => sum + value, 0);
  }
}

@Component({
  selector: 'app-bench',
  imports: [TotalPipe],
  template: `
    <p>{{ minutes.join(' + ') }} = {{ minutes | total }}</p>
    <button type="button" (click)="push()">Push 10</button>
    <button type="button" (click)="replace()">Replace with 10 more</button>
    <button type="button" (click)="nothing()">Do nothing</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected minutes = [30, 60];

  protected push(): void {
    this.minutes.push(10);
  }

  protected replace(): void {
    this.minutes = [...this.minutes, 10];
  }

  protected nothing(): void {}
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Push 10' --do 'click Do nothing' --do 'click Do nothing'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Push 10
total ran, call 2
-- click Do nothing
total ran, call 3
-- click Do nothing
total ran, call 4
30 + 60 + 10 = 100
```

The push is counted now. And so is every click that changed nothing: the pipe ran on each check,
because it cannot know that nothing changed. Here it adds three numbers. A pipe that sorted a
thousand sessions would sort them on every keystroke in every field of the page, under zone.js on
every event anywhere, and that is how impure pipes make an application slow without anybody having
written a slow line.

**Angular's own impure pipes are few and deliberate**: `async`, which has to look for a new value
from its Observable, and `json`, `slice` and `keyvalue`, which take objects that may change in place.
A pipe of your own almost never needs to be impure; the data it receives should be replaced, not
changed.
