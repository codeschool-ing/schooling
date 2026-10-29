---
title: The lifecycle, by its old names
version: 1
---

**Every lifecycle hook of lesson 9 exists in the Options API as an option with the same name minus the
`on`: `mounted()`, `updated()`, `unmounted()`.** Two of them have no Composition partner, and they are
the two you will see most in old code: `beforeCreate` and `created`.

```html
<!-- src/demos/OptionsLifecycle.vue -->
<script>
export default {
  data() {
    return { minutes: 30 }
  },
  watch: {
    minutes(now, before) {
      console.log(`watch: ${before} -> ${now}`)
    },
  },
  beforeCreate() {
    console.log(`beforeCreate: minutes is ${this.minutes}`)
  },
  created() {
    console.log(`created: minutes is ${this.minutes}, the element is ${this.$el}`)
  },
  mounted() {
    console.log(`mounted: the element is a ${this.$el.nodeName}`)
  },
  beforeUnmount() {
    console.log('beforeUnmount')
  },
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <button @click="minutes += 15">15 more</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsLifecycle' --do 'click button' --text -
[vite] connecting...
[vite] connected.
beforeCreate: minutes is undefined
created: minutes is 30, the element is null
mounted: the element is a #text
-- click button
watch: 30 -> 45
```

The four moments in the transcript:

- **`beforeCreate`: `minutes` is `undefined`.** The instance exists and `data` has not been set up yet.
  Almost nothing belongs here.
- **`created`: `minutes` is 30, and the element is `null`.** The state exists and nothing has been
  rendered. This is where Options API code starts its requests, and it is exactly what top-level code in
  `<script setup>` is: lesson 9 said that setup *is* creation.
- **`mounted`: the element is a `#text`.** Surprising, and worth a line: `this.$el` is the component's
  root node, and this component has two roots, a `<p>` and a `<button>`. A component with several roots
  has no single element, so Vue points `$el` at an empty text node it uses as a marker. Code written for
  Vue 2, where a component always had exactly one root, often assumes `$el` is that root element; with a
  multi-root component in Vue 3 that assumption breaks. A template ref, lesson 9, names the element you
  mean instead.
- **The watcher** printed `30 -> 45`, the next section's subject.

## The names, side by side

| Options API | Composition API |
|---|---|
| `beforeCreate`, `created` | the top level of `<script setup>` |
| `beforeMount`, `mounted` | `onBeforeMount`, `onMounted` |
| `beforeUpdate`, `updated` | `onBeforeUpdate`, `onUpdated` |
| `beforeUnmount`, `unmounted` | `onBeforeUnmount`, `onUnmounted` |
| `activated`, `deactivated` | `onActivated`, `onDeactivated` |

Vue 2 called the two removal hooks `beforeDestroy` and `destroyed`. Vue 3 renamed them; code
that still uses the old names is code that was not finished migrating, and its cleanup never runs.
