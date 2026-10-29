---
title: defineModel, a prop you can write
version: 1
---

**`defineModel()` declares a prop and its update event together, and hands the child a ref that reads
the prop and, when written, emits the event.** It is what makes `v-model` work on your own component.
It does not break one-way flow: the child still never changes the parent's value; writing to the ref
*asks* the parent to, and the parent's `v-model` does it.

```html
<!-- src/demos/MinutesField.vue -->
<script setup>
const minutes = defineModel({ type: Number, required: true })
</script>

<template>
  <label>
    Minutes
    <input type="number" :value="minutes" @input="minutes = Number($event.target.value)" />
  </label>
  <button @click="minutes += 15">+15</button>
</template>
```

```html
<!-- src/demos/ModelDemo.vue -->
<script setup>
import { ref } from 'vue'
import MinutesField from './MinutesField.vue'

const planned = ref(45)
</script>

<template>
  <MinutesField v-model="planned" />
  <p id="parent">The parent's ref: {{ planned }} ({{ typeof planned }})</p>
</template>
```

Press `+15` in one run, and type 100 into the field in another:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelDemo' --do 'click text=+15' --text '#parent'
[vite] connecting...
[vite] connected.
-- click text=+15
== the text of #parent
The parent's ref: 60 (number)
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelDemo' --do 'fill input 100' --text '#parent'
[vite] connecting...
[vite] connected.
-- fill input 100
== the text of #parent
The parent's ref: 100 (number)
```

**The parent's ref became 60 in the first run and 100 in the second, and stayed a number.** The button
wrote `minutes += 15` and the field wrote `minutes = Number(…)`, both to the model ref, and both changes
reached `planned` in the parent. The `Number(…)` is the field's job: an input hands over text, as lesson
5 warned, and this component promises a number.

## What it expands into

`defineModel` is shorthand. The child above is equivalent to:

```javascript
const props = defineProps({ modelValue: { type: Number, required: true } })
const emit = defineEmits(['update:modelValue'])
// read props.modelValue; to change it, emit('update:modelValue', newValue)
```

and `v-model="planned"` on the parent is shorthand for `:model-value="planned"
@update:model-value="(value) => (planned = value)"`. The names `modelValue` and `update:modelValue` are
the convention both sides agree on. You will meet the long form in every component written before Vue
3.4, when `defineModel` arrived, and in the Options API of lesson 11.

## More than one model

`defineModel('minutes')` names the model, and the parent writes `v-model:minutes="planned"`. A component
can have several: a date range with `v-model:from` and `v-model:to`, a session editor with
`v-model:course` and `v-model:minutes`. Each is a prop and an event, named after the model.

## When to use it

For a component whose job is to **edit one value the parent owns**: an input with a label, a date
picker, a star rating. Lesson 14 builds the planner's form out of these. For a component that only
*reports* something happened, a row being ticked, a plain event is clearer: the parent then decides
what the tick means, as the next section's `SessionRow` lets `App` decide.
