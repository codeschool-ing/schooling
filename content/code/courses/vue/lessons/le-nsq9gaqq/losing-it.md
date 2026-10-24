---
title: Three ways to lose it
version: 1
---

**Reactivity lives in the wrapper, so it is lost the moment you take a plain value out of it.** Vue
cannot warn you, because taking a value out of an object is ordinary JavaScript. Every case below has
the same shape, and once you see the shape the cases stop being separate rules.

## Destructuring a reactive object

```html
<!-- src/demos/LostReactivity.vue -->
<script setup>
import { reactive, toRefs } from 'vue'

const week = reactive({ planned: 195, done: 75 })

// A copy of the number, taken once.
const { done } = week
// A ref that stays connected to week.done.
const { done: doneRef } = toRefs(week)

function finishOne() {
  week.done += 20
}
</script>

<template>
  <p id="a">week.done: {{ week.done }}</p>
  <p id="b">destructured: {{ done }}</p>
  <p id="c">through toRefs: {{ doneRef }}</p>
  <button @click="finishOne">Finish a 20-minute session</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LostReactivity' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
week.done: 95

destructured: 75

through toRefs: 95

Finish a 20-minute session
```

**The destructured line still says 75.** `const { done } = week` read `week.done` once, through the
proxy, and put the number 75 in a new variable. The variable is a number, and a number cannot report
that it changed. The first line and the third followed the change to 95.

`toRefs(week)` is the fix when you need the pieces: it returns an object whose every property is a
ref linked to the matching property of the proxy, so destructuring it hands out refs. `toRef(week,
'done')` makes one.

## Replacing a reactive object

```javascript
let week = reactive({ planned: 0, done: 0 })
// later, when the data arrives
week = reactive(loaded)   // the template still holds the first proxy
```

The template was compiled against the variable as it was when the component was set up, and it holds
the first proxy. Pointing the variable at a second proxy changes nothing on the screen. **This is the
case the table in the last section meant by "not possible"**, and the reason the recommendation is
`ref`: `week.value = loaded` replaces the contents of the same ref, which the template does hold.

`Object.assign(week, loaded)` also works with `reactive`, because it writes into the existing proxy
property by property. It does not remove properties that `loaded` lacks, which is a second, quieter
surprise.

## Passing a value into a function

```javascript
function minutesLeft(planned, done) {
  return planned - done
}
const left = minutesLeft(week.planned, week.done)   // a number, computed once
```

`left` is a number taken at one moment. When `week.done` changes, nothing calls the function again.
This one is not a mistake in a function: it is a value that needed to be recomputed whenever its
inputs change, which is what `computed` is for, and lesson 3 is about it. A function called **inside
the template** does run again, because the template is re-run; a function called once in the script
does not.

## The shape all three share

| you wrote | you got | the fix |
|---|---|---|
| `const { done } = week` | a number | `toRefs(week)`, or read `week.done` where you need it |
| `week = reactive(other)` | a second proxy nobody watches | a `ref`, and `week.value = other` |
| `const left = f(week.done)` | a number computed once | `computed(() => f(week.done))`, lesson 3 |

**Read through the wrapper at the last moment**, inside the template, a `computed` or a watcher, and
the reading is tracked. Read it early, into a plain variable, and you hold a copy.
