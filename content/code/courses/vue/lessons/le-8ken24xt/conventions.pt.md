---
title: As convenções
version: 1
---

**Composables são só uma convenção, então são as convenções que tornam um deles previsível de usar.**
Três delas fazem a maior parte do trabalho: o nome começa com `use`; as entradas podem ser refs,
getters ou valores comuns; o resultado é um objeto comum de refs.

## Entradas: aceite um ref, um getter ou um valor

Um composable que calcula algo a partir da entrada deve acompanhar a entrada quando ela muda. Se
receber um ref, deve ler o ref dentro de um `computed` ou de um watcher; se receber um getter, chamá-lo
ali; se receber um valor comum, usá-lo. `toValue()` faz as três coisas, então o composable não precisa
se importar com o que recebeu:

```javascript
// src/demos/useHours.js: minutes as hours, from a ref, a getter or a plain number.
import { computed, toValue } from 'vue'

export function useHours(minutes) {
  return computed(() => (toValue(minutes) / 60).toFixed(2))
}
```

```html
<!-- src/demos/Conventions.vue -->
<script setup>
import { ref } from 'vue'
import { useHours } from './useHours.js'

const minutes = ref(90)
const fromRef = useHours(minutes)
const fromGetter = useHours(() => minutes.value * 2)
const fromNumber = useHours(minutes.value)
</script>

<template>
  <p>From the ref: {{ fromRef }}</p>
  <p>From a getter: {{ fromGetter }}</p>
  <p>From a number: {{ fromNumber }}</p>
  <button @click="minutes += 30">30 more</button>
</template>
```

A página abre com 90 minutos, e um clique soma 30:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Conventions' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
From the ref: 2.00

From a getter: 4.00

From a number: 1.50

30 more
```

**O ref e o getter acompanharam o clique; o número, não.** `useHours(minutes.value)` passou 90, um
número comum, e um número não muda, então as horas ficaram em 1.50. É a regra da aula 2 de novo, na
porta de um composable: passe o ref, ou um getter, e o composable consegue acompanhá-lo.

## Saída: um objeto comum de refs

Devolva `{ data, error, loading }`, cada um sendo um ref, em vez de `reactive({ data, error, loading })`.
Um objeto comum de refs pode ser desestruturado, `const { data } = useFetchJson(…)`, e cada peça
continua reativa, porque cada peça *é* um ref. Um objeto reativo perde a reatividade ao ser
desestruturado, como a aula 2 mostrou, o que obrigaria todo chamador a lembrar de não fazer isso.

## O resto, em poucas palavras

| convenção | por quê |
|---|---|
| o nome começa com `use` | quem lê sabe que ele precisa ser chamado durante o setup |
| chamado no nível de cima do setup, nunca num handler nem num callback que roda depois | os watchers e hooks dele ficam presos ao componente que está sendo montado (aula 4, e a seção sobre ciclo de vida desta aula) |
| um arquivo por composable, em `src/composables` | eles são encontrados, e importados, pelo nome |
| ele limpa tudo o que começa | o chamador não deveria precisar saber que existe um timer |

A biblioteca **VueUse** é uma coleção de uns duzentos composables escritos com essas convenções: o
tamanho da janela, o mouse, o local storage, a rede, o relógio. Antes de escrever um genérico, procure
lá; para um que conhece a sua aplicação, como os dados do planner, escreva o seu.
