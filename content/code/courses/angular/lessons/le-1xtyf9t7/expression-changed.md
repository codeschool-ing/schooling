---
title: NG0100, the error only development mode shows
version: 1
---

**In development mode, Angular walks the tree twice in a row and checks that the second walk finds
every value the same as the first; when one differs, it reports `NG0100`.** A template expression that
gives a different answer each time it is asked, with nothing having changed, is a bug: the page would
show whichever answer happened to be drawn. The second walk is how development mode finds it, and a
production build skips it, which is why the error never appears there.

The commonest cause is a method that reads the clock:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  template: '<h2>Bench</h2><p>Checked at {{ now() }}</p>',
})
export class Bench {
  protected now(): number {
    return Date.now();
  }
}
```

`grep -v` drops the lines of the stack trace, which start with spaces and `at`:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench | grep -v '^    at '
[vite] connecting...
[vite] connected.
[error] ERROR RuntimeError: NG0100: ExpressionChangedAfterItHasBeenCheckedError: Expression has changed after it was checked. Previous value: '1793318437138'. Current value: '1793318437139'. Expression location: _Bench component. Find more at https://v21.angular.dev/errors/NG0100
Angular is running in development mode.
[error] ERROR RuntimeError: NG0100: ExpressionChangedAfterItHasBeenCheckedError: Expression has changed after it was checked. Previous value: '1793318437138'. Current value: '1793318437163'. Expression location: _Bench component. Find more at https://v21.angular.dev/errors/NG0100
Bench

Checked at 1793318437138
```

The message has everything needed: the code, `NG0100`; the previous and the current value,
milliseconds apart; the component, `Bench`; and a link to the page that explains it. The page itself
drew the first value and carried on, which is why the error is easy to miss: it is in the console, not
on the screen.

## What causes it, and the fix for each

- **An expression that is not a pure function of the component's state**: the clock, a random number,
  a new object built on every call. Compute the value once, when it should change, and keep it in a
  signal or a field.
- **A child changing its parent's state while the parent is being checked**, typically in a lifecycle
  hook that runs after the parent's template was drawn. Lesson 9 meets those hooks and their order.
- **A getter that changes something as it reads**, such as one that increments a counter. A template's
  reads must be reads; the change belongs in an event handler.

The fix is never to make the error go away by catching it or turning development mode's check off.
The error is telling you the screen and the state disagree, and in production nobody would be told.
