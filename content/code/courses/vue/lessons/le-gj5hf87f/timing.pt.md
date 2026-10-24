---
title: Quando o callback roda
version: 1
---

**O callback de um watcher não roda no momento em que o valor muda.** Como uma renderização, ele vai
para uma fila (aula 2), e a opção `flush` diz em que ponto da fila ele entra: antes de o componente se
redesenhar, depois, ou na hora, a cada escrita.

```html
<!-- src/demos/FlushTiming.vue -->
<script setup>
import { ref, watch } from 'vue'

const count = ref(0)
const page = () => document.querySelector('output').textContent

watch(count, (n) => console.log(`pre:  count ${n}, page says ${page()}`))
watch(count, (n) => console.log(`post: count ${n}, page says ${page()}`), { flush: 'post' })
watch(count, (n) => console.log(`sync: count ${n}, page says ${page()}`), { flush: 'sync' })

function addTwo() {
  count.value++
  count.value++
}
</script>

<template>
  <output>{{ count }}</output>
  <button @click="addTwo">Add two</button>
</template>
```

Um clique, dois incrementos:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FlushTiming' --do 'click button' --text -
[vite] connecting...
[vite] connected.
-- click button
sync: count 1, page says 0
sync: count 2, page says 0
pre:  count 2, page says 0
post: count 2, page says 2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um clique em Add two, em ordem de tempo da esquerda para a direita. O clique escreve em count duas vezes. O watcher sync roda a cada escrita, vendo count 1 e depois count 2, e a página dizendo 0 nas duas vezes. Quando o código do clique termina, a fila roda: o watcher pre, uma vez, com count 2 e a página ainda dizendo 0; depois o redesenho, e então o output diz 2; depois o watcher post, uma vez, com count 2 e a página dizendo 2.\"><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o clique</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">watchers</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;output&gt;</text><rect x=\"100\" y=\"45\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">count.value++</text><line x1=\"157\" y1=\"77\" x2=\"157\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"157.0,108.0 153.9,100.6 160.1,100.6\" fill=\"var(--wire)\"></polygon><rect x=\"222\" y=\"45\" width=\"114\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"279\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">count.value++</text><line x1=\"279\" y1=\"77\" x2=\"279\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"279.0,108.0 275.9,100.6 282.1,100.6\" fill=\"var(--wire)\"></polygon><rect x=\"100\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">sync</text><text x=\"157\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 1, page says 0</text><rect x=\"222\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"279\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">sync</text><text x=\"279\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 0</text><rect x=\"344\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"401\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pre</text><text x=\"401\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 0</text><rect x=\"466\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"523\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">redesenho</text><rect x=\"588\" y=\"110\" width=\"114\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">post</text><text x=\"645\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">count 2, page says 2</text><line x1=\"344\" y1=\"96\" x2=\"702\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"523\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">na fila: roda depois do código do clique</text><rect x=\"100\" y=\"182\" width=\"362\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"281\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><rect x=\"466\" y=\"182\" width=\"236\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"584\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><line x1=\"100\" y1=\"226\" x2=\"702\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"702.0,226.0 694.6,229.1 694.6,222.9\" fill=\"var(--wire)\"></polygon></svg>", "caption": "sync roda a cada escrita; pre e post rodam uma vez, um de cada lado do redesenho.", "same": ["watchers"]}
```

| `flush` | rodou | viu a página dizer | use para |
|---|---|---|---|
| `'sync'` | duas vezes, uma por escrita, no momento da escrita | 0 | quase nada; veja abaixo |
| `'pre'`, o padrão | uma vez, com o valor final, **antes** de redesenhar | 0 | trabalho que só precisa dos valores, que é a maior parte |
| `'post'` | uma vez, **depois** de redesenhar | 2 | trabalho que precisa da página como a mudança a deixou: medir, rolar, focar |

O `'pre'` é o padrão porque a maioria dos watchers não toca na página, e rodá-los antes de redesenhar
deixa que eles mudem estado que o mesmo redesenho vai mostrar, numa passada em vez de duas.

**O `'post'` é para ler o DOM.** Um watcher que rola uma lista até a sessão recém-acrescentada precisa
que o elemento dessa sessão exista, e ele só existe depois de redesenhar. O `watchPostEffect` é o
`watchEffect` com `flush: 'post'` já definido.

**O `'sync'` abre mão do agrupamento** para o qual a fila existe. Ele rodou duas vezes para duas
escritas, e um laço de cem escritas o rodaria cem vezes. Ele serve para o watcher raro que precisa ver
cada valor intermediário, como um registro de cada mudança; nunca é a correção para um watcher que
"roda tarde demais", o que é um problema de `'post'` ou um problema de `computed`.
