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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"A demo LostRefs. À esquerda, a store de sessões, um objeto reativo, com done indo de 45 para 105 quando s4 é alternada, planned em 105, e a action toggle. À direita, três jeitos de tirar pedaços dela. const done igual a store lê done uma vez e é uma cópia simples: fica em 45. storeToRefs de store dá um ref para done e planned, que acompanha a store: 105 de 105. const toggle igual a store pega a action direto da store: uma função, a mesma para sempre, e o botão dela funcionou.\"><rect x=\"20\" y=\"30\" width=\"200\" height=\"156\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useSessionsStore()</text><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">done: 45 → 105</text><text x=\"120\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planned: 105</text><text x=\"120\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">toggle()</text><rect x=\"280\" y=\"40\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">const { done } = store</text><line x1=\"222\" y1=\"57\" x2=\"276\" y2=\"57\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,57.0 268.6,60.1 268.6,53.9\" fill=\"var(--amber)\"></polygon><text x=\"512\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma cópia: fica em 45</text><rect x=\"280\" y=\"95\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">storeToRefs(store)</text><line x1=\"222\" y1=\"112\" x2=\"276\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,112.0 268.6,115.1 268.6,108.9\" fill=\"var(--phosphor)\"></polygon><text x=\"512\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">refs: 105 de 105</text><rect x=\"280\" y=\"150\" width=\"220\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">const { toggle } = store</text><line x1=\"222\" y1=\"167\" x2=\"276\" y2=\"167\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"276.0,167.0 268.6,170.1 268.6,163.9\" fill=\"var(--phosphor)\"></polygon><text x=\"512\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma função: a mesma para sempre</text></svg>", "caption": "Estado e getters passam pelo storeToRefs; as actions vêm direto da store."}
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
