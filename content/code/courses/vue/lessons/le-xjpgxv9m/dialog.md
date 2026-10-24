---
title: The dialog, done by the browser
version: 1
---

**The `<dialog>` element, opened with `showModal()`, is a modal the browser draws on its top layer: it
sits above everything, makes the rest of the page inert, moves the focus inside, closes with Escape, and
returns the focus to where it was.** Every one of those is a thing a hand-made modal of positioned
`<div>`s has to get right, and usually gets partly right. Vue's part is small: a template ref to call
`showModal()`.

```html
<!-- src/demos/DialogDemo.vue -->
<script setup>
import { useTemplateRef } from 'vue'

const dialog = useTemplateRef('dialog')

function open() {
  dialog.value.showModal()
  console.log(`opened; focus is on #${document.activeElement.id}`)
}
function closed() {
  console.log(`closed with "${dialog.value.returnValue}"; focus is back on #${document.activeElement.id}`)
}
</script>

<template>
  <button id="open" @click="open">Add a session</button>
  <dialog ref="dialog" aria-labelledby="dialog-title" @close="closed">
    <h2 id="dialog-title">Add a session</h2>
    <form method="dialog">
      <label>Minutes <input id="minutes" type="number" value="30" /></label>
      <button id="cancel" value="cancel">Cancel</button>
      <button id="add" value="add">Add</button>
    </form>
  </dialog>
</template>
```

Open it and press Escape; open it again and press *Add*:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DialogDemo' --do 'click #open' --do 'press Escape' --do 'click #open' --do 'click #add' --text -
[vite] connecting...
[vite] connected.
-- click #open
opened; focus is on #minutes
-- press Escape
closed with ""; focus is back on #open
-- click #open
opened; focus is on #minutes
-- click #add
closed with "add"; focus is back on #open
```

**Each time it opened, the focus went to the first field inside, `#minutes`; each time it closed, the
focus came back to the button that opened it.** Escape closed it with an empty `returnValue`; the *Add*
button, inside a `<form method="dialog">`, closed it with its own `value`, `"add"`. No line of the demo
moves the focus or listens for Escape.

## What to add to it

- **A name**: `aria-labelledby` pointing at the dialog's heading, so a screen reader announces *Add a
  session, dialog* when it opens.
- **A way to close it that a mouse user can see**: Escape is invisible. A close button, ideally in a
  `<form method="dialog">` so that it needs no handler.
- **A Teleport, sometimes.** The top layer already puts a modal dialog above any `overflow` or
  `z-index`, so Teleport is not needed for drawing it. It still helps keep the dialog out of the markup
  of whatever component opened it, and the planner's dialog uses one for that, with the last section of
  this lesson showing it.

`dialog.show()`, without *Modal*, opens it as an ordinary box in the page, with no top layer and no
inert background. A modal is the one people mean when they say dialog.
