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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 255\" role=\"img\" aria-label=\"The OneWay demo. The parent, OneWay.vue, has minutes, 30, and session, which points at its own reactive object with course spanish and minutes 30. Both are passed down as props to Counter.vue, whose props are read-only. Its session prop points at the same object, not a copy. Writing props.minutes plus 5 is refused with a warning, and the parent keeps 30. Writing props.session.minutes plus 5 is allowed: it changes the parent&#x27;s object, and the minutes go from 30 to 35 in the child and in the parent.\"><rect x=\"20\" y=\"30\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">OneWay.vue</text><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the parent</text><text x=\"110\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">minutes: 30</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">session</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Counter.vue</text><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read-only props</text><text x=\"610\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">minutes: 30</text><text x=\"610\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">session</text><line x1=\"202\" y1=\"88\" x2=\"516\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"516.0,88.0 508.6,91.1 508.6,84.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passed down as props</text><rect x=\"240\" y=\"168\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ course: 'spanish',</text><text x=\"355\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  minutes: 30 → 35 }</text><text x=\"355\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the parent's reactive object, one copy</text><line x1=\"110\" y1=\"142\" x2=\"270\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,166.0 262.3,168.0 263.2,161.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"560\" y1=\"142\" x2=\"445\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,166.0 451.6,161.4 452.8,167.5\" fill=\"var(--phosphor)\"></polygon><text x=\"525\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">props.minutes += 5</text><text x=\"525\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused; the parent keeps 30</text><text x=\"525\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">props.session.minutes += 5</text><text x=\"525\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allowed: 35 in both</text></svg>", "caption": "The props object is read-only one level deep; the object a prop points at is still the parent's."}
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
