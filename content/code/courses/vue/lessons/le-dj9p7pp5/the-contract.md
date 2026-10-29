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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"The FieldContract demo after 1.5 is typed into the hours field. The hours FormField emits update:modelValue with 1.5. The writable computed hours runs its setter, which writes minutes as 1.5 times 60, rounded: 90. The ref minutes is now 90. From it, the minutes field shows 90, and the computed error, which only has a message above 240 minutes, is empty, so the minutes field&#x27;s error goes. The hours getter, 90 divided by 60, gives back 1.5.\"><text x=\"95\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">FormField</text><rect x=\"20\" y=\"34\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the Minutes field</text><text x=\"95\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the Hours field</text><text x=\"95\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1.5 typed</text><rect x=\"290\" y=\"34\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">minutes</text><text x=\"375\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ref: 300 → 90</text><rect x=\"290\" y=\"140\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">hours</text><text x=\"375\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writable computed</text><rect x=\"540\" y=\"34\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">error</text><text x=\"620\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">empty: 90 is not above 240</text><line x1=\"172\" y1=\"168\" x2=\"286\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"286.0,168.0 278.6,171.1 278.6,164.9\" fill=\"var(--amber)\"></polygon><text x=\"230\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">update:modelValue</text><line x1=\"375\" y1=\"138\" x2=\"375\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"375.0,94.0 378.1,101.4 371.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"385\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">set: × 60, rounded</text><line x1=\"288\" y1=\"62\" x2=\"174\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"174.0,62.0 181.4,58.9 181.4,65.1\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">:model-value</text><line x1=\"462\" y1=\"62\" x2=\"536\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"536.0,62.0 528.6,65.1 528.6,58.9\" fill=\"var(--wire)\"></polygon><text x=\"375\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">get: 90 / 60 = 1.5, back in the Hours field</text></svg>", "caption": "One write goes up through the contract, and everything that reads minutes follows it."}
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
