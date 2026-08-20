---
title: Container queries: the component that measures itself
---

A media query asks the size of the **window**. That breaks down for reusable components: the same card may be in a narrow bar or filling the whole screen, and the window cannot tell the two cases apart.

Container queries ask the size of the **container**:

```css
.list { container-type: inline-size; }

@container (min-width: 400px) {
  .card { display: grid; grid-template-columns: 80px 1fr; }
}
```

The card starts adapting to the space **it** was given, not to the size of the monitor. It is the right answer for a component library, and today it is supported in every current browser.
