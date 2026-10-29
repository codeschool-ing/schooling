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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"How T is decided in the TypedPicker demo. On the left, the parent passes :items equal to courses, a Course array. In the middle, T becomes Course. On the right, the three places TypedList wrote T: items, a T array, is a Course array; the event pick, with an item of type T, hands the listener a Course, so course.goal is a number; and the slot&#x27;s item is a Course, so item.title is a string. Each is checked against Course.\"><text x=\"110\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the parent passes</text><rect x=\"20\" y=\"76\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:items=\"courses\"</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Course[]</text><line x1=\"202\" y1=\"106\" x2=\"256\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"256.0,106.0 248.6,109.1 248.6,102.9\" fill=\"var(--amber)\"></polygon><rect x=\"260\" y=\"82\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">T = Course</text><text x=\"585\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where TypedList wrote T</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">items: T[]</text><text x=\"585\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Course[]</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"53\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,53.0 462.3,60.1 458.3,55.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"470\" y=\"95\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pick: [item: T]</text><text x=\"585\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">course.goal: number</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,118.0 458.2,119.7 459.3,113.6\" fill=\"var(--phosphor)\"></polygon><rect x=\"470\" y=\"160\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;slot :item=\"item\"&gt;</text><text x=\"585\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">item.title: string</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"183\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,183.0 458.9,179.3 463.7,175.3\" fill=\"var(--phosphor)\"></polygon></svg>", "caption": "Nothing in the picker names a type; T is read off the items it was given."}
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
