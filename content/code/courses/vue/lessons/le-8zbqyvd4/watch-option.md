---
title: The watch option
version: 1
---

**The `watch` option is an object whose keys name what to watch and whose values say what to do.** It
is lesson 4's `watch` with the source written as a string, and the last section's demo used the
simplest form: `minutes(now, before) {}` ran when `this.minutes` changed, and printed `30 -> 45`.

The forms you will read:

```javascript
watch: {
  // A data property or a prop, by name.
  minutes(now, before) {
    console.log(`${before} -> ${now}`)
  },

  // A nested property, by its path as a string.
  'session.minutes'(now) {
    this.save()
  },

  // With options: deep, immediate, flush, as in lesson 4.
  sessions: {
    handler(list) {
      localStorage.setItem('planner.sessions', JSON.stringify(list))
    },
    deep: true,
    immediate: true,
  },
},
```

Each line maps to the Composition API directly:

| `watch` option | `watch()` |
|---|---|
| `minutes(now, before) {}` | `watch(minutes, (now, before) => {})` |
| `'session.minutes'(now) {}` | `watch(() => session.value.minutes, (now) => {})` |
| `sessions: { handler, deep: true }` | `watch(sessions, handler, { deep: true })` |

## Two differences that matter when translating

**A watched array or object is shallow in the option form too**, unless `deep: true` is said, which is
lesson 4's push problem in a new spelling: `sessions(list) {}` does not run on `this.sessions.push(…)`.
Vue 3 made this stricter than Vue 2, which watched arrays for mutation by default, so a watcher on an
array that "stopped working" after an upgrade to Vue 3 is missing `deep: true`.

**There is no `watchEffect` in the options.** The closest thing is `this.$watch(() => …, handler)`,
called in `created`, which returns a stop function. A component that needs automatic tracking, or
watchers created conditionally, is a candidate for the `setup()` option at the end of this lesson.
