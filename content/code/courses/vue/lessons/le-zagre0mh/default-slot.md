---
title: The default slot
version: 1
---

**A slot is a hole in a component's template that the parent fills with markup of its own.** Props
pass values down; a slot passes *content* down, already written, so that a component can be a frame
around something it knows nothing about. A card, a panel, a dialog, a button with an icon: each one
decides where the content goes and how it is framed, and the parent decides what the content is.

```html
<!-- src/demos/InfoCard.vue -->
<script setup>
const secret = 'the card'
</script>

<template>
  <div class="card">
    <slot>Nothing to show.</slot>
  </div>
</template>
```

```html
<!-- src/demos/DefaultSlot.vue -->
<script setup>
import InfoCard from './InfoCard.vue'

const course = 'Statistics'
</script>

<template>
  <InfoCard>
    <strong>{{ course }}</strong>: 45 of 180 minutes
  </InfoCard>
  <InfoCard />
  <InfoCard>The card's own variable is {{ typeof secret }} here.</InfoCard>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DefaultSlot'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: Property "secret" was accessed during render but is not defined on instance. 
  at <InfoCard> 
  at <DefaultSlot>
== the text of #app
Statistics: 45 of 180 minutes
Nothing to show.
The card's own variable is undefined here.
```

Three cards, three lessons:

- **The first card drew the parent's markup**, bold and all, inside its own `<div class="card">`. The
  `<slot>` element was replaced by whatever the parent wrote between `<InfoCard>` and `</InfoCard>`.
- **The second card was given nothing**, and drew the slot's fallback, the text written inside
  `<slot>…</slot>`. A fallback is how a component says what it shows when the parent has nothing to
  say.
- **The third card tried to read `secret`, the card's own variable, and could not.** Vue warned that
  `secret` is not defined, and `typeof` gave `undefined`.

## Whose variables

The third card is the rule worth remembering: **slot content is compiled in the parent's scope.** It
is written in the parent's template, so it sees the parent's variables, `course` in the first card,
and none of the child's, however close it looks on the page. The child places the content; it does not
lend it anything.

That is a deliberate boundary, the same one the props contract of lesson 6 draws. When a child *does*
want to hand something to the content, a value it computed, an item of a list it is looping over, it
has to say so out loud, and a scoped slot (two sections on) is how.

## What a slot is for

| the parent wants to pass | use |
|---|---|
| a value: a number, a title, a session | a prop |
| a piece of markup: a heading with a link in it, a list, a form | a slot |
| a choice among a few fixed looks | a prop naming the variant, not a slot |

The last row matters because slots are tempting. A button that takes its label as a slot can be given
anything, including a second button inside it, which is invalid HTML and unusable with a keyboard. A
slot gives the parent freedom; give it where the freedom is needed.
