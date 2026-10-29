---
title: Transition, for one element coming and going
version: 1
---

**`<Transition>` wraps one element that appears or disappears, through `v-if` or `v-show`, and adds CSS
classes to it at each step, so that a stylesheet can animate the change.** Vue does not animate
anything itself: it only puts the right class on at the right moment and takes it off when the browser
says the CSS transition has ended.

```html
<!-- src/demos/FadeDemo.vue -->
<script setup>
import { ref } from 'vue'

const shown = ref(false)
let started = 0

function beforeEnter() {
  started = performance.now()
}
function afterEnter() {
  console.log(`the enter transition took about ${Math.round((performance.now() - started) / 100) * 100} ms`)
}
</script>

<template>
  <button @click="shown = !shown">Toggle</button>
  <Transition name="fade" @before-enter="beforeEnter" @after-enter="afterEnter">
    <p v-if="shown" id="note">Saved in this browser.</p>
  </Transition>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.6s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
@media (prefers-reduced-motion: reduce) {
  .fade-enter-active,
  .fade-leave-active {
    transition: none;
  }
}
</style>
```

Toggle it and print the paragraph straight away, while the fade is still running:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FadeDemo' --do 'click button' --html '#note' --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of #note
<p id="note" class="fade-enter-active fade-enter-to">Saved in this browser.</p>
```

**The paragraph carries `fade-enter-active` and `fade-enter-to`**, caught in the middle of its 600
milliseconds. Toggle it again and wait for the end:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FadeDemo' --do 'click button' --do 'wait 1000' --text -
[vite] connecting...
[vite] connected.
-- click button
-- wait 1000
the enter transition took about 600 ms
```

The `after-enter` hook ran when the transition ended, about 600 milliseconds after it began, which is
the duration the stylesheet set: Vue reads the duration from the element's computed style and waits for
the browser's `transitionend`.

## The six classes

For a transition named `fade`, Vue puts these on the element:

| entering | leaving | when |
|---|---|---|
| `fade-enter-from` | `fade-leave-from` | the first frame: the starting state |
| `fade-enter-active` | `fade-leave-active` | the whole time: where `transition:` is written |
| `fade-enter-to` | `fade-leave-to` | from the second frame to the end: the target state |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of an element entering with a transition named fade, lasting 600 milliseconds. fade-enter-active is on for the whole duration. fade-enter-from is on only for the first frame. fade-enter-to is on from the second frame to the end. When the browser reports transitionend, fade-enter-active and fade-enter-to are removed and after-enter runs.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-from</text><rect x=\"170\" y=\"29\" width=\"24\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-active</text><rect x=\"170\" y=\"67\" width=\"480\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-to</text><rect x=\"194\" y=\"105\" width=\"456\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"170\" y1=\"160\" x2=\"690\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,160.0 682.6,163.1 682.6,156.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"650\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 ms</text><line x1=\"650\" y1=\"24\" x2=\"650\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"644\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">transitionend: after-enter</text><text x=\"200\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one frame</text></svg>", "caption": "Vue switches classes on and off; the stylesheet decides what each of them looks like and how long it lasts."}
```

In the demo, `enter-from` and `leave-to` are `opacity: 0`, and `-active` says how long and with which
curve. When leaving, Vue keeps the element in the page until `fade-leave-active` has finished, and only
then removes it, which is the one thing CSS on its own cannot do: animate an element that `v-if` is
about to delete.

The hooks, `@before-enter`, `@after-enter`, `@leave` and the rest, are for transitions driven by
JavaScript, or, as here, for knowing when one has ended. The classes are the usual way.
