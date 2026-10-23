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
