---
title: ref, and its .value
version: 1
---

**`ref()` wraps a value in an object with one property, `value`, and Vue watches that property.** Any
value fits: a number, a string, an array, an object. Reading `minutes.value` is noticed by whatever is
rendering at the time, and writing it tells Vue to redraw whatever read it. That is the whole contract.

```html
<!-- src/demos/RefBasics.vue -->
<script setup>
import { ref } from 'vue'

const minutes = ref(25)
console.log(minutes.value)
console.log(typeof minutes, minutes.constructor.name)

const session = ref({ course: 'statistics', minutes: 25 })
function longer() {
  session.value.minutes += 5
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <p>{{ session.course }}: {{ session.minutes }} minutes</p>
  <button @click="longer">Five more</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=RefBasics' --do 'click button'
[vite] connecting...
[vite] connected.
25
object RefImpl
-- click button
== the text of #app
25 minutes

statistics: 30 minutes

Five more
```

Three things in that transcript:

- **`minutes.value` is `25`**, the number. `minutes` itself is an object, a `RefImpl`: the wrapper.
  Printing `minutes` without `.value` prints the wrapper, which is the first mistake everybody makes
  once.
- **The template wrote `{{ minutes }}`, with no `.value`**, and showed 25. A ref at the top level of
  `<script setup>` is unwrapped automatically in the template. In the script, you always write
  `.value`; in the template, you never do.
- **`session.value.minutes += 5` redrew the page.** A ref holding an object makes the object reactive
  too, all the way down, so changing a property inside it is noticed as well as replacing the whole
  object.

## Why a wrapper at all

JavaScript cannot notice that a plain variable was read. `let minutes = 25` is a value in a slot, and
nothing runs when somebody reads the slot. What JavaScript *can* do is run code when a property of an
object is read or written: a getter, or a Proxy. So Vue puts the value inside an object and watches
its `value` property. **The `.value` you type is the price of being noticed.**

The same constraint is why a ref is passed around as the ref, not as its value. A function given
`minutes` can read the current value whenever it wants; a function given `minutes.value` was handed the
number 25 and will hold 25 forever.

## Unwrapping, precisely

The template unwraps a ref when it is a **top-level** name of `<script setup>`. A ref nested inside a
plain object is not unwrapped inside an expression, and the difference shows up as soon as you do
arithmetic with it:

```html
<!-- src/demos/Unwrapping.vue -->
<script setup>
import { ref } from 'vue'

const total = ref(0)
const counts = { total: ref(0) }
</script>

<template>
  <p>{{ total + 1 }}</p>
  <p>{{ counts.total }}</p>
  <p>{{ counts.total + 1 }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Unwrapping'
[vite] connecting...
[vite] connected.
== the text of #app
1

0

[object Object]1
```

`{{ total + 1 }}` is 1, because `total` is top-level and was unwrapped before the `+`. `{{ counts.total }}`
is 0, because the last thing an interpolation does is unwrap what it is about to print. But
**`{{ counts.total + 1 }}` is `[object Object]1`**: the `+` met the wrapper, turned it into a string
and glued a 1 to it. Keep refs at the top level of the script, or inside a `reactive` object (next
section), where they are unwrapped whenever they are read.

## When the whole value is replaced

Data from a server arrives as a new array or object, and the usual move is to replace the ref's value
with it:

```javascript
const courses = ref([])
courses.value = loaded
```

Everything that read `courses.value` is redrawn. If the data is large and you will only ever replace
it, never change it in place, **`shallowRef`** watches `.value` and nothing inside it, which skips the
work of making a thousand nested objects reactive. The planner is small and uses `ref` throughout.
