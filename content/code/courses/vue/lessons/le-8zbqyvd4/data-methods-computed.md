---
title: data, computed and methods
version: 1
---

**In the Options API, `data` returns the component's state, `computed` defines its derived values and
`methods` its functions, and all three are merged onto `this`.** Each is the Options spelling of
something you already know.

| Options API | is, in the Composition API |
|---|---|
| `data() { return { clicks: 0 } }` | `const clicks = ref(0)` |
| `computed: { percent() { return … } }` | `const percent = computed(() => …)` |
| `methods: { ask() { … } }` | `function ask() { … }` |
| `props: { … }` | `defineProps({ … })` |
| `emits: ['more']`, then `this.$emit('more', 15)` | `const emit = defineEmits(['more'])`, then `emit('more', 15)` |
| `watch: { … }` | `watch(…)`, section 06 of this lesson |

Read the card of the last section again with this table beside it and every line has a partner.

## Why `data` is a function

`data` returns a new object each time it is called, and Vue calls it once per component instance. If it
were a plain object, every card would share one `clicks`, because they would all hold the same object.
The rule is the same one lesson 10 stated for composables: **calling the function is what makes fresh
state.** A component written with `data: { clicks: 0 }` is refused by Vue 3: it warns that the data option
must be a function, and the component fails to mount. Vue 2 allowed it only on the root instance.

## Everything on `this`, and what that costs

Vue merges props, data, computed values and methods onto one object, the component instance, and
`this` inside any option is that instance. That makes the Options API quick to write, and it has three
costs you will meet in real code:

- **Names collide, and not always out loud.** A method and a computed both called `percent` are one
  name on `this`; Vue warns about that one in development, and the computed wins. Other collisions pass
  in silence: between mixins (section 07), and between what `setup()` returns and `data` (section 08).
- **Nothing says where a name came from.** `this.label` could be a prop, a data property, a computed
  value, or something a mixin added (section 07). In a large component, finding out means searching.
- **Unwrapping is automatic and everywhere.** `this.clicks` is the value, never a ref, so there is no
  `.value` to forget; and there is also no ref to pass to a function that should follow it, which lesson
  2's rules needed.

The computed `percent` and the method `ask` read `this.done` and `this.clicks` because there is no other
way to reach the component from inside an option. That is the subject of the next section, and the
most common bug in Options API code.
