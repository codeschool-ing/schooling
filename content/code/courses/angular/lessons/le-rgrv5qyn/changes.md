---
title: Reacting to an input changing
version: 1
---

**`ngOnChanges` runs whenever an input changes, and receives what the change was; with signal inputs,
a `computed` or an `effect` that reads the input does the same job with less code.** The hook was the
only way to react to an input in the decorator era, so it is everywhere in older code, usually to keep
a derived field in step:

```typescript
// the decorator era
@Input() minutes = 0;
hours = 0;

ngOnChanges(changes: SimpleChanges): void {
  if (changes['minutes']) {
    this.hours = this.minutes / 60;
  }
}
```

`changes` holds one entry per changed input, with `previousValue`, `currentValue` and `firstChange`.
The code has to check which input changed, copy the value into a field, and remember that the field
exists only to follow the input. Lesson 6 would call that an effect that sets a signal, and it has the
same answer:

```typescript
// with signals
readonly minutes = input(0);
protected readonly hours = computed(() => this.minutes() / 60);
```

No hook, no check of which input changed, no field to keep in step. The `computed` reads the input, so
it follows the input, which is all `ngOnChanges` was arranged to achieve.

When the reaction is not a value but an act on the outside world, it is an `effect`, which lesson 6
introduced for exactly that:

```typescript
constructor() {
  effect(() => {
    document.title = `${this.minutes()} minutes this week`;
  });
}
```

`ngOnChanges` also fires only for changes made through the template binding, not for a value set from
code, which was a source of bugs a computed simply does not have. You will still read it, and when you
migrate an `@Input` to `input()` with lesson 8's migration, the `ngOnChanges` beside it is the next
thing to turn into a `computed`.
