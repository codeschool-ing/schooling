---
title: Teleport, drawn somewhere else
version: 1
---

**`<Teleport to="body">` renders its contents at another place in the document, while they stay part of
the component that wrote them.** The component keeps its state, its props and its events; only the
elements move. It exists for one family of problems: something that must sit on top of the whole page,
a dialog, a toast, a menu, written inside a component whose box would clip it or stack it underneath.

```html
<!-- src/demos/TeleportDemo.vue -->
<script setup>
import { ref } from 'vue'

const open = ref(false)
</script>

<template>
  <div class="card">
    <p>A card that clips whatever overflows it.</p>
    <button @click="open = true">Show the note</button>
    <p v-if="open" class="note" id="stays">A note drawn inside the card</p>
    <Teleport to="body">
      <p v-if="open" class="note" id="moves">A note teleported to the body</p>
    </Teleport>
  </div>
</template>

<style scoped>
.card {
  height: 4rem;
  overflow: hidden;
  border: 1px solid #c9d8cf;
}
</style>
```

Show both notes, and print the whole body:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TeleportDemo' --do 'click button' --html body --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of body
<body>
    <div id="app" data-v-app=""><div data-v-9092e573="" class="card"><p data-v-9092e573="">A card that clips whatever overflows it.</p><button data-v-9092e573="">Show the note</button><p data-v-9092e573="" class="note" id="stays">A note drawn inside the card</p><!--teleport start--><!--teleport end--></div></div>
    <script type="module" src="/src/main.js"></script>
  

<p data-v-9092e573="" class="note" id="moves">A note teleported to the body</p></body>
```

**The first note is inside the card's `<div>`; the second is the last element of `<body>`**, outside
`#app` altogether. Where the teleport was written, Vue left two comments, `<!--teleport start-->` and
`<!--teleport end-->`, to remember the place. The second note still carries the card's scoped-style
attribute, `data-v-9092e573`, because it is still the card's markup.

## Why it matters

The card has `overflow: hidden` and a fixed height, so the first note, drawn inside it, is cut off at
the card's edge: an ordinary CSS rule, set for an ordinary reason, that a dialog living inside the card
cannot escape. The same happens with `transform` and `filter` on any ancestor, and with `z-index` on a
positioned one, each of which creates a new layer the dialog is trapped in. **A teleported element has
none of its old ancestors**, so none of their rules reach it.

`to` takes any CSS selector, `#modals` for a container of your own, and `:disabled="true"` renders the
contents in place after all, which is useful for showing the same component inline on a large screen
and as an overlay on a small one.

## What it does not change

Teleport moves elements, not the component. Props, emitted events and provide and inject work exactly
as before, because they belong to the component tree. **DOM events follow the DOM**, though: a click
inside the teleported note bubbles up to `<body>`, not through the card's `<div>`, so a listener on the
card does not hear it.
And the focus is not moved: a teleported note that appears does not take the keyboard user there. For
something that needs the focus, a dialog, the browser's own `<dialog>` element does that part, and it
is the next section.
