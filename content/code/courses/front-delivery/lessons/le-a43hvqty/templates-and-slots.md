---
title: Templates and slots
version: 1
---

**A `<template>` is markup the browser parses and never renders, and a `<slot>` is a hole in a shadow tree
where the host's own children appear.** Together they let an element say where the page's content goes
without moving the page's content.

## The template

The element's file builds one template when the module is first loaded:

```typescript
const template = document.createElement("template");
template.innerHTML = `
  <style>…</style>
  <slot></slot>
  <span class="when"></span>
  <button type="button" part="button">Mark done</button>
  <span class="done" hidden>done</span>
`;
```

What is inside a template is **inert**: parsed into elements, but not drawn, its scripts not run, its
images not fetched. `template.content` is a document fragment holding them, and each constructor makes
its own copy with `template.content.cloneNode(true)`. The markup is parsed once, however many rows the
page has; cloning a parsed tree is cheaper than parsing a string again for every element.

The `<style>` inside is the element's whole style sheet, and since it is cloned into each shadow tree it
applies to that tree alone. A library with many elements can instead build one `CSSStyleSheet` and give it
to each root through `shadowRoot.adoptedStyleSheets`, so every row shares a single parsed sheet.

## The slot

`<slot></slot>` is the default slot. The host's child nodes, here the text *JavaScript*, are drawn where
it sits, in front of the date. They are not moved: in the DOM they are still children of
`<planner-session>`, which is why the page can change them and style them.

An element with more than one hole names them:

```html
<!-- inside the shadow tree -->
<slot name="title"></slot>
<slot></slot>

<!-- in the page -->
<planner-card>
  <h3 slot="title">JavaScript</h3>
  <p>Two sessions this week.</p>
</planner-card>
```

A child with `slot="title"` goes to the slot with that name, and everything else goes to the default one.
Whatever is written inside a `<slot>` is its **fallback**, shown when nothing is slotted there.

## Text in, or text through an attribute

The course name could have been an attribute, `course="JavaScript"`, drawn by `#render` like the date.
Passing it as content is the better choice for text a person reads: it is visible before the script
runs, it is translated by the page like the rest of the page, and it can hold markup such as a link. Data
the element computes with, the minutes and the date, stays in attributes.
