---
title: The generic component
version: 1
---

**A generic component is one whose props, events and slots are typed by a type parameter, `T`, that the
parent's use decides.** A list that accepts any kind of item and hands it back in a slot and an event,
typed as what was passed in, is the case it exists for: without a generic, the list would have to say
its items are "anything", and every parent would lose its types at the list's edge.

The sandbox gets TypeScript too, for the demos of this section, with the same three packages and a
configuration that checks only the files whose names start with `Typed`:

```
ana@dev:~/vue/sandbox$ npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1

added 11 packages, and audited 58 packages in 3s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

```json
{
  "extends": "@vue/tsconfig/tsconfig.dom.json",
  "include": ["env.d.ts", "src/demos/Typed*.vue"],
  "compilerOptions": {
    "lib": ["ES2023", "DOM", "DOM.Iterable"]
  }
}
```

and the same one-line `env.d.ts` as the planner's. The list:

```html
<!-- src/demos/TypedList.vue -->
<script setup lang="ts" generic="T extends { id: string }">
// T is whatever kind of item the parent passes; all this component needs is an id.
const { items } = defineProps<{ items: T[] }>()
const emit = defineEmits<{ pick: [item: T] }>()
</script>

<template>
  <ul>
    <li v-for="item in items" :key="item.id">
      <button @click="emit('pick', item)">
        <slot :item="item">{{ item.id }}</slot>
      </button>
    </li>
  </ul>
</template>
```

**`generic="T extends { id: string }"`** on the `<script setup>` tag declares the type parameter, with a
constraint: whatever `T` is, it has a string `id`, which the `:key` needs. `items: T[]`, the event
`pick: [item: T]` and the slot's `item` are all the same `T`. A parent that uses it with courses:

```html
<!-- src/demos/TypedPicker.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import TypedList from './TypedList.vue'

interface Course {
  id: string
  title: string
  goal: number
}

const courses: Course[] = [
  { id: 'statistics', title: 'Statistics', goal: 180 },
  { id: 'spanish', title: 'Spanish', goal: 120 },
]
const chosen = ref<Course | null>(null)
</script>

<template>
  <TypedList :items="courses" @pick="(course) => (chosen = course)">
    <template #default="{ item }">{{ item.title }}, {{ item.goal }} minutes</template>
  </TypedList>
  <p id="chosen">{{ chosen ? `${chosen.title}: goal ${chosen.goal}` : 'Nothing chosen' }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TypedPicker' --do 'click text=Spanish' --text '#chosen'
[vite] connecting...
[vite] connected.
-- click text=Spanish
== the text of #chosen
Spanish: goal 120
```

Nothing in the picker says what `item` and `course` are: **`T` became `Course` because `:items` was
given a `Course[]`**, so the slot's `item.title` and the event's `course.goal` are checked against
`Course`.

## Two uses the checker refuses

```html
<!-- src/demos/TypedMistakes.vue -->
<script setup lang="ts">
import TypedList from './TypedList.vue'

const sessions = [{ id: 's2', minutes: 45 }]
const labels = ['statistics', 'spanish']
</script>

<template>
  <TypedList :items="sessions">
    <template #default="{ item }">{{ item.title }}</template>
  </TypedList>
  <TypedList :items="labels" />
</template>
```

In the browser the page shows nothing useful and says nothing:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TypedMistakes'
[vite] connecting...
[vite] connected.
== the text of #app
```

The checker is specific:

```
ana@dev:~/vue/sandbox$ npx vue-tsc --noEmit
src/demos/TypedMistakes.vue(11,43): error TS2339: Property 'title' does not exist on type '{ id: string; minutes: number; }'.
src/demos/TypedMistakes.vue(13,15): error TS2322: Type 'string[]' is not assignable to type '{ id: string; }[]'.
  Type 'string' is not assignable to type '{ id: string; }'.
```

**`title` does not exist** on a session, because `T` became the session's shape; and **a list of
strings is refused** by the constraint, because a string has no `id`. Both would otherwise reach a
student as an empty button.
