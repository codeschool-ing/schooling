---
title: A field component, and the v-model contract
version: 1
---

**A form field component wraps one input with its label and its error, and joins the parent's
`v-model` with `defineModel()`.** Lesson 6 built the smallest one; this one is worth having, because it
puts the label and the error message beside the input in one place, wired for a screen reader, so that
no form in the planner can forget either.

```html
<!-- src/demos/FormField.vue -->
<script setup>
import { useId } from 'vue'

defineOptions({ inheritAttrs: false })
const model = defineModel()
const { label, error } = defineProps({ label: String, error: String })

// One id per field, unique on the page: the label and the error point at it.
const id = useId()
</script>

<template>
  <div class="field">
    <label :for="id">{{ label }}</label>
    <input
      :id="id"
      v-model="model"
      v-bind="$attrs"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="error ? `${id}-error` : undefined"
    />
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>
```

Three things in it are new:

- **`useId()`**, from Vue 3.5, gives each copy of the component an id that is unique on the page, so the
  `<label for>` reaches its own input, and the error its own field. Two fields of the same form can no
  longer share an id by being copies of one component.
- **`inheritAttrs: false` and `v-bind="$attrs"`** send the attributes the parent writes, `type`, `min`,
  `max`, onto the `<input>` instead of the wrapping `<div>`, which lesson 6's fallthrough would have
  chosen.
- **`aria-invalid` and `aria-describedby`** tie the error to the field. The section on errors a screen reader can hear, two sections on, is
  about why.

A demo with two fields, the second bound to lesson 3's writable computed, which promised to meet
`v-model` here:

```html
<!-- src/demos/FieldContract.vue -->
<script setup>
import { ref, computed } from 'vue'
import FormField from './FormField.vue'

const minutes = ref(300)
const error = computed(() => (minutes.value > 240 ? 'At most 240 minutes in one session.' : ''))

// Lesson 3's writable computed: the same value, edited in hours.
const hours = computed({
  get: () => minutes.value / 60,
  set: (value) => {
    minutes.value = Math.round(value * 60)
  },
})
</script>

<template>
  <FormField v-model.number="minutes" label="Minutes" type="number" min="5" max="240" :error="error" />
  <FormField v-model.number="hours" label="Hours" type="number" step="0.25" />
  <p id="value">minutes = {{ minutes }} ({{ typeof minutes }}), hours = {{ hours }}</p>
</template>
```

As it opens, with 300 minutes:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FieldContract' --html '.field' --text '#value'
[vite] connecting...
[vite] connected.
== the HTML of .field
<div class="field"><label for="v-0">Minutes</label><input id="v-0" type="number" min="5" max="240" aria-invalid="true" aria-describedby="v-0-error"><p id="v-0-error" class="error">At most 240 minutes in one session.</p></div>
== the text of #value
minutes = 300 (number), hours = 5
```

And with an hour and a half typed into the hours field:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FieldContract' --do 'fill input[step] 1.5' --text '#value'
[vite] connecting...
[vite] connected.
-- fill input[step] 1.5
== the text of #value
minutes = 90 (number), hours = 1.5
```

**The hours field wrote 1.5, the writable computed turned it into 90 minutes, and the minutes field and
its error followed.** `v-model.number` on a component passes the modifier to the component, and Vue
applies the conversion to the value the component emits. The `--html` shows the error wired to its
field by id: `aria-describedby="v-0-error"` on the input, `id="v-0-error"` on the message.

## The contract, once more

`v-model="x"` on a component is `:model-value="x"` and `@update:model-value="v => (x = v)"`, as lesson 6
showed; `defineModel()` is both halves on the child's side. A field component that keeps to it can be
used with any ref, a `reactive` object's property, a store's state or a writable computed, and the
parent never knows the difference.
