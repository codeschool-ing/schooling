---
title: provide e inject
version: 1
---

**Um componente pode fazer `provide` de um valor sob uma chave, e qualquer componente abaixo dele, em
qualquer profundidade, pode fazer `inject` dele por essa chave.** Os componentes do meio nem recebem
nem repassam o valor. É a mesma árvore de antes, com a unidade enviada por cima do meio em vez de
através dele.

As chaves ficam num módulo próprio, por um motivo que a seção sobre chaves, mais adiante nesta aula, dá:

```javascript
// src/demos/keys.js: the keys this sandbox provides values under.
export const unitKey = Symbol('unit')
export const plannerKey = Symbol('planner')
```

```html
<!-- src/demos/InjectLeaf.vue -->
<script setup>
import { inject } from 'vue'
import { unitKey } from './keys.js'

defineProps({ minutes: Number })
const unit = inject(unitKey)
</script>

<template>
  <li>{{ unit === 'hours' ? minutes / 60 : minutes }} {{ unit }}</li>
</template>
```

```html
<!-- src/demos/InjectMiddle.vue -->
<script setup>
import InjectLeaf from './InjectLeaf.vue'

defineProps({ sessions: Array })
</script>

<template>
  <ul>
    <InjectLeaf v-for="s in sessions" :key="s.id" :minutes="s.minutes" />
  </ul>
</template>
```

```html
<!-- src/demos/ProvideInject.vue -->
<script setup>
import { provide } from 'vue'
import InjectMiddle from './InjectMiddle.vue'
import { unitKey } from './keys.js'

provide(unitKey, 'hours')

const sessions = [
  { id: 's2', minutes: 45 },
  { id: 's4', minutes: 60 },
]
</script>

<template>
  <InjectMiddle :sessions="sessions" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ProvideInject'
[vite] connecting...
[vite] connected.
== the text of #app
0.75 hours
1 hours
```

A mesma página da versão com drilling, e **o `InjectMiddle` não menciona mais unidade nenhuma.** O pai
chamou `provide(unitKey, 'hours')` durante o próprio setup, e cada folha chamou `inject(unitKey)`
durante o seu e recebeu `'hours'`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Duas árvores com os mesmos três níveis. À esquerda, prop drilling: o pai passa unit ao componente do meio como prop, e o do meio repassa a cada folha, embora nunca o use. À direita, provide e inject: o pai provê unit sob uma chave, o componente do meio não participa, e cada folha injeta o valor diretamente.\"><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">props, nível por nível</text><rect x=\"110\" y=\"30\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">pai</text><rect x=\"110\" y=\"105\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">meio</text><rect x=\"40\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">folha</text><rect x=\"210\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">folha</text><line x1=\"180\" y1=\"66\" x2=\"180\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"180\" y1=\"141\" x2=\"100\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"180\" y1=\"141\" x2=\"270\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"188\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><text x=\"90\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><text x=\"272\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:unit</text><rect x=\"470\" y=\"30\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">pai</text><rect x=\"470\" y=\"105\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">meio</text><rect x=\"400\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">folha</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">folha</text><line x1=\"540\" y1=\"66\" x2=\"540\" y2=\"103\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"141\" x2=\"460\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"141\" x2=\"630\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><path d=\"M468,50 C370,90 400,150 440,178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><path d=\"M612,50 C710,90 680,150 640,178\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">provide(unitKey, 'hours')</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">inject(unitKey)</text></svg>", "caption": "Com provide, o componente do meio deixa de carregar um valor que não usa. Ele também deixa de mostrar, em qualquer lugar, que os filhos precisam de um."}
```

## Como uma folha encontra o valor

Os valores providos por cada componente ficam por cima dos do pai dele, como uma pilha de folhas
transparentes. Um `inject` olha para o ancestral mais próximo que proveu aquela chave e pega o valor
dele; um componente mais acima que provê a mesma chave fica escondido pelo mais próximo. Isso faz do
provide um jeito de **sobrescrever para uma subárvore**: o planner inteiro poderia prover `'minutes'`, e
um painel dentro dele prover `'hours'` só para os próprios filhos.

Duas regras vêm junto, e as duas são sobre o momento:

- **`provide` e `inject` são chamados durante o setup**, no nível de cima do `<script setup>`, como o
  `watch` da aula 4. Chamados depois, num handler de clique ou num `.then()`, não há componente
  em setup a que prendê-los, e o Vue avisa.
- **Um valor só é encontrado por componentes *abaixo* de quem o provê.** Um irmão, ou o próprio pai de
  quem provê, não consegue injetá-lo. Dados de que a aplicação inteira precisa são providos pelo
  componente raiz, `App`, ou pela própria aplicação no `main.js` com `app.provide(key, value)`, que é como
  bibliotecas como o router da aula 12 ficam disponíveis em todo lugar.
