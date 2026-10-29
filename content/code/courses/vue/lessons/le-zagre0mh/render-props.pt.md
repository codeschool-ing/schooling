---
title: Um slot com escopo é uma render prop
version: 1
---

**Se você já leu código React, já viu o slot com escopo, com o nome de *render prop*: uma prop cujo
valor é uma função que devolve marcação.** Os dois resolvem o mesmo problema, deixar um componente ser
dono do comportamento enquanto o pai é dono da aparência, e a comparação mostra o formato de cada
framework.

A mesma ideia nos dois, um componente que guarda uma semana e deixa o pai desenhá-la. A versão React
aparece só para comparação e não faz parte do projeto deste curso:

```jsx
// React: the parent passes a function as children, and the child calls it.
<WeekPager>
  {({ monday, previous, next }) => (
    <>
      <p>Week of {monday}</p>
      <button onClick={previous}>Previous</button>
    </>
  )}
</WeekPager>
```

No Vue, o filho passa os valores para o `<slot>` e o template do pai os recebe. Este é esse filho, sem
marcação própria:

```html
<!-- src/demos/WeekPager.vue -->
<script setup>
import { ref } from 'vue'

// No markup of its own: it holds a week and hands it to whoever uses it.
const monday = ref('2026-10-19')
function move(days) {
  const [y, m, d] = monday.value.split('-').map(Number)
  const next = new Date(y, m - 1, d + days)
  // Swedish writes a date as YYYY-MM-DD, which is the format the planner uses.
  monday.value = next.toLocaleDateString('sv-SE')
}
</script>

<template>
  <slot :monday="monday" :previous="() => move(-7)" :next="() => move(7)" />
</template>
```

```html
<!-- src/demos/Renderless.vue -->
<script setup>
import WeekPager from './WeekPager.vue'
</script>

<template>
  <WeekPager v-slot="{ monday, previous, next }">
    <p>Week of {{ monday }}</p>
    <button id="back" @click="previous">Previous</button>
    <button id="on" @click="next">Next</button>
  </WeekPager>
</template>
```

Next duas vezes, depois Previous uma vez:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Renderless' --do 'click #on' --do 'click #on' --do 'click #back'
[vite] connecting...
[vite] connected.
-- click #on
-- click #on
-- click #back
== the text of #app
Week of 2026-10-26

PreviousNext
```

A partir do dia 19, duas semanas para a frente e uma para trás: **o dia 26**. O `WeekPager` não
renderiza nada além do seu slot. Ele guarda estado, `monday`, e duas funções que o mudam, e entrega as
três a quem o usa. Um componente assim se chama **renderless** (sem renderização).

## Onde os dois modelos diferem

| | render prop do React | slot com escopo do Vue |
|---|---|---|
| o que o pai passa | uma função, chamada pelo filho a cada renderização | um template, compilado uma vez, que recebe as props do slot |
| onde o conteúdo mora | em JSX, dentro da função do pai | no template do pai |
| como ele é chamado | pelo filho, como qualquer função | pelo Vue, onde o filho pôs o `<slot>` |

Por baixo, eles são mais próximos do que parecem: o Vue compila cada slot numa função, e o filho a
chama com as props do slot. A diferença está no que você escreve, um template em vez de uma função, e
no que o Vue consegue fazer com um template: ele sabe quais partes são estáticas, como a saída
compilada da aula 1 mostrou.

## E por que você vai escrever poucos componentes renderless

Eles eram o principal jeito de compartilhar comportamento no Vue 2, e o React se afastou das render
props pelo mesmo motivo que o Vue: **compartilhar estado e lógica não precisa de componente nenhum.**
Uma função que cria refs e os devolve, usada dentro do setup de qualquer componente, faz isso sem uma
camada a mais na árvore e sem template. No Vue essa função é um *composable*, e a aula 10 reescreve o
`WeekPager` como um. Slots com escopo continuam sendo a ferramenta certa quando a parte compartilhada
é de fato estrutura: a lista, a tabela, a moldura.
