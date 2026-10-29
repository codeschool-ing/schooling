---
title: Every kind of field, bound
version: 1
---

**`v-model` binds every kind of form field the browser has, and each kind hands back a value of its own
type: a date field a string, a select the chosen option's value, a number field a number.** Lesson 5
met `v-model` on a text field and two checkboxes. A form for a study session needs a course, a date and
a number of minutes, and this lesson builds one, so it starts with the fields themselves.

```html
<!-- src/demos/Fields.vue -->
<script setup>
import { ref } from 'vue'

const date = ref('2026-10-24')
const course = ref('spanish')
const minutes = ref(30)
const kind = ref('reading')
const note = ref('')
</script>

<template>
  <label>Date <input id="date" type="date" v-model="date" /></label>
  <label>
    Course
    <select id="course" v-model="course">
      <option value="statistics">Statistics</option>
      <option value="spanish">Spanish</option>
      <option value="guitar">Guitar</option>
    </select>
  </label>
  <label>Minutes <input id="minutes" type="number" v-model="minutes" /></label>
  <fieldset>
    <legend>Kind</legend>
    <label><input type="radio" value="reading" v-model="kind" /> Reading</label>
    <label><input id="practice" type="radio" value="practice" v-model="kind" /> Practice</label>
  </fieldset>
  <label>Note <textarea id="note" v-model="note"></textarea></label>
  <pre id="state">{{ { date, course, minutes, kind, note } }}</pre>
  <p id="types">{{ typeof date }}, {{ typeof course }}, {{ typeof minutes }}</p>
</template>
```

Change the date, the minutes, the kind and the note:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Fields' --do 'fill #date 2026-10-30' --do 'fill #minutes 45' --do 'check #practice' --do 'fill #note verbs' --text '#app'
[vite] connecting...
[vite] connected.
-- fill #date 2026-10-30
-- fill #minutes 45
-- check #practice
-- fill #note verbs
== the text of #app
Date  Course 
Statistics
Spanish
Guitar
Minutes 
Kind
 Reading Practice
Note 
{
  "date": "2026-10-30",
  "course": "spanish",
  "minutes": 45,
  "kind": "practice",
  "note": "verbs"
}

string, string, number
```

`{{ { date, course, minutes, kind, note } }}` prints an object as JSON, which is a quick way to see a
form's whole state while you build it.

## What each field gives

| field | `v-model` holds | to know |
|---|---|---|
| `<input type="date">` | `"2026-10-30"`, a string in `YYYY-MM-DD` | the format the planner already uses, so no conversion is needed; what the student *sees* is in their own locale's format |
| `<select>` | the `value` of the chosen `<option>` | an option with no `value` gives its text; bind `:value` to hand over a number or an object |
| `<input type="number">` | a number | Vue converts it on its own for this type, as lesson 5 said; an empty field gives `""` |
| radio buttons sharing a `v-model` | the `value` of the one chosen | wrap them in a `<fieldset>` with a `<legend>`, so a screen reader announces the question with each option |
| `<textarea>` | the text | write `v-model`: `{{ note }}` between the tags shows the ref, and what the student types never reaches it |

The `<select>` holds `"spanish"` though the student saw *Spanish*: the value is the id, the text is the
title, which is the planner's rule from lesson 5 for any list. And every field above sits inside its
`<label>`, so clicking the words reaches the field and a screen reader names it.

## The one that gives a string where you want a number

The number field is the exception that proves the rule: Vue reads the field's `type` and converts. A
field of any other type gives a string, even if it holds digits, which is the next section's subject.
