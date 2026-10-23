---
title: Naming a value in the template with @let
version: 1
---

**`@let name = expression;` gives a value a name inside the template, so that it is computed once
and read wherever it is needed.** The week's summary computes `planned - done` and compares `done`
with `planned` separately, which is two ways of asking one question. Name the answer:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned - done;
<p>{{ planned }} minutes planned, {{ done }} done.</p>
@if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

The same page as before, which is the point of a refactoring. Four rules make `@let` predictable:

- **it is read-only.** The template cannot assign to it, not even in an event binding;
- **it is recomputed** every time Angular checks the template, from the values it reads, so it is
  never stale;
- **it is visible after its line**, in the same block and in the blocks inside it, and not before
  it or outside it;
- **its type is inferred**, so `left` is a `number` and the comparison is checked.

## Where it is not the right tool

`@let` is for the template's own convenience: a long expression read twice, or a value unwrapped once
and used in several places. A value that the class also needs, or that takes real work to compute,
belongs in the class, where it can be tested; lesson 6's `computed` is exactly that, and the week's
summary moves `left` there when its numbers stop being constants.
