---
title: The planner's form, whole
version: 1
---

**The planner's week page gains a third panel, *Add a session*, with the form this lesson has built in
pieces.** It is two components: the field from the contract section, now in the planner's
`src/components`, and the form that uses it.

## FormField, with a slot for a select

The planner's version of the field adds one thing to the sandbox's: a scoped slot, lesson 7, so that a
field that is not an `<input>`, like the course `<select>`, can be wrapped with the same label and error.
The slot hands the content its `id`, whether it is invalid, and the id of its message:

```html
<!-- src/components/FormField.vue -->
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
    <slot :id="id" :invalid="Boolean(error)" :described-by="error ? `${id}-error` : undefined">
      <input
        :id="id"
        v-model="model"
        v-bind="$attrs"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="error ? `${id}-error` : undefined"
      />
    </slot>
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>

<style scoped>
.field {
  margin-bottom: 0.75rem;
}
label {
  display: block;
  font-weight: 600;
}
.error {
  color: #a3261b;
  margin: 0.25rem 0 0;
}
</style>
```

## SessionForm

```html
<!-- src/components/SessionForm.vue -->
<script setup>
import { reactive, ref, computed, useTemplateRef } from 'vue'
import FormField from './FormField.vue'
import { usePlannerStore } from '../stores/planner.js'
import { formatDay } from '../planner.js'

const { date: firstDate } = defineProps({ date: { type: String, required: true } })
const planner = usePlannerStore()

// The fields travel together, so they are one reactive object (lesson 2).
const draft = reactive({ course: '', date: firstDate, minutes: 30 })
const tried = ref(false)
const saved = ref('')
const courseField = useTemplateRef('course')

const errors = computed(() => ({
  course: draft.course ? '' : 'Choose a course.',
  date: draft.date ? '' : 'Choose a date.',
  minutes:
    Number.isInteger(draft.minutes) && draft.minutes >= 5 && draft.minutes <= 240
      ? ''
      : 'Between 5 and 240 whole minutes.',
}))
const valid = computed(() => Object.values(errors.value).every((e) => e === ''))
// Errors are shown only once the student has tried to submit.
const shown = computed(() => (tried.value ? errors.value : {}))

function submit() {
  tried.value = true
  if (!valid.value) {
    saved.value = ''
    return
  }
  planner.add({ ...draft })
  saved.value = `Added ${draft.minutes} minutes of ${planner.titles[draft.course]} on ${formatDay(draft.date)}.`
  Object.assign(draft, { course: '', minutes: 30 })
  tried.value = false
  courseField.value.focus()
}
</script>

<template>
  <form novalidate @submit.prevent="submit">
    <FormField label="Course" :error="shown.course">
      <template #default="{ id, invalid, describedBy }">
        <select
          :id="id"
          ref="course"
          v-model="draft.course"
          :aria-invalid="invalid ? 'true' : undefined"
          :aria-describedby="describedBy"
        >
          <option value="" disabled>Choose…</option>
          <option v-for="c in planner.courses" :key="c.id" :value="c.id">{{ c.title }}</option>
        </select>
      </template>
    </FormField>
    <FormField v-model="draft.date" label="Date" type="date" :error="shown.date" />
    <FormField v-model.number="draft.minutes" label="Minutes" type="number" min="5" max="240" :error="shown.minutes" />
    <button>Add the session</button>
    <p role="status" class="saved">{{ saved }}</p>
  </form>
</template>
```

The course field fills the slot with a `<select>` and wires it with the three values the slot passes;
the date and minutes fields use the default `<input>`. The form takes the date the student starts from
as a prop, `date`, which is copied into the draft once: lesson 6's "a starting value the child then
owns".

## On the page

`HomeView.vue` imports it, `import SessionForm from '../components/SessionForm.vue'`, and adds a panel
after the week's:

```html
<PlannerPanel title="Add a session">
  <SessionForm :date="today" />
</PlannerPanel>
```

Today is the starting date, because that is when a student most often plans the next session. Pressed
empty, the form says what is missing:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Add the session' --text form
[vite] connecting...
[vite] connected.
-- click text=Add the session
== the text of form
Course
Choose…
Statistics
Spanish
Guitar

Choose a course.

Date
Minutes
Add the session
```

**Only the course is missing**: the date started as today, and the minutes as 30, which is within the
rule. The text of the form shows every option of the select, because a `<select>`'s options are its text;
the screen shows the one chosen.

The planner can now add sessions as well as tick them, and lesson 4's watcher saves every new one in the
browser, with nobody having to remember it. Lesson 16 types this form, lesson 21 tests it.
