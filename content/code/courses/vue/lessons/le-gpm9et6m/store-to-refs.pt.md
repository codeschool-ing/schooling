---
title: storeToRefs, e a armadilha da desestruturação de novo
version: 1
---

**Uma store é um objeto reativo, então desestruturá-la entrega valores simples que nunca mudam.**
`const { done } = store` lê `store.done` uma vez. Para tirar pedaços de uma store e mantê-los reativos, o
`storeToRefs(store)` retorna uma ref para cada pedaço de estado e cada getter, e essas podem ser
desestruturadas com segurança.

```html
<!-- src/demos/LostRefs.vue -->
<script setup>
import { storeToRefs } from 'pinia'
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()
const { done } = store
const { done: doneRef, planned } = storeToRefs(store)
const { toggle } = store
</script>

<template>
  <p id="plain">Destructured: {{ done }}</p>
  <p id="refs">With storeToRefs: {{ doneRef }} of {{ planned }}</p>
  <button @click="toggle('s4')">Toggle s4</button>
</template>
```

Alterne a sessão que não está feita:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LostRefs' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
Destructured: 45

With storeToRefs: 105 of 105

Toggle s4
```

**O `done` desestruturado ficou em 45; o que veio do `storeToRefs` foi para 105.** É a primeira armadilha
da aula 2, num lugar novo, e o motivo de as views do planner escreverem as duas primeiras linhas do jeito
que escrevem:

```javascript
const planner = usePlannerStore()
const { sessions } = storeToRefs(planner)
const { toggle } = planner
```

## Por que as actions vêm direto da store

O `storeToRefs` pula as actions, porque uma action é uma função e uma função não precisa de ref: ela é a
mesma função para sempre, e chamá-la sempre trabalha sobre o estado atual. Então **estado e getters passam
pelo `storeToRefs`, e as actions são desestruturadas da própria store**, como o `toggle` acima. A demo faz o
mesmo com o `toggle`, e o botão dela funcionou.

## Ou não desestruture

`planner.sessions` no template, e `planner.toggle(id)` no script, não precisam de `storeToRefs` nenhum: ler
pela store é sempre reativo. O `App.vue` da última seção desta aula escreve `planner.error` e
`planner.courses.length` no template e não desestrutura nada. Desestruture quando uma view usa um pedaço
com frequência suficiente para que `planner.` em todo lugar vire ruído, e aí use `storeToRefs`.
