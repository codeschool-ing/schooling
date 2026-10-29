---
title: trim, number and lazy
version: 1
---

**Three modifiers change what `v-model` writes: `.trim` removes spaces at the ends, `.number` converts to
a number, and `.lazy` writes when the field changes instead of on every keystroke.** Each one is a small
function between the field and the ref, and each one solves a bug that would otherwise be in every form.

```html
<!-- src/demos/Modifiers.vue -->
<script setup>
import { ref } from 'vue'

const plain = ref('')
const trimmed = ref('')
const number = ref('')
const lazy = ref('')
</script>

<template>
  <input id="plain" v-model="plain" />
  <input id="trimmed" v-model.trim="trimmed" />
  <input id="number" v-model.number="number" />
  <input id="lazy" v-model.lazy="lazy" />
  <p id="out">
    plain {{ JSON.stringify(plain) }} · trim {{ JSON.stringify(trimmed) }} · number
    {{ JSON.stringify(number) }} ({{ typeof number }}) · lazy {{ JSON.stringify(lazy) }}
  </p>
</template>
```

Type into the four fields, spaces included, without leaving the last one:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Modifiers' --do 'fill #plain  verbs ' --do 'fill #trimmed  verbs ' --do 'fill #number 45' --do 'fill #lazy verbs' --text '#out'
[vite] connecting...
[vite] connected.
-- fill #plain  verbs 
-- fill #trimmed  verbs 
-- fill #number 45
-- fill #lazy verbs
== the text of #out
plain " verbs " · trim "verbs" · number 45 (number) · lazy ""
```

Then type into the last one and press Tab to leave it:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Modifiers' --do 'fill #lazy verbs' --do 'press Tab' --text '#out'
[vite] connecting...
[vite] connected.
-- fill #lazy verbs
-- press Tab
== the text of #out
plain "" · trim "" · number "" (string) · lazy "verbs"
```

- **`.trim`** stored `"verbs"` where the plain field stored `" verbs "`. A title saved with a space in
  front of it sorts first and never matches a search; trim anything a person types as a name.
- **`.number`** stored the number `45` from an ordinary text field. It uses `parseFloat`, and a value
  that does not parse is left as the string, so `.number` is a convenience, not validation.
- **`.lazy`** stored nothing while the field still had focus, and `"verbs"` once Tab moved the focus
  away. The field fires `change` when it is left, not `input` on every key.

## When lazy is the right one

`.lazy` suits a field whose value is expensive to react to: one that triggers a search request, a
recalculation over a long list, or a check against a server. Updating on every keystroke would send a
request per letter. For a field whose value is shown or checked locally, the default is what the student
expects: the error disappears the moment the typing fixes it.
