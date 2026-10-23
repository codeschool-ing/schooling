---
title: TransitionGroup, for lists
version: 1
---

**`<TransitionGroup>` does for every item of a `v-for` what `<Transition>` does for one element: items
entering and leaving get the `-enter-` and `-leave-` classes, and items that merely move, because
something was inserted before them, get a `-move` class.** The move is the part that makes a list
change read as a list change, instead of rows jumping into new places.

```html
<!-- src/demos/ListDemo.vue -->
<script setup>
import { ref } from 'vue'

const sessions = ref([
  { id: 's2', label: '19 October, Statistics' },
  { id: 's4', label: '21 October, Statistics' },
])
function addFirst() {
  sessions.value = [{ id: 's7', label: '18 October, Guitar' }, ...sessions.value]
}
</script>

<template>
  <button @click="addFirst">Add one at the top</button>
  <TransitionGroup tag="ul" name="slide" id="list">
    <li v-for="s in sessions" :key="s.id">{{ s.label }}</li>
  </TransitionGroup>
</template>

<style>
.slide-enter-active,
.slide-move {
  transition: all 1s ease;
}
.slide-enter-from {
  opacity: 0;
  transform: translateX(-1rem);
}
</style>
```

Add one at the top, and print the list during the second the transition lasts:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ListDemo' --do 'click button' --html '#list' --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of #list
<ul id="list"><li class="slide-enter-active slide-enter-to">18 October, Guitar</li><li class="slide-move" style="">19 October, Statistics</li><li class="slide-move" style="">21 October, Statistics</li></ul>
```

**The new row is entering; the two old rows have `slide-move`**, because each was pushed one place down.
Vue measured where every row was before the change, let the list redraw, measured again, and then
moved each row back to its old position with a `transform` and let the `-move` transition carry it to
the new one. That technique has a name, FLIP: first, last, invert, play.

## Three rules it brings

- **Every item needs a real `:key`.** The move is computed per key, so lesson 5's rule is the whole
  mechanism here: with an index as the key, every row would appear to change instead of moving.
- **`tag` says what element to draw around the items**, here a `<ul>`, so the list is still a list to a
  screen reader. Without `tag`, `<TransitionGroup>` draws no wrapper of its own.
- **The CSS for `-move` needs a `transition`**, or nothing moves: the classes are applied and nothing is
  told to animate them.

The planner's week list, at the end of this lesson, uses it so that a session added for the 24th slides
into its place in date order.
