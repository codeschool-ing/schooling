---
title: Limpando depois de um watcher
version: 1
---

**Um watcher que começa algo lento precisa poder cancelá-lo quando a próxima mudança chega, ou a
resposta mais velha pode chegar depois da mais nova e vencer.** Esse é o bug real mais comum em
watchers, porque ele nunca aparece numa máquina rápida com uma rede rápida, e aparece num celular
dentro de um trem.

A demo tem um servidor de mentira em que statistics responde em 600 milissegundos e todo o resto em
100. Dois watchers pedem notas a ele sempre que o curso muda; um faz a limpeza e o outro não:

```html
<!-- src/demos/StaleAnswer.vue -->
<script setup>
import { ref, watch, onWatcherCleanup } from 'vue'

// A pretend server: statistics answers slowly, everything else quickly.
function lookUp(course) {
  const delay = course === 'statistics' ? 600 : 100
  return new Promise((resolve) => setTimeout(() => resolve(`notes for ${course}`), delay))
}

const course = ref('guitar')
const careless = ref('')
const careful = ref('')

watch(course, async (c) => {
  careless.value = await lookUp(c)
})

watch(course, async (c) => {
  let stale = false
  onWatcherCleanup(() => {
    stale = true
  })
  const answer = await lookUp(c)
  if (stale) {
    console.log(`dropped the answer for ${c}: a newer question was asked`)
    return
  }
  careful.value = answer
})
</script>

<template>
  <p id="careless">Without cleanup: {{ careless }}</p>
  <p id="careful">With cleanup: {{ careful }}</p>
  <button id="stats" @click="course = 'statistics'">Statistics</button>
  <button id="spanish" @click="course = 'spanish'">Spanish</button>
</template>
```

Escolha statistics, mude de ideia logo em seguida e escolha Spanish, e espere as duas respostas:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=StaleAnswer' --do 'click #stats' --do 'click #spanish' --do 'wait 800'
[vite] connecting...
[vite] connected.
-- click #stats
-- click #spanish
-- wait 800
dropped the answer for statistics: a newer question was asked
== the text of #app
Without cleanup: notes for statistics

With cleanup: notes for spanish

StatisticsSpanish
```

**O watcher descuidado mostra as notas de statistics, enquanto o curso escolhido é Spanish.** As duas
requisições estavam em andamento; Spanish respondeu depois de 100 milissegundos e foi mostrado;
statistics respondeu 500 milissegundos depois e o sobrescreveu. Nada falhou, e a tela está errada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de 0 a 700 milissegundos. Em 0 o curso vira statistics e a requisição dele começa; ela responde em 600. Quase no mesmo instante o curso vira Spanish e a requisição dele começa; ela responde cerca de 100 milissegundos depois. O watcher descuidado mostra Spanish nesse momento e depois statistics em 600, o que está errado. A limpeza do watcher cuidadoso marcou a execução de statistics como velha quando Spanish foi escolhido, então em 600 ele descarta a resposta e mantém Spanish.\"><line x1=\"150.0\" y1=\"220\" x2=\"710.0\" y2=\"220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,220.0 702.6,223.1 702.6,216.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"150.0\" y1=\"215\" x2=\"150.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><line x1=\"230.0\" y1=\"215\" x2=\"230.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><line x1=\"630.0\" y1=\"215\" x2=\"630.0\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"630.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 ms</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">statistics pedido</text><rect x=\"150.0\" y=\"30\" width=\"480.0\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">resposta lenta</text><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish pedido</text><rect x=\"154.0\" y=\"65\" width=\"80.0\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sem limpeza</text><rect x=\"234.0\" y=\"113\" width=\"396.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mostra Spanish</text><rect x=\"630.0\" y=\"113\" width=\"80.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">statistics</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">com limpeza</text><rect x=\"234.0\" y=\"158\" width=\"476.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mostra Spanish</text><line x1=\"630.0\" y1=\"52\" x2=\"630.0\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"626.0\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">velha: descartada</text></svg>", "caption": "As respostas chegam na ordem em que o servidor termina, não na ordem em que foram pedidas. Só a limpeza sabe qual pergunta ainda vale."}
```

## onWatcherCleanup

`onWatcherCleanup(fn)`, do Vue 3.5, registra uma função que o Vue chama **logo antes de o watcher rodar
de novo, e quando ele é parado**. Chamada dentro do callback, ela pertence àquela execução. Então,
quando Spanish foi escolhido, o Vue primeiro rodou a limpeza da execução de statistics, que ligou o
`stale` dela, e depois começou a execução de Spanish. Quando a resposta de statistics enfim chegou, a
execução dela viu `stale` e jogou a resposta fora, e o console diz isso.

Dois detalhes importam:

- **Registre a limpeza antes do primeiro `await`.** Como o rastreamento no `watchEffect`, a limpeza
  fica ligada à execução enquanto o callback roda de forma síncrona; registrada depois de um `await`, o
  Vue não consegue saber a que execução ela pertence, e avisa.
- **Antes do 3.5**, e em código que você vai ler, a mesma função chega como terceiro argumento do
  callback: `watch(course, async (c, old, onCleanup) => { onCleanup(() => { stale = true }) … })`.
  Ela faz a mesma coisa.

## Cancelando de verdade

Uma flag ignora a resposta atrasada; a requisição continua rodando até o fim. Com `fetch`, um
`AbortController` a interrompe:

```javascript
watch(course, async (c) => {
  const controller = new AbortController()
  onWatcherCleanup(() => controller.abort())
  const response = await fetch(`/notes/${c}.json`, { signal: controller.signal })
  notes.value = await response.json()
})
```

`controller.abort()` faz o `fetch` pendente rejeitar com um `AbortError`, então as linhas depois dele
nunca rodam para o curso velho. A aula 10 embrulha exatamente isso num composable, para que cada
componente que busca dados não o escreva de novo.
