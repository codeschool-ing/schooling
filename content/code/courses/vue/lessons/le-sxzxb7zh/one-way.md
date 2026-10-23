---
title: One way down
version: 1
---

**Props flow one way: the parent owns the value, and the child only reads it.** If the child could
change a prop, the parent's state would change behind its back, and a value used by five children
would be changed by whichever wrote last. So Vue makes the props object read-only, and a child that
needs to change something asks the parent, with an event (next section).

```html
<!-- src/demos/Counter.vue -->
<script setup>
const props = defineProps({
  minutes: Number,
  session: Object,
})

function addToNumber() {
  props.minutes += 5
}
function addInsideObject() {
  props.session.minutes += 5
}
</script>

<template>
  <p>Child sees {{ minutes }} and {{ session.minutes }}</p>
  <button id="number" @click="addToNumber">Change the number prop</button>
  <button id="object" @click="addInsideObject">Change inside the object prop</button>
</template>
```

```html
<!-- src/demos/OneWay.vue -->
<script setup>
import { ref } from 'vue'
import Counter from './Counter.vue'

const minutes = ref(30)
const session = ref({ course: 'spanish', minutes: 30 })
</script>

<template>
  <Counter :minutes="minutes" :session="session" />
  <p id="parent">Parent has {{ minutes }} and {{ session.minutes }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OneWay' --do 'click #number' --do 'click #object'
[vite] connecting...
[vite] connected.
-- click #number
[warn] [Vue warn] Set operation on key "minutes" failed: target is readonly. Proxy(Object)
-- click #object
== the text of #app
Child sees 30 and 35

Change the number propChange inside the object prop

Parent has 30 and 35
```

**Assigning to the number prop was refused**, with a warning, and the parent still has 30. **Changing a
property inside the object prop was not refused**: the session's minutes went from 30 to 35, in the
child *and in the parent*. The props object is read-only one level deep, the property `session` itself;
the object it points at is the parent's own reactive object, and the child reached into it.

That second case is the dangerous one, because it works. Nothing warns, the screen is right, and the
parent's data was changed by a component that was only meant to display it. When it causes a bug, the
bug is found in the parent, which has no line that changes the minutes. **Treat an object prop as
read-only all the way down**, as if it had been frozen.

## When the child needs its own copy

Two legitimate needs look like changing a prop, and neither is:

- **A starting value the child then owns**, like the initial text of a field the student will edit.
  Copy it into a ref once: `const draft = ref(props.initial)`. From then on it is the child's, and a
  later change in the parent does not reach it, which is what "initial" means.
- **A value derived from a prop**, like a percentage. That is a `computed` of the prop, lesson 3, and
  it follows the parent forever.

If neither fits, the child is trying to change the parent's state, and the next section is how it
asks.
