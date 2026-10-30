---
title: Classes and styles
version: 1
---

**`[class.name]` adds or removes one class by a condition, and `[style.property]` sets one style from
a value.** They are property bindings with a special first word, and they cover almost every case
where the look of an element depends on the data. Give the bench some styles to switch between:

```css
/* src/app/bench/bench.css */
.long {
  font-weight: 600;
}
.bar {
  height: 0.5rem;
  background: currentColor;
}
```

and a template that uses them:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p [class.long]="minutes > 40">{{ minutes }} minutes</p>
<p [class]="{ long: minutes > 40, short: minutes < 20 }">The same, as an object</p>
<div class="bar" [style.width.%]="minutes / 2.4"></div>
<p [style.color]="minutes > 200 ? 'red' : null">Red past 200</p>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-bench><h2>Bench</h2><p class="long">45 minutes</p><p class="long">The same, as an object</p><div class="bar" style="width: 18.75%;"></div><p>Red past 200</p></app-bench>
```

Four lines, four forms:

- **`[class.long]`** adds `long` while the condition is true and removes it when it is false. Any
  other class on the element is left alone, which matters when a stylesheet or another directive put
  it there.
- **`[class]` with an object** does the same for several classes at once: each key is a class, each
  value its condition. `short` was false, so it is absent.
- **`[style.width.%]`** carries its unit in the name, so the expression is just a number: 45 divided
  by 2.4 is 18.75, and the style says `18.75%`. `.px`, `.rem` and `.em` work the same way.
- **`null` removes a style.** At 45 minutes, `[style.color]` evaluated to `null`, and the paragraph
  has no `style` attribute at all, rather than an empty one.

**Prefer a class to a style.** A class names a state, `long`, and the stylesheet says what it looks
like; a style binding writes the look into the template, where the next person to change the design
has to find it. Style bindings earn their place for values that really are continuous, a width or a
position, as the bar does here.

The old way to write the object form is `[ngClass]` and `[ngStyle]`, directives from
`@angular/common`. They still work, and you will see them in older code; `[class]` and `[style]` do
the same without an import.
