---
title: TransitionGroup, para listas
version: 1
---

**O `<TransitionGroup>` faz para cada item de um `v-for` o que o `<Transition>` faz para um elemento: os
itens que entram e saem recebem as classes `-enter-` e `-leave-`, e os itens que só se movem, porque algo
foi inserido antes deles, recebem uma classe `-move`.** O movimento é a parte que faz uma mudança na
lista ser lida como uma mudança na lista, em vez de linhas pulando para lugares novos.

```html
<!-- src/demos/ListDemo.vue -->
<script setup>
import { ref } from 'vue'

const sessions = ref([
  { id: 's2', label: '19 October, Statistics' },
  { id: 's4', label: '21 October, Statistics' },
])
function addFirst() {
  sessions.value = [{ id: 's7', label: '18 October, Guitar' }, ...sessions.value]
}
</script>

<template>
  <button @click="addFirst">Add one at the top</button>
  <TransitionGroup tag="ul" name="slide" id="list">
    <li v-for="s in sessions" :key="s.id">{{ s.label }}</li>
  </TransitionGroup>
</template>

<style>
.slide-enter-active,
.slide-move {
  transition: all 1s ease;
}
.slide-enter-from {
  opacity: 0;
  transform: translateX(-1rem);
}
</style>
```

Adicione uma no topo e imprima a lista durante o segundo que a transição dura:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ListDemo' --do 'click button' --html '#list' --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of #list
<ul id="list"><li class="slide-enter-active slide-enter-to">18 October, Guitar</li><li class="slide-move" style="">19 October, Statistics</li><li class="slide-move" style="">21 October, Statistics</li></ul>
```

**A linha nova está entrando; as duas antigas têm `slide-move`**, porque cada uma foi empurrada um lugar
para baixo. O Vue mediu onde cada linha estava antes da mudança, deixou a lista ser redesenhada, mediu
de novo e então levou cada linha de volta à posição antiga com um `transform`, deixando a transição do
`-move` levá-la até a nova. Essa técnica tem nome, FLIP: first, last, invert, play.

## Três regras que vêm com ele

- **Todo item precisa de uma `:key` de verdade.** O movimento é calculado por chave, então a regra da
  aula 5 é o mecanismo inteiro aqui: com o índice como chave, toda linha pareceria mudar em vez de se
  mover.
- **O `tag` diz qual elemento desenhar em volta dos itens**, aqui um `<ul>`, para que a lista continue
  sendo uma lista para um leitor de tela. Sem `tag`, o `<TransitionGroup>` não desenha invólucro
  próprio.
- **O CSS do `-move` precisa de uma `transition`**, ou nada se move: as classes são aplicadas e nada é
  mandado animá-las.

A lista da semana do planner, no fim desta aula, usa isso para que uma sessão adicionada no dia 24
deslize até o lugar dela na ordem das datas.
