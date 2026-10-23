---
title: Providing something that changes
version: 1
---

**`provide` hands over whatever it is given, once.** Give it a plain value and the injectors get that
value forever; give it a ref and they get the ref, and follow it as it changes. So a value that
changes is provided as a ref or a `computed`, never as `.value`, for the same reason lesson 2 gave for
passing a ref into a function.

That raises the question lesson 6 answered for props: if a child holds the parent's ref, can it write
to it? It can, unless the provider prevents it. This demo prevents it, and shows both what the child
may do and what it may not:

```html
<!-- src/demos/TotalBadge.vue -->
<script setup>
import { inject } from 'vue'
import { plannerKey } from './keys.js'

const { total, addFive } = inject(plannerKey)

function cheat() {
  total.value = 999
}
</script>

<template>
  <p id="badge">Total: {{ total }} minutes</p>
  <button id="add" @click="addFive">Add five</button>
  <button id="cheat" @click="cheat">Write to it directly</button>
</template>
```

```html
<!-- src/demos/ReactiveProvide.vue -->
<script setup>
import { ref, readonly, provide } from 'vue'
import TotalBadge from './TotalBadge.vue'
import { plannerKey } from './keys.js'

const total = ref(75)

provide(plannerKey, {
  total: readonly(total),
  addFive: () => {
    total.value += 5
  },
})
</script>

<template>
  <TotalBadge />
  <p id="owner">The provider has {{ total }}</p>
</template>
```

Add five, then try to write 999:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProvide' --do 'click #add' --do 'click #cheat'
[vite] connecting...
[vite] connected.
-- click #add
-- click #cheat
[warn] [Vue warn] Set operation on key "value" failed: target is readonly. RefImpl
== the text of #app
Total: 80 minutes

Add fiveWrite to it directly

The provider has 80
```

**`Add five` worked, and both the badge and the provider show 80.** The badge called the function the
provider handed it, and the provider changed its own ref. **Writing 999 was refused** with a warning,
because the badge was given `readonly(total)`: a read-only view of the same ref, which follows every
change and accepts none.

## The pattern

Provide **the state read-only, and the operations on it as functions.** It is the props-and-emits
contract of lesson 6, stretched across the layers in between: the injector reads what it is given, and
asks for changes through functions the owner wrote. The owner keeps a single place where its state
changes, which is what makes it possible to find out later why it changed.

| provide | the injector can |
|---|---|
| `'hours'`, a plain value | read it, once; it will never change |
| `total`, a ref | read it and follow it, *and write to it*, unnoticed by the owner |
| `readonly(total)` | read it and follow it; a write is refused |
| `readonly(total)` and `addFive` | read it, follow it, and ask the owner to change it |

`readonly` works on a ref, a `reactive` object or a `computed`; a `computed` with no setter is already
read-only, which is why the planner can provide its `titles` as they are, later in this lesson.
