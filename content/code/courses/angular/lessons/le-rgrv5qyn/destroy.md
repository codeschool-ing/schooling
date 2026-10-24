---
title: Cleaning up when a component goes
version: 1
---

**When a component is destroyed, anything it started outside Angular keeps going unless it stops it:
a timer, a listener on `window`, a connection.** The `@if` that removed `Life` in the first section
destroyed the component; it did not stop the timers or listeners the component had started, because
Angular does not know about them. A component that starts a clock shows the leak:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

`--do 'wait 500'` lets half a second pass between actions:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
tick 8
tick 9
tick 10
tick 11
tick 12
tick 13
tick 14
tick 15
tick 16
tick 17
tick 18
tick 19
tick 20
tick 21
tick 22
tick 23
tick 24
tick 25
tick 26
tick 27
tick 28
tick 29
tick 30
tick 31
tick 32
tick 33
tick 34
tick 35
tick 36
tick 37
tick 38
tick 39
tick 40
tick 41
tick 42
tick 43
tick 44
tick 45
tick 46
tick 47
tick 48
tick 49
tick 50
tick 51
tick 52
tick 53
tick 54
tick 55
tick 56
tick 57
tick 58
tick 59
tick 60
tick 61
tick 62
tick 63
tick 64
tick 65
tick 66
tick 67
tick 68
tick 69
tick 70
tick 71
tick 72
tick 73
tick 74
tick 75
tick 76
tick 77
tick 78
tick 79
tick 80
tick 81
tick 82
tick 83
tick 84
tick 85
tick 86
tick 87
tick 88
tick 89
tick 90
tick 91
tick 92
tick 93
tick 94
tick 95
tick 96
tick 97
tick 98
tick 99
tick 100
tick 101
tick 102
tick 103
tick 104
tick 105
tick 106
tick 107
tick 108
tick 109
tick 110
tick 111
tick 112
tick 113
tick 114
tick 115
tick 116
tick 117
tick 118
tick 119
tick 120
tick 121
tick 122
tick 123
tick 124
tick 125
tick 126
tick 127
tick 128
tick 129
tick 130
tick 131
tick 132
tick 133
tick 134
tick 135
tick 136
tick 137
tick 138
tick 139
tick 140
tick 141
tick 142
tick 143
tick 144
tick 145
tick 146
tick 147
tick 148
tick 149
tick 150
tick 151
tick 152
tick 153
tick 154
tick 155
tick 156
tick 157
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

locator.click: Timeout 30000ms exceeded.
Call log:
  - waiting for getByRole('button', { name: 'Remove', exact: true }).or(getByRole('link', { name: 'Remove', exact: true })).first()
    - locator resolved to <button type="button">Remove</button>
  - attempting click action
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
    - waiting 20ms
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
      - waiting 100ms
    58 × waiting for element to be visible, enabled and stable
       - element is visible, enabled and stable
       - scrolling into view if needed
       - done scrolling
       - <vite-error-overlay></vite-error-overlay> intercepts pointer events
     - retrying click action
       - waiting 500ms

    at /home/ana/js-tools/look.mjs:133:69 {
  name: 'TimeoutError'
}

Node.js v22.22.0
```

The clock left the page, and its interval went on ticking for a component that no longer exists,
holding it in memory so it can never be collected. Do that in a component shown in a list, and every
time the list changes another interval starts and none stops.

## DestroyRef

`inject(DestroyRef)` gives the component the object Angular calls when it is destroyed, and
`onDestroy` registers what to run then:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    const id = setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
    inject(DestroyRef).onDestroy(() => {
      clearInterval(id);
      console.log('clock stopped');
    });
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
clock stopped
-- wait 500
Bench
Remove
```

The cleanup is written next to what it cleans up, in the constructor, which is easier to keep right
than a start in `ngOnInit` and a stop in a separate `ngOnDestroy` method. `inject` is lesson 10's
subject; here it is enough that it hands the component things Angular holds for it. **What Angular
started, Angular stops**: effects, `resource` requests and the subscriptions of the `async` pipe end
with the component on their own. What you started with a browser API is yours.
