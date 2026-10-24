---
title: Slots com escopo
version: 1
---

**Um slot com escopo é um slot que devolve valores ao conteúdo que o preenche.** O filho escreve props
no seu elemento `<slot>`, e o conteúdo do pai as recebe. É assim que um componente dono da
*estrutura*, uma lista, uma tabela, um laço, deixa o pai decidir como cada *item* é desenhado, que é a
única coisa que a regra de escopo da seção sobre o slot padrão tornaria impossível.

```html
<!-- src/demos/SessionTable.vue -->
<script setup>
defineProps({ sessions: { type: Array, required: true } })
</script>

<template>
  <ol>
    <li v-for="(session, index) in sessions" :key="session.id">
      <slot name="row" :session="session" :position="index + 1">
        {{ session.id }}
      </slot>
    </li>
  </ol>
</template>
```

```html
<!-- src/demos/ScopedSlots.vue -->
<script setup>
import SessionTable from './SessionTable.vue'

const sessions = [
  { id: 's2', course: 'statistics', minutes: 45, done: true },
  { id: 's5', course: 'guitar', minutes: 20, done: false },
]
</script>

<template>
  <SessionTable :sessions="sessions" />
  <SessionTable :sessions="sessions">
    <template #row="{ session, position }">
      {{ position }}. {{ session.course }}, {{ session.minutes }} minutes {{ session.done ? '(done)' : '' }}
    </template>
  </SessionTable>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ScopedSlots'
[vite] connecting...
[vite] connected.
== the text of #app
s2
s5
1. statistics, 45 minutes (done)
2. guitar, 20 minutes
```

**A primeira tabela não recebeu nada e desenhou o conteúdo reserva em cada linha, o id.** A segunda
preencheu o slot `row` com um template que recebe `{ session, position }` e desenhou cada linha do
seu jeito. O `<ol>`, o laço e a key ficaram no `SessionTable`; só o interior de cada `<li>` veio do
pai.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas caixas. À esquerda, o filho SessionTable é dono do elemento da lista, do laço e de cada item; dentro de cada item há um slot. À direita, o template do pai para o slot row. Uma seta do slot para o pai leva as props do slot, session e position. Uma seta de volta leva a marcação que o template do pai produziu, desenhada dentro do item.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o filho: SessionTable</text><text x=\"40\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;ol&gt;</text><text x=\"55\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;li v-for=\"session in sessions\"&gt;</text><rect x=\"70\" y=\"108\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;slot name=\"row\"</text><text x=\"185\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:session :position&gt;</text><text x=\"55\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/li&gt;</text><text x=\"40\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/ol&gt;</text><rect x=\"420\" y=\"60\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o template do pai</text><text x=\"560\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">#row=\"{ session, position }\"</text><text x=\"560\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{{ position }}. {{ session.course }}</text><line x1=\"302\" y1=\"122\" x2=\"418\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,112.0 410.9,115.7 410.4,109.5\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">props do slot</text><line x1=\"418\" y1=\"160\" x2=\"302\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"302.0,156.0 309.5,153.1 309.3,159.4\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">marcação</text></svg>", "caption": "O filho fica com a estrutura e empresta o item; o pai desenha o item e o devolve."}
```

## Lendo a sintaxe

- No filho, **`<slot name="row" :session="session" :position="index + 1">`** liga duas props de slot,
  exatamente como props num componente. Elas podem ser quaisquer valores, inclusive funções.
- No pai, **`<template #row="{ session, position }">`** as recebe como um objeto só, as props do slot,
  que as chaves desestruturam. Sem desestruturar, fica `#row="props"` e depois `props.session`.
- Para o slot padrão de um componente que não tem outros slots, o template pode ser dispensado e o
  `v-slot` escrito no próprio componente: `<SessionTable v-slot="{ session }">`. A demo da próxima
  seção faz isso.

## O escopo continua sendo do pai

O conteúdo em `#row` enxerga duas coisas: as variáveis do próprio pai, como qualquer conteúdo de slot,
e as props de slot que o filho escolheu passar. Nada mais do filho. O filho decide exatamente o que
compartilha, que é a mesma disciplina dos emits de um componente: uma lista curta e com nomes.

O uso comum é um componente de lista que cuida das partes difíceis, ordenação, carregamento, um estado
vazio, paginação, navegação pelo teclado, e deixa cada página que o usa decidir como um item se parece.
Uma tabela de sessões numa tela e uma lista das mesmas sessões em outra podem compartilhar o componente
e diferir só nos seus templates `#row`.
