---
title: defineModel, uma prop em que se pode escrever
version: 1
---

**`defineModel()` declara uma prop e o seu evento de atualização juntos, e entrega ao filho um ref que lê
a prop e, quando escrito, emite o evento.** É o que faz o `v-model` funcionar num componente seu. Ele não
quebra o fluxo num sentido só: o filho continua nunca mudando o valor do pai; escrever no ref *pede* ao
pai que mude, e o `v-model` do pai faz isso.

```html
<!-- src/demos/MinutesField.vue -->
<script setup>
const minutes = defineModel({ type: Number, required: true })
</script>

<template>
  <label>
    Minutes
    <input type="number" :value="minutes" @input="minutes = Number($event.target.value)" />
  </label>
  <button @click="minutes += 15">+15</button>
</template>
```

```html
<!-- src/demos/ModelDemo.vue -->
<script setup>
import { ref } from 'vue'
import MinutesField from './MinutesField.vue'

const planned = ref(45)
</script>

<template>
  <MinutesField v-model="planned" />
  <p id="parent">The parent's ref: {{ planned }} ({{ typeof planned }})</p>
</template>
```

Aperte `+15` numa execução, e digite 100 no campo em outra:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelDemo' --do 'click text=+15' --text '#parent'
[vite] connecting...
[vite] connected.
-- click text=+15
== the text of #parent
The parent's ref: 60 (number)
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelDemo' --do 'fill input 100' --text '#parent'
[vite] connecting...
[vite] connected.
-- fill input 100
== the text of #parent
The parent's ref: 100 (number)
```

**O ref do pai virou 60 na primeira execução e 100 na segunda, e continuou um número.** O botão escreveu `minutes += 15` e o campo
escreveu `minutes = Number(…)`, os dois no ref do model, e as duas mudanças chegaram a `planned` no pai.
O `Number(…)` é trabalho do campo: um input entrega texto, como a aula 5 avisou, e este componente
promete um número.

## No que ele se expande

`defineModel` é uma abreviação. O filho acima equivale a:

```javascript
const props = defineProps({ modelValue: { type: Number, required: true } })
const emit = defineEmits(['update:modelValue'])
// read props.modelValue; to change it, emit('update:modelValue', newValue)
```

e `v-model="planned"` no pai é abreviação de `:model-value="planned"
@update:model-value="(value) => (planned = value)"`. Os nomes `modelValue` e `update:modelValue` são a
convenção com que os dois lados concordam. Você vai encontrar a forma longa em todo componente escrito
antes do Vue 3.4, quando o `defineModel` chegou, e na Options API da aula 11.

## Mais de um model

`defineModel('minutes')` dá nome ao model, e o pai escreve `v-model:minutes="planned"`. Um componente
pode ter vários: um intervalo de datas com `v-model:from` e `v-model:to`, um editor de sessão com
`v-model:course` e `v-model:minutes`. Cada um é uma prop e um evento, com o nome do model.

## Quando usar

Para um componente cujo trabalho é **editar um valor de que o pai é dono**: um input com label, um seletor
de data, uma avaliação em estrelas. A aula 14 monta o formulário do planner com eles. Para um componente
que só *relata* que algo aconteceu, uma linha sendo marcada, um evento comum é mais claro: o pai então
decide o que a marcação significa, como o `SessionRow` da próxima seção deixa o `App` decidir.
