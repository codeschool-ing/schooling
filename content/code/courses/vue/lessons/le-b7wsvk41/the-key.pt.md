---
title: A chave que importa
version: 1
---

**O `:key` diz ao Vue a qual item cada elemento pertence, para que, quando a lista muda, ele possa
mover, manter ou remover os elementos certos.** Sem ele, ou com o errado, o Vue reaproveita elementos
pela posição, e qualquer coisa que um elemento guarde e que não veio da lista, um valor digitado, uma
caixa marcada, o estado próprio de um componente, fica na posição enquanto os itens passam por ela.

Aqui está uma linha com estado próprio, uma estrela que só a linha conhece:

```html
<!-- src/demos/StarRow.vue -->
<script setup>
import { ref } from 'vue'

defineProps(['course'])
const starred = ref(false)
</script>

<template>
  <li>
    {{ course }} {{ starred ? '*' : '' }}
    <button @click="starred = true">Star</button>
  </li>
</template>
```

E os mesmos três cursos desenhados duas vezes, uma com a chave pela posição e outra pelo próprio curso:

```html
<!-- src/demos/KeyMatters.vue -->
<script setup>
import { ref } from 'vue'
import StarRow from './StarRow.vue'

const courses = ref(['statistics', 'spanish', 'guitar'])
function removeFirst() {
  courses.value = courses.value.slice(1)
}
</script>

<template>
  <h2>key = index</h2>
  <ul id="by-index">
    <StarRow v-for="(course, i) in courses" :key="i" :course="course" />
  </ul>
  <h2>key = the course</h2>
  <ul id="by-id">
    <StarRow v-for="course in courses" :key="course" :course="course" />
  </ul>
  <button id="remove" @click="removeFirst">Remove the first course</button>
</template>
```

Marque com estrela o primeiro curso de cada lista, que é statistics, e depois remova statistics:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=KeyMatters' --do 'click #by-index button' --do 'click #by-id button' --do 'click #remove'
[vite] connecting...
[vite] connected.
-- click #by-index button
-- click #by-id button
-- click #remove
== the text of #app
key = index
spanish * Star
guitar Star
key = the course
spanish Star
guitar Star
Remove the first course
```

**Na lista com a chave pelo índice, a estrela foi para Spanish.** Spanish nunca recebeu estrela. O que
aconteceu: antes da remoção, a chave 0 era statistics com estrela; depois dela, a chave 0 é Spanish. O Vue
viu que a chave 0 ainda existe, manteve aquele componente com o seu estado, a estrela, e só mudou a prop
`course` dele. O componente que sumiu foi o da chave 2, que guardava guitar e não tinha nada a ver com statistics.

**Na lista com a chave pelo curso, a linha com estrela saiu junto com statistics.** A chave `statistics`
tinha sumido, então o componente dela foi removido, com estrela e tudo; as chaves `spanish` e `guitar`
foram mantidas como estavam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas listas de três linhas de curso, antes e depois de statistics ser removido. Com a chave pelo índice, as linhas tinham as chaves 0, 1 e 2; depois restam 0 e 1, então o componente de chave 0 é mantido com a estrela e passa a mostrar Spanish, e a chave 2 é removida. Com a chave pelo curso, as linhas tinham as chaves statistics, spanish e guitar; depois o componente de statistics sai com a estrela, e os outros dois são mantidos.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">chave = índice</text><text x=\"90\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><text x=\"270\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><rect x=\"20\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"152\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">statistics *</text><rect x=\"20\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"152\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"20\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"152\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"200\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"332\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish *</text><rect x=\"200\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"332\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"200\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"208\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"332\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">removido</text><line x1=\"162\" y1=\"70\" x2=\"198\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,70.0 190.6,73.1 190.6,66.9\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"110\" x2=\"198\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,110.0 190.6,113.1 190.6,106.9\" fill=\"var(--wire)\"></polygon><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">chave = o curso</text><text x=\"450\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><text x=\"630\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><rect x=\"380\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stat…</text><text x=\"512\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">statistics *</text><rect x=\"380\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">span…</text><text x=\"512\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"380\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"388\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">guit…</text><text x=\"512\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><rect x=\"560\" y=\"55\" width=\"140\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"568\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stat…</text><text x=\"692\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">removido *</text><rect x=\"560\" y=\"95\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">span…</text><text x=\"692\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spanish</text><rect x=\"560\" y=\"135\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">guit…</text><text x=\"692\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">guitar</text><line x1=\"522\" y1=\"70\" x2=\"558\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,70.0 550.6,73.1 550.6,66.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"110\" x2=\"558\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,110.0 550.6,113.1 550.6,106.9\" fill=\"var(--wire)\"></polygon><line x1=\"522\" y1=\"150\" x2=\"558\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,150.0 550.6,153.1 550.6,146.9\" fill=\"var(--wire)\"></polygon><text x=\"200\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a estrela fica na posição 0</text><text x=\"560\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a estrela sai com o seu curso</text></svg>", "caption": "O Vue mantém os componentes cujas chaves ainda existem. Com um índice, a chave que sobrevive é uma posição, e o estado vai junto com a posição."}
```

## O que faz uma boa chave

- **Estável**: o mesmo item tem a mesma chave enquanto existir. Um índice deixa de ser estável assim que
  algo é inserido, removido ou ordenado.
- **Única entre as irmãs.** Duas chaves iguais numa lista e o Vue avisa, e a atualização dá errado de
  maneiras que dependem da ordem dos eventos.
- **Uma string ou um número.** Não um objeto: dois objetos diferentes nunca são iguais, mesmo com o mesmo conteúdo, então uma chave montada como objeto muda a cada renderização.

Os dados do planner foram escritos para isso: toda sessão tem um `id` que nunca muda, de `s1` a `s6`,
e o `addSession` da aula 3 dá a uma nova o próximo número. **A regra deste código é a regra do catálogo
inteiro em que você está estudando, aplicada a uma lista**: junte por um id estável, nunca pela
posição.

Um índice só é aceitável como chave quando a lista nunca muda de ordem e as linhas não guardam estado
próprio, como uma lista fixa de rótulos. Mesmo assim, escrever `:key="item.id"` não custa nada e
sobrevive ao dia em que alguém acrescenta uma ordenação.
