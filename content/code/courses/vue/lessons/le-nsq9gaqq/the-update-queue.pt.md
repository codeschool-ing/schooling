---
title: A fila de atualização, e o nextTick
version: 1
---

**Mudar um ref não redesenha a página na hora.** O Vue anota quais renders precisam rodar de novo,
põe esses renders numa fila e roda a fila quando o seu código termina, no que o JavaScript chama de
microtarefa. Então três mudanças seguidas causam um redesenho, não três, e a página que você lê na
mesma função ainda mostra o valor antigo.

```html
<!-- src/demos/UpdateQueue.vue -->
<script setup>
import { ref, nextTick } from 'vue'

const count = ref(0)

function shown() {
  console.log(`render with count = ${count.value}`)
  return count.value
}

async function addThree() {
  count.value++
  count.value++
  count.value++
  const onPage = document.querySelector('output').textContent
  console.log(`count is ${count.value}, the page still says ${onPage}`)
  await nextTick()
  console.log(`after nextTick the page says ${document.querySelector('output').textContent}`)
}
</script>

<template>
  <output>{{ shown() }}</output>
  <button @click="addThree">Add three</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=UpdateQueue' --do 'click button'
[vite] connecting...
[vite] connected.
render with count = 0
-- click button
count is 3, the page still says 0
render with count = 3
after nextTick the page says 3
== the text of #app
3Add three
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Um clique em Add three, em ordem de tempo da esquerda para a direita, em três linhas. Na primeira, o código do clique: count.value++ três vezes, depois o log dizendo que count é 3 e a página ainda diz 0, depois await nextTick. Na segunda, a fila do Vue: as três escritas puseram na fila um redesenho só, e ele roda uma vez, com count igual a 3, quando o código do clique parou no await. Então o código continua e a página diz 3. Na terceira, o elemento output: diz 0 até esse redesenho, e 3 depois dele.\"><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">addThree()</text><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">fila</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;output&gt;</text><rect x=\"110\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"127\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"127\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"167\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"167\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"190\" y=\"40\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"207\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">++</text><line x1=\"207\" y1=\"72\" x2=\"150\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"100\" y=\"108\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"160\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1 redesenho na fila</text><rect x=\"230\" y=\"40\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">log: a página ainda diz 0</text><rect x=\"400\" y=\"40\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">await nextTick()</text><line x1=\"502\" y1=\"62\" x2=\"525\" y2=\"106\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"525.0,106.0 518.8,100.9 524.3,98.0\" fill=\"var(--phosphor)\"></polygon><rect x=\"505\" y=\"108\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">render with count = 3</text><line x1=\"627\" y1=\"110\" x2=\"640\" y2=\"74\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"640.0,74.0 640.4,82.0 634.6,79.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"628\" y=\"40\" width=\"84\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"670\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a página diz 3</text><rect x=\"100\" y=\"176\" width=\"523\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"361\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><rect x=\"627\" y=\"176\" width=\"83\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><line x1=\"100\" y1=\"226\" x2=\"710\" y2=\"226\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"710.0,226.0 702.6,229.1 702.6,222.9\" fill=\"var(--wire)\"></polygon><text x=\"405\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um clique, em ordem de tempo</text></svg>", "caption": "Três escritas põem um redesenho na fila; o nextTick espera por ele."}
```

A ordem das linhas é a lição:

1. `render with count = 0` é o primeiro desenho.
2. Depois de três incrementos, **`count` é 3 e o `<output>` ainda diz 0**. O valor mudou; a página
   ainda não foi redesenhada.
3. **`render with count = 3` aparece uma vez**, não três. As três escritas enfileiraram um
   redesenho, e ele rodou com o valor final.
4. `await nextTick()` esperou por esse redesenho, e depois dele a página diz 3.

A aula 13 de `javascript`, sobre o event loop, descreveu as microtarefas: trabalho que roda depois da
tarefa atual e antes de o navegador fazer qualquer outra coisa. A fila do Vue é uma delas.
**`nextTick()` devolve uma promise que se resolve depois que a fila rodou**, então o código depois de
`await nextTick()` vê a página como a mudança a deixou.

## Quando você precisa dele

Raramente, e quase sempre para mexer no DOM diretamente depois de uma mudança: para pôr o foco num
campo que uma mudança acabou de fazer aparecer, para medir o novo tamanho de um elemento, para rolar
uma lista até um item que acabou de ser adicionado. A aula 9 faz o primeiro com um template ref.

Se você se pegar recorrendo ao `nextTick` para deixar um *valor* correto, o valor está sendo calculado
no lugar errado. Valores pertencem a um `computed`, que nunca fica desatualizado; o `nextTick` é só
sobre a página alcançar a mudança.
