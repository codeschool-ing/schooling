---
title: Conditions with @if
version: 1
---

**`@if (condition) { … }` draws its block while the condition is true and removes it from the page
when it is false.** Not hidden: removed. The elements inside do not exist while the condition is
false, which is the difference between `@if` and the `[hidden]` property of lesson 4, and it matters
for what a screen reader finds and for what a test can query.

The week's summary says how much is planned and how much done. It should also say what is left, or
that nothing is:

```html
<!-- src/app/week-summary/week-summary.html -->
<p>{{ planned }} minutes planned, {{ done }} done.</p>
@if (done >= planned) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ planned - done }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
Angular is running in development mode.
[vite] connected.
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

**The block is part of the template's syntax, not an attribute on an element.** `@if` needs no
import, wraps any number of elements, and puts nothing of its own into the page: there is no wrapper
`<div>` around the paragraph. `@else if (other)` adds a branch between the two, as in JavaScript.

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-week-summary><p>165 minutes planned, 90 done.</p><!--container--><p>75 minutes to go.</p><!--container--><label for="week-progress">Done this week</label><progress id="week-progress" value="90" max="165"></progress></app-week-summary>
```

One paragraph from the `@if`, not two: the `@else` branch was drawn and the other one does not exist
in the page at all. The `<!--container-->` comments are Angular's bookmarks for where a block's
content goes; they are comments, so the browser draws nothing for them.

## Naming what the condition found

A condition is often a value that may be missing: a session that may not have been found, a server
answer that may not have arrived. `as` gives the value a name inside the block, already narrowed to
"not missing", the way lesson 1's `if (next)` narrowed it in TypeScript:

```html
@if (next(); as session) {
  <p>Next: {{ session.date }}, {{ session.minutes }} minutes.</p>
} @else {
  <p>Nothing planned.</p>
}
```

Inside the block, `session` is a `Session` and never `undefined`, so the template type-checks the
property reads. Lesson 6 uses this shape with a signal, which is what `next()` with parentheses is.
