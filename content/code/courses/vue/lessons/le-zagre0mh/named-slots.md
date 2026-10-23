---
title: Named slots
version: 1
---

**A component can have several slots, each with a name, and the parent fills each one with a
`<template>` naming it.** The usual case is a frame with more than one place for content: a panel with
a header, a body and a footer, where each part is the parent's to write.

```html
<!-- src/demos/TitledPanel.vue -->
<template>
  <section class="panel">
    <header>
      <slot name="header">Untitled</slot>
    </header>
    <slot />
    <footer v-if="$slots.footer">
      <slot name="footer" />
    </footer>
  </section>
</template>
```

```html
<!-- src/demos/NamedSlots.vue -->
<script setup>
import TitledPanel from './TitledPanel.vue'
</script>

<template>
  <TitledPanel>
    <template #header><h2>This week</h2></template>
    <p>Five sessions planned.</p>
    <template #footer>75 of 195 minutes done</template>
  </TitledPanel>
  <TitledPanel>
    <p>A panel with no header and no footer.</p>
  </TitledPanel>
</template>
```

This time the HTML is the evidence, so `look` prints it:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=NamedSlots' --html '#app' --text -
[vite] connecting...
[vite] connected.
== the HTML of #app
<div id="app" data-v-app=""><section class="panel"><header><h2>This week</h2></header><p>Five sessions planned.</p><footer>75 of 195 minutes done</footer></section><section class="panel"><header>Untitled</header><p>A panel with no header and no footer.</p><!--v-if--></section></div>
```

**`<template #header>` filled the slot named `header`.** `#header` is short for `v-slot:header`, as `@`
is for `v-on`. Content outside any `<template #…>`, the paragraph, went into the slot with no name,
which is called `default`. The `<template>` element itself leaves nothing on the page.

**The second panel had no header and drew the fallback, `Untitled`. And it had no footer, so it has no
`<footer>` element at all**, only the `<!--v-if-->` placeholder. That is what `v-if="$slots.footer"`
is for: `$slots` holds a function for each slot the parent actually filled, so the panel can ask whether
there is a footer before drawing an empty box with a border around nothing.

## When a slot counts as empty

A fallback is drawn when the parent's content for that slot is empty, and **content that is only a
`v-if` that came out false counts as empty**: it rendered nothing but a placeholder comment. The
planner's panel at the end of this lesson relies on exactly that. It is also where `$slots` can
mislead: `$slots.footer` is truthy whenever the parent wrote a `#footer`, even one whose only content is a
`v-if` that came out false, so the panel would draw an empty footer. For that case the fallback is the
better tool than `$slots`.

## Order and spelling

The order of the `<template>`s in the parent does not matter; the child's template decides where each
slot goes. A slot's name is a plain string, so `#footer` in the parent must match `name="footer"` in the
child exactly. A misspelt slot name fills nothing and warns about nothing: the content just does not
appear, which is the one silent failure of slots. If something you wrote between a component's tags
is missing from the page, compare the names first.
