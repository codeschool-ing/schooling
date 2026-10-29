---
title: Os hooks, da criação à remoção
version: 1
---

**Um componente tem uma vida: ele é criado, colocado na página, atualizado quantas vezes for preciso e
removido. O Vue chama uma função sua em cada um desses momentos, se você registrar uma, e essas funções
são os hooks de ciclo de vida.** Na Composition API cada hook é uma função que você importa e chama
durante o setup, `onMounted(() => …)`, e você já usou dois deles, na aula 5, só para imprimir.

Um componente que anuncia cada momento da sua vida:

```html
<!-- src/demos/Lifecycle.vue -->
<script setup>
import { ref, onBeforeMount, onMounted, onBeforeUpdate, onUpdated, onBeforeUnmount, onUnmounted } from 'vue'

const minutes = ref(30)
console.log('setup: the component is being created')
onBeforeMount(() => console.log('onBeforeMount: about to be put on the page'))
onMounted(() => console.log('onMounted: on the page'))
onBeforeUpdate(() => console.log(`onBeforeUpdate: the page still says ${document.querySelector('#minutes').textContent}`))
onUpdated(() => console.log(`onUpdated: the page now says ${document.querySelector('#minutes').textContent}`))
onBeforeUnmount(() => console.log('onBeforeUnmount: about to be removed'))
onUnmounted(() => console.log('onUnmounted: removed'))
</script>

<template>
  <p id="minutes">{{ minutes }}</p>
  <button id="more" @click="minutes += 15">15 more</button>
</template>
```

E um pai que consegue removê-lo:

```html
<!-- src/demos/Hooks.vue -->
<script setup>
import { ref } from 'vue'
import Lifecycle from './Lifecycle.vue'

const shown = ref(true)
</script>

<template>
  <Lifecycle v-if="shown" />
  <button id="remove" @click="shown = false">Remove it</button>
</template>
```

Some quinze minutos, depois remova o componente:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Hooks' --do 'click #more' --do 'click #remove' --text -
[vite] connecting...
[vite] connected.
setup: the component is being created
onBeforeMount: about to be put on the page
onMounted: on the page
-- click #more
onBeforeUpdate: the page still says 30
onUpdated: the page now says 45
-- click #remove
onBeforeUnmount: about to be removed
onUnmounted: removed
```

## Cada momento, e o que é verdade nele

| hook | quando | os elementos do componente |
|---|---|---|
| (o próprio setup) | o componente está sendo criado | não existem |
| `onBeforeMount` | está prestes a renderizar e ser inserido pela primeira vez | ainda não existem na página |
| `onMounted` | ele está na página | existem; dá para medir, focar, entregar a uma biblioteca |
| `onBeforeUpdate` | o estado mudou, e o redesenho está para acontecer | mostram os valores antigos |
| `onUpdated` | o redesenho aconteceu | mostram os valores novos |
| `onBeforeUnmount` | ele está prestes a ser removido | ainda estão lá, ainda funcionando |
| `onUnmounted` | ele foi removido | se foram; tudo o que você começou já precisa ter sido parado |

A transcrição diz o mesmo: o `onBeforeUpdate` leu **30** da página e o `onUpdated` leu **45**, do mesmo
elemento, com um redesenho entre os dois.

## Os três que você vai usar

A maioria dos componentes não usa hook nenhum, e a maioria dos que usam fica com estes três:

- **`onMounted`**, para trabalho que precisa dos elementos do componente na página: focar um campo
  (seção 04 desta aula), medir alguma coisa, iniciar uma biblioteca de gráficos ou de mapas que desenha
  dentro de um elemento.
- **`onUnmounted`**, para parar o que você começou: um timer, um listener em `window`, uma conexão. A
  seção 05 é sobre o que acontece quando você esquece.
- **`onBeforeUnmount`**, para a mesma coisa, quando a parada ainda precisa dos elementos: uma biblioteca
  que precisa ser avisada para soltar o elemento onde estava desenhando.

`onBeforeUpdate` e `onUpdated` raramente são a ferramenta certa. Código que deve rodar depois que um
valor muda é um watcher, aula 4, com `flush: 'post'` se precisar da página; um hook que roda depois de
*todo* redesenho, seja qual for o motivo, é um instrumento grosseiro que um watcher no valor certo torna
preciso.

Não existe `onCreated`. Na Composition API, o próprio setup *é* a criação: o código no nível de cima do
`<script setup>` roda exatamente onde o hook `created` do Vue 2 rodava. A aula 11 encontra o `created` na
Options API, onde ele ainda existe.
