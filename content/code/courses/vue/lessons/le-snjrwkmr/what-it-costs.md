---
title: What it costs, and the planner's one use of it
version: 1
---

**`provide` and `inject` remove the props in between, and with them the one thing props gave you: a
dependency you can see.** A component that injects something no longer says, in its props, everything
it needs. It works only somewhere below a provider, and nothing in its tag where it is used tells you
so. That is the escape hatch's price, and it is worth paying only for values that really are ambient.

## What you lose

- **Visibility.** `<SessionRow :session="s" />` looks complete, and is not: it also needs course
  titles, provided by something above it. A reader finds that out from the component's script, not from
  where it is used.
- **Portability.** Move the component to another part of the tree, outside the provider's subtree, and
  it gets the default, or `undefined`. The move compiles and runs.
- **Easy testing.** A test of a component that injects has to provide the value too. Lesson 21 does
  it for `SessionRow`, with the `global.provide` option of Vue Test Utils, and it is one more thing to
  know.

## When it is worth it

| the value is | pass it as |
|---|---|
| used by the component that has it and its children | props |
| used two or three levels down, by components that also need other props from the same parent | props; the drilling is short and honest |
| used at many depths, set in one place for a whole subtree | `provide` / `inject` |
| shared by the whole application and changed from many places | a store, lesson 13 |

The last row is where most "I need provide for this" ends up. A store is provide and inject with
rules: one module owns the state, everything that changes it is a named action, and the browser's Vue
tools can show every change. Lesson 13 moves the planner's sessions into one.

## The planner's titles

The course titles are a lookup that every session row needs, at whatever depth the rows end up, and
that only `App` can build, because only `App` loads the courses. That is the third row of the table, so
`App` provides them. First, the key:

```javascript
// src/keys.js: the keys the planner provides values under. A Symbol is unique,
// so no other code can provide or inject under the same key by accident.
export const titlesKey = Symbol('course titles')
```

`App.vue` gains two lines: `provide` in its imports, and the call itself, right after `titles` is
declared. It also stops passing `:title` to each row:

```javascript
provide(titlesKey, titles)
```

`titles` is a `computed` with no setter, so it is already read-only, and the rows follow it when the
courses arrive. `SessionRow` loses its `title` prop and injects the lookup instead:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { computed, inject } from 'vue'
import { formatDay } from '../planner.js'
import { titlesKey } from '../keys.js'

const { session } = defineProps({
  session: { type: Object, required: true },
})
const emit = defineEmits(['toggle'])

// The titles of every course, provided by App. Without a provider, the id is
// shown instead of the title, rather than nothing.
const titles = inject(titlesKey, null)
const title = computed(() => titles?.value[session.course] ?? session.course)
</script>

<template>
  <li :class="{ done: session.done }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
</style>
```

The default is `null`, and the title falls back to the course's id, `statistics`, when there is no
provider: the third answer of the last section's table. `titles?.value` reads the injected `computed`
through its `.value`, because an injected ref is not unwrapped in the script, only in the template.

With the planner's server running, the list reads exactly as before:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text 'main section:nth-child(2) ul'
[vite] connecting...
[vite] connected.
== the text of main section:nth-child(2) ul
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**The screen did not change, and that was the point**: the titles now arrive at the rows without
passing through the list that holds them. Whether that is better is the judgement of this section. For
a lookup every row needs and nothing else does, it is. For `session`, which is the row's whole reason
to exist, a prop remains the right answer, and it stayed one.
