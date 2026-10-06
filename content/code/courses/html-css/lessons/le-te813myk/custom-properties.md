---
title: Custom properties: a value with a name
version: 1
---

A **custom property** is a property whose name you choose, starting with two hyphens, and whose value you use elsewhere with **`var()`**. They are often called **CSS variables**, and the name is fair enough, with one difference from the variables of a programming language that the next sections are about. Here is the bookshop's events page, with its colours and its spacing declared once:

```css
:root {
  --green: #2f6f4e;
  --red: #8a1c1c;
  --paper: #fbf8f2;
  --ink: #1d1d1b;

  --accent: var(--green);
  --space: 1rem;
}

body {
  background: var(--paper);
  color: var(--ink);
}

.event {
  padding: var(--space);
  border-left: 4px solid var(--accent);
}
.event h2 { color: var(--accent); }

.cancelled { --accent: var(--red); }
```

The declarations go on **`:root`**, a pseudo-class that matches the `<html>` element, so that every element on the page can use them. `--green` and `--red` are the raw colours. `--accent` is the role, "the colour that marks an event", and its value is another variable. Then the rules use the names: the events' border and their headings take `var(--accent)`, the padding takes `var(--space)`.

```
ana@laptop:~/site$ probe events.html style :root --accent,--space style '.event h2' color style .event padding-left
html  --accent: #2f6f4e
html  --space: 1rem
h2  color: rgb(47, 111, 78)
h2  color: rgb(138, 28, 28)
article.event  padding-left: 16px
article.event.cancelled  padding-left: 16px
```

The root has the values, with `--accent` already resolved to `#2f6f4e`. The first heading is green, `rgb(47, 111, 78)`, and the padding is **16px**, `1rem`. The second heading is **red**, `rgb(138, 28, 28)`, and no rule in the stylesheet says that a heading is red: it reads `var(--accent)` like the first. The next section is why.

## What a custom property is not

**It is not a property that does anything by itself.** `--accent: green` on an element changes nothing about how that element looks; it only stores a value for `var()` to read. The browser does not know what `--accent` means and never will.

**It is not checked when it is declared.** Anything can be stored, `--accent: banana` included, and the browser only discovers whether the value makes sense where it is used. Section 05 is what happens when it does not.

Custom properties are case-sensitive, unlike the rest of CSS: `--Accent` and `--accent` are two different variables.
