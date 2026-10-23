---
title: A signal is a value that says when it changes
version: 1
---

**A signal holds a value, and anything that reads it is told when the value changes.** That second
half is the whole idea. A plain field holds a value too, but nothing knows when somebody writes to it,
so Angular has to go and look; a signal announces it. Lesson 7 is about why that difference decides
how Angular redraws a page. This lesson is about using signals, and it starts outside a component,
because a signal does not need one.

Make a folder for short programs inside the project, so that they find `@angular/core` in its
`node_modules`, and save this in it:

```typescript
// try/signals.mts
import { signal } from '@angular/core';

const minutes = signal(45);
console.log('read:', minutes());

minutes.set(60);
console.log('after set:', minutes());

minutes.update((m) => m + 15);
console.log('after update:', minutes());

const sessions = signal<number[]>([]);
sessions.update((list) => [...list, 30]);
console.log('sessions:', sessions());
```

`.mts` tells Node the file is a module, so it runs the `import` without asking. Node removes the types
and runs it, as in lesson 1:

```
ana@dev:~/planner$ node try/signals.mts
read: 45
after set: 60
after update: 75
sessions: [ 30 ]
```

Three things to read in it:

- **A signal is read by calling it**: `minutes()`, with parentheses. That call is how a signal knows
  who is reading it, which the next section depends on.
- **`set` replaces the value; `update` computes the new one from the old.** Use `update` whenever
  the new value depends on the old, so the read and the write cannot drift apart.
- **`signal<number[]>([])`** names the type when the starting value does not show it: an empty array
  could hold anything. TypeScript infers `signal(45)` as a `WritableSignal<number>` on its own.

## In a template

A template reads a signal the same way, by calling it: `{{ minutes() }}`. Forgetting the parentheses
is the commonest mistake with signals, and the template checking of lesson 4 catches it as a build
error rather than printing a function's source on the page.

In a component, the convention is the one lesson 4 set for fields: `protected readonly`. `readonly`
because the field always holds the same signal, whose value changes; nobody should replace the signal
itself.

```typescript
protected readonly minutes = signal(45);
```

## Where this sits in Angular's history

Signals arrived in Angular 16 as a preview and have been stable since 17 for `signal` and
`computed`, and since 20 for `effect` and `linkedSignal`. The framework is part-way through moving
everything onto them: inputs (lesson 8), queries, forms and the change detection of lesson 7. Code
written before 2023 has none, and you will meet plain fields and RxJS (lesson 13) where today's code
has signals. Both are Angular; this course writes new code the new way.
