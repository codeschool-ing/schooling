---
title: Utility classes: the style goes in the HTML
version: 1
---

Lesson 10 named classes after **what a thing is**: `.event-card`, with its rules in `event-card.css`. **Tailwind CSS** names classes after **what they do**, one declaration or a few each, and a component is styled by combining them in its `class` attribute:

```html
<article class="mt-4 rounded-lg border-l-4 border-emerald-700 bg-white p-4">
  <h2 class="text-lg font-semibold">Poetry reading</h2>
  <p class="mt-1 text-stone-600">Thursday, 7 pm.</p>
</article>
```

`mt-4` is a top margin, `rounded-lg` rounded corners, `border-l-4` a 4-pixel left border, `p-4` padding. These are **utility classes**, and building with them is called **utility-first**. The card has no name and no stylesheet of its own.

## What it buys and what it costs

**What it buys.** Nobody has to invent and agree on names, which is harder than it sounds and is what BEM exists to manage. Styles cannot leak: a class does one thing wherever it is put, so changing one card cannot break another, and deleting a card deletes its styles with it. The values come from a **scale**, as lesson 10 section 08 recommended: `p-4` and `p-6` exist and `p-[13px]` stands out. And you do not switch between two files to change one thing.

**What it costs.** The HTML gets long, and a list of fifteen classes is harder to read than one good name. The same list repeated on twenty cards is repetition that section 10 has to deal with. And you have to know CSS to use it well: `flex items-center justify-between` is lesson 8, abbreviated. A developer who learnt Tailwind without CSS can write the classes and cannot tell why a layout broke.

That last point is why it is the last lesson of this course and not the first. Every class in this lesson is translated back into the CSS it generates, and the translation is the thing to learn.
