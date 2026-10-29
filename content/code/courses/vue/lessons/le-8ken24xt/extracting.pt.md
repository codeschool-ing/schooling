---
title: Um composable, extraído
version: 1
---

**Um composable é uma função que usa a reatividade do Vue, refs, valores computed, watchers e hooks de
ciclo de vida, e devolve alguns deles para um componente usar.** É a unidade de reúso da Composition
API. O nome é uma convenção, não um recurso: não há nada para importar ou registrar, só uma função cujo
nome começa com `use`, chamada durante o setup de um componente.

A aula 7 deixou um componente renderless, `WeekPager`, que guardava uma semana e a emprestava ao seu
slot, e disse que a aula 10 o reescreveria como composable. Aqui está ele, o mesmo estado e os mesmos
dois movimentos, sem template e sem componente:

```javascript
// src/demos/useWeek.js: the week WeekPager held, as a composable.
import { ref, computed } from 'vue'

export function useWeek(start) {
  const monday = ref(start)

  function move(days) {
    const [y, m, d] = monday.value.split('-').map(Number)
    // Swedish writes a date as YYYY-MM-DD, which is the format the planner uses.
    monday.value = new Date(y, m - 1, d + days).toLocaleDateString('sv-SE')
  }

  return {
    monday,
    sunday: computed(() => {
      const [y, m, d] = monday.value.split('-').map(Number)
      return new Date(y, m - 1, d + 6).toLocaleDateString('sv-SE')
    }),
    previous: () => move(-7),
    next: () => move(7),
  }
}
```

Um componente que o usa duas vezes, para duas semanas independentes:

```html
<!-- src/demos/TwoWeeks.vue -->
<script setup>
import { useWeek } from './useWeek.js'

const plan = useWeek('2026-10-19')
const { monday, sunday, next } = useWeek('2026-10-19')
</script>

<template>
  <p id="plan">Plan: {{ plan.monday }} to {{ plan.sunday }}</p>
  <p id="review">Review: {{ monday }} to {{ sunday }}</p>
  <button @click="next">Next week, for the review only</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TwoWeeks' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
Plan: 2026-10-19 to 2026-10-25

Review: 2026-10-26 to 2026-11-01

Next week, for the review only
```

**A revisão foi para o dia 26 e o plano ficou no dia 19.** Cada chamada a `useWeek` rodou a função de
novo e criou um novo ref `monday`, então cada chamador tem uma semana só sua. Essa é a primeira coisa a
entender sobre um composable: **ele é uma função, e cada chamada cria estado novo.** Ele não é um store
compartilhado; a aula 13 é sobre a coisa que é.

## O que a extração rendeu

Comparado com o `WeekPager`, o composable:

- não acrescenta **nenhum componente à árvore**, nem um template que o chamador tenha de preencher num
  formato específico;
- pode ser chamado **mais de uma vez no mesmo componente**, o que um componente renderless só consegue
  sendo escrito duas vezes no template;
- devolve **o que quiser**, inclusive um `computed` para o domingo, e o chamador pega as peças de que
  precisa desestruturando, o que é seguro aqui porque cada peça é um ref ou uma função (a próxima seção
  diz por que isso importa);
- pode ser **testado como uma função**, sem montar nada, o que a aula 21 faz.

A primeira chamada da demo guarda o resultado num objeto, `plan`, e lê `plan.monday` no template; a
segunda o desestrutura. As duas funcionam. Um ref lido como propriedade de um objeto comum no template
é desembrulhado quando é a última coisa impressa, como a aula 2 mostrou, e `{{ plan.monday }}` é
exatamente isso.
