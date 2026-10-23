---
title: A computed you can write to
version: 1
---

**A computed is read-only unless you give it a setter, and then writing to it writes to the values it
is made from.** The setter is not a second copy of the state. It is a translation: the reader asks for
hours, the state is kept in minutes, and the setter turns an hour into minutes and stores those.

```html
<!-- src/demos/WritableHours.vue -->
<script setup>
import { ref, computed } from 'vue'

const minutes = ref(90)

const hours = computed({
  get: () => minutes.value / 60,
  set: (value) => {
    minutes.value = Math.round(value * 60)
  },
})

const readOnly = computed(() => minutes.value / 60)

function setTwoHours() {
  hours.value = 2
}
function tryReadOnly() {
  readOnly.value = 3
}
</script>

<template>
  <p>{{ minutes }} minutes = {{ hours }} hours</p>
  <button id="two" @click="setTwoHours">Make it two hours</button>
  <button id="three" @click="tryReadOnly">Make it three, the wrong way</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WritableHours' --do 'click #two' --do 'click #three'
[vite] connecting...
[vite] connected.
-- click #two
-- click #three
[warn] [Vue warn] Write operation failed: computed value is readonly
== the text of #app
120 minutes = 2 hours

Make it two hoursMake it three, the wrong way
```

`computed({ get, set })` takes the two functions as an object. **Setting `hours.value = 2` ran the
setter**, which stored 120 in `minutes`; the getter then worked out 2 from the 120, and the page shows
both. The second button tried to write to a computed with no setter, and **Vue refused with a warning
and changed nothing**. The warning appears only in development: a production build drops it, and the
write is ignored in silence, which is one more reason to read the console while you work.

## Where this earns its place

A writable computed is the tool for **one value shown in two shapes**:

- minutes stored, hours edited, as above;
- a list of tags stored as an array, edited in a text field as `"grammar, verbs"`;
- a date stored as `YYYY-MM-DD`, edited as three separate fields.

In each case one shape is the truth and the other is a view of it, and the setter is the only place
the view is turned back into the truth. Lesson 14 meets it again, joined to a form field with
`v-model`, where it is used most.

## And where it does not

A setter that writes to something *other* than what the getter read is a computed pretending to be
state. If `set` stores the value somewhere and `get` returns it from there, you have written a ref
with extra steps. **The test is that after any `set`, a `get` must return the value just written**, or
the nearest one the truth can hold. `hours.value = 1.5` stores 90 and reads back 1.5; `hours.value =
0.01` stores 1 minute and reads back 0.016666…, which is the nearest the minutes can hold and is
honest about it.
