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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two trees of the TeleportDemo. On the left, where the markup is written, the card&#x27;s template: the div with class card holds a paragraph, the button, the note with id stays, and a Teleport to body holding the note with id moves. On the right, where it is drawn, the document: body holds the div with id app, which holds the card, which holds the note stays and two comments, teleport start and teleport end, where the Teleport was written; after the script, the last element of body is the note moves, outside app altogether. A dashed arrow joins the Teleport on the left to that note on the right.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where it is written: the template</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where it is drawn: the document</text><rect x=\"40\" y=\"36\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">div.card</text><rect x=\"64\" y=\"70\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p</text><rect x=\"64\" y=\"104\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button</text><rect x=\"64\" y=\"138\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p#stays</text><rect x=\"64\" y=\"172\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;Teleport to=\"body\"&gt;</text><rect x=\"88\" y=\"206\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p#moves</text><rect x=\"400\" y=\"34\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">body</text><rect x=\"422\" y=\"62\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">div#app</text><rect x=\"444\" y=\"90\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">div.card</text><rect x=\"466\" y=\"118\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"551\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">p#stays</text><rect x=\"466\" y=\"146\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"551\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--teleport start--&gt;</text><rect x=\"466\" y=\"174\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"551\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--teleport end--&gt;</text><rect x=\"422\" y=\"202\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">script</text><rect x=\"422\" y=\"230\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">p#moves</text><path d=\"M 282 219 C 340 219, 360 241, 418 241\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"410\" y1=\"241\" x2=\"420\" y2=\"241\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,241.0 412.6,244.1 412.6,237.9\" fill=\"var(--amber)\"></polygon></svg>", "caption": "The Teleport's contents stay in the card's component and are drawn at the end of body."}
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
