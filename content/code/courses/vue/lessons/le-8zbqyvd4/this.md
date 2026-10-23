---
title: this, and the arrow that loses it
version: 1
---

**Inside an option, `this` is the component instance only when the option is an ordinary function.** An
arrow function has no `this` of its own; it takes the `this` of the place it was written, which in a
module is `undefined`. So a method written as an arrow cannot reach the component, and the first click
proves it.

```html
<!-- src/demos/ThisTrap.vue -->
<script>
export default {
  data() {
    return { minutes: 30 }
  },
  methods: {
    longer() {
      this.minutes += 15
    },
    shorter: () => {
      this.minutes -= 15
    },
  },
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <button id="longer" @click="longer">Longer</button>
  <button id="shorter" @click="shorter">Shorter</button>
</template>
```

Press `Longer`, then `Shorter`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ThisTrap' --do 'click #longer' --do 'click #shorter'
[vite] connecting...
[vite] connected.
-- click #longer
-- click #shorter
[warn] [Vue warn]: Unhandled error during execution of native event handler 
  at <ThisTrap>
Uncaught TypeError: Cannot read properties of undefined (reading 'minutes')
== the text of #app
45 minutes

LongerShorter
```

**`Longer` worked and `Shorter` threw**: `Cannot read properties of undefined (reading 'minutes')`. Vue
calls each method with `this` set to the component, and for `longer`, an ordinary method, that is what
`this` became. An arrow function ignores how it is called: its `this` was fixed when the module was
evaluated, and at the top level of an ES module `this` is `undefined`. `javascript` lesson 6 explained
why arrows behave this way; here is the price of forgetting it inside an object of options.

## The rule, and its one exception

**Every option that uses `this` is written as a method**: `data() {}`, `mounted() {}`, `percent() {}`,
`ask() {}`. Never `data: () => {}` and never `ask: () => {}`.

**Inside** a method, arrow functions are what you want, precisely because they keep the method's
`this`:

```javascript
methods: {
  later() {
    setTimeout(() => {
      this.minutes += 15 // the method's `this`: the component
    }, 1000)
  },
},
```

An ordinary `function () {}` in the `setTimeout` would have its own `this`, set by the timer, which is
not the component. Old code solves that with `const self = this` or `.bind(this)`; with arrows it is not
needed.

## Why the Composition API has no such trap

`<script setup>` has no `this` to lose. `clicks` is a variable, closed over by every function that uses
it, arrow or not. This is one of the quiet reasons the Composition API is easier to get right, and one
of the reasons Vue's own documentation recommends it for new applications.
