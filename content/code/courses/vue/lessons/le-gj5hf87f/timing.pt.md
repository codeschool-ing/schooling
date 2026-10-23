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
