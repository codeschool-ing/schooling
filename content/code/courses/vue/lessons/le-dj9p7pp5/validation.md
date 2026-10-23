---
title: Validation, by hand
version: 1
---

**Validation is a `computed`: the form's values go in, a message per field comes out, and an empty message
means the field is fine.** No library is needed for a form of three fields, and writing it by hand once
shows what every validation library does for you: decide what is wrong, and decide *when* to say so.

The planner's form keeps its three fields in one `reactive` object, the case lesson 2 gave for
`reactive`: fields that always travel together. The rules, from `SessionForm.vue`, which the last section
of this lesson shows whole:

```javascript
const draft = reactive({ course: '', date: firstDate, minutes: 30 })
const tried = ref(false)

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
```

## What, and when

**`errors` answers "what is wrong", always**, and it is never stale, because it is computed. **`shown`
answers "what to say now"**, and says nothing until the student has pressed the button once. Showing
every error from the first moment, on a form the student has not touched, greets them with three red
messages for fields they have not reached yet. Showing them only on submit, and then live as they fix
each one, is the pattern the next two sections assume.

Each message is a sentence that says what to do, not what went wrong in the code's terms: *Choose a
course*, not *course is required*; *Between 5 and 240 whole minutes*, not *invalid value*. The rule is a
fact about the planner, set where the planner's rules are: a study session longer than four hours is
probably a typo.

## The browser's own checks, turned off

The form has `novalidate`. Without it, the browser would check `min="5"` and `max="240"` itself on
submit and show its own bubble, in its own words and its own language, before Vue's handler runs. The
attributes stay on the input, because they tell the browser's number field what the arrows can reach and
tell a screen reader the range; `novalidate` only stops the browser from blocking the submit, so that one
set of messages, the planner's, is shown, wired for a screen reader as the next section describes.

## The rule lives in the form, and in the store

`errors` stops a bad session at the form. It is not the only defence: anything that adds a session
without the form, a test, a future import, would skip it. The store's `add` accepts what it is given, and
a planner with a server would check again there, because a server never trusts a browser. For a planner
whose data lives in the student's own browser, the form's check is enough.
