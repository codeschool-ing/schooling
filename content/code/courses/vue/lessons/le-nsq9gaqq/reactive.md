---
title: reactive, and the proxy it returns
version: 1
---

**`reactive()` takes an object and returns a Proxy of it: a stand-in that looks like the object and
reports every read and write to Vue.** There is no `.value`, because the object's own properties are
what is watched. It works only for objects, arrays, Maps and Sets; `reactive(25)` cannot watch
anything, and the demo below shows Vue saying so.

```html
<!-- src/demos/ReactiveProxy.vue -->
<script setup>
import { reactive, isReactive } from 'vue'

const raw = { course: 'spanish', minutes: 30, tags: ['grammar'] }
const session = reactive(raw)

console.log(session === raw)
console.log(isReactive(session), isReactive(raw))
console.log(isReactive(session.tags))
console.log(reactive(25))

function viaProxy() {
  session.minutes += 10
}
function viaRaw() {
  raw.minutes += 10
  console.log(`raw.minutes is now ${raw.minutes}`)
}
</script>

<template>
  <p>{{ session.course }}: {{ session.minutes }} minutes</p>
  <button id="proxy" @click="viaProxy">Through the proxy</button>
  <button id="raw" @click="viaRaw">Through the original</button>
</template>
```

Click the first button and then the second:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProxy' --do 'click #proxy' --do 'click #raw'
[vite] connecting...
[vite] connected.
false
true false
true
[warn] [Vue warn] value cannot be made reactive: 25
25
-- click #proxy
-- click #raw
raw.minutes is now 50
== the text of #app
spanish: 40 minutes

Through the proxyThrough the original
```

Read the lines before the clicks first:

- **`session === raw` is `false`.** The proxy is a different object. Vue keeps one proxy per original,
  so `reactive(raw)` called twice returns the same proxy, but never the original itself.
- **`isReactive(raw)` is `false`.** Making a proxy does not change the object it wraps.
- **`isReactive(session.tags)` is `true`.** Reading a nested object through the proxy returns a proxy
  of it, made on the spot. That is what "deep" means here: no matter how far down you change something,
  you went through a proxy to get there.

Last comes `reactive(25)`: a warning, and the number 25 handed back unchanged.

Then the clicks. The first went through the proxy, 30 became 40, and the page followed. The second
changed the original directly: `raw.minutes` is 50, and **the page still says 40**. Nothing told Vue.
Now the same two clicks and one more through the proxy:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProxy' --do 'click #proxy' --do 'click #raw' --do 'click #proxy'
[vite] connecting...
[vite] connected.
false
true false
true
[warn] [Vue warn] value cannot be made reactive: 25
25
-- click #proxy
-- click #raw
raw.minutes is now 50
-- click #proxy
== the text of #app
spanish: 60 minutes

Through the proxyThrough the original
```

The page jumped to 60, picking up the 10 it had missed. A change made behind Vue's back is not lost,
only unseen until something else causes a redraw. That is worse than lost, because it looks as if it
works.

**The rule: once an object is made reactive, keep only the proxy.** Throw the original away, or never
give it a name: `const session = reactive({ … })`.

## ref or reactive

Both make reactive state, and a `ref` holding an object uses `reactive` for the object. The
difference is in what you can do to the variable:

| | `ref` | `reactive` |
|---|---|---|
| holds | any value | objects only |
| read in the script | `x.value` | `x.prop` |
| replace the whole thing | `x.value = other` | not possible: the variable must keep pointing at the proxy |
| destructure it | the ref stays a ref | the pieces stop being reactive (next section) |

**The Vue documentation recommends `ref` as the default**, and so does this course. It is longer to
type and has fewer ways to break. `reactive` is pleasant for a group of fields that always travel
together, like a form, and lesson 14 uses it for one.
