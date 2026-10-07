---
title: When div and span are right
version: 1
---

After a lesson about choosing meaningful elements, it is worth being clear about the two that mean nothing, because they are not mistakes. **`<div>` is a generic block and `<span>` is a generic piece of inline text.** They exist for the times you need an element and the content has no meaning that an element could express, which happens constantly, mostly for layout and styling.

A row of three event cards needs a wrapper so CSS can lay the cards out side by side. The cards are articles; the row is not anything. It is a `<div>`:

```html
<div class="cards">
  <article>…</article>
  <article>…</article>
  <article>…</article>
</div>
```

A price in a sentence needs a colour. The price is not emphasised, not important, not a term; it is just text CSS has to reach:

```html
<p>First edition, <span class="price">R$ 240</span>, in very good condition.</p>
```

Both are correct. In the accessibility tree they leave no trace, and that is right: there is nothing to tell anybody.

## The test

Before writing a `<div>`, ask the question from lesson 1: **what is this?** If the answer is a heading, a list, a navigation block, a self-contained item, a button, use that element. If the honest answer is "a box for the layout", use a `<div>` and stop worrying about it.

The failure this lesson is about is not using `<div>`. It is using `<div>` **where the content had a meaning**, as the soup page did with its title, its menu and its events, so that the meaning ended up in a class name where only the CSS and the person reading the file could find it.

## A note on ARIA

ARIA attributes, `role` and `aria-*`, can add meaning to a `<div>`: `role="navigation"`, `role="button"`. They exist for widgets HTML does not have, such as tabs or a tree view, and the `javascript` and framework courses use them there. For anything HTML does have, the element is shorter, comes with its behaviour, and cannot be half-done. **No ARIA is better than bad ARIA**: a wrong role tells assistive technology something false, which is worse than telling it nothing.
