---
title: Props, o que um componente recebe
version: 1
---

**Uma prop é um valor que um componente pai entrega a um componente filho por um atributo, e o filho
declara quais props aceita.** É assim que um componente é usado em muitos lugares com dados diferentes:
o planner vai desenhar um `CourseCard` por curso, cada um com o seu título e os seus minutos. A
declaração não é burocracia. É o filho dizendo do que precisa, e em desenvolvimento o Vue confere cada
uso contra ela.

```html
<!-- src/demos/GoalBar.vue -->
<script setup>
const props = defineProps({
  label: { type: String, required: true },
  minutes: { type: Number, required: true },
  goal: { type: Number, default: 60 },
  unit: {
    type: String,
    default: 'minutes',
    validator: (value) => ['minutes', 'hours'].includes(value),
  },
})
console.log(`${props.label}: minutes is a ${typeof props.minutes}`)
</script>

<template>
  <p>{{ label }}: {{ minutes }} of {{ goal }} {{ unit }}</p>
</template>
```

`defineProps` não é importado. É uma macro do compilador: o compilador de SFC a lê e a transforma nas
opções do componente, e por isso ela só funciona no nível de cima do `<script setup>`. Ela devolve um
objeto com as props, que o script lê como `props.label` e o template lê pelo nome, `{{ label }}`.

Quatro usos, três deles errados, cada um de um jeito:

```html
<!-- src/demos/PropsBasics.vue -->
<script setup>
import GoalBar from './GoalBar.vue'
</script>

<template>
  <GoalBar label="Statistics" :minutes="45" :goal="180" />
  <GoalBar label="Spanish" minutes="30" />
  <GoalBar label="Guitar" :minutes="20" unit="days" />
  <GoalBar :minutes="10" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=PropsBasics'
[vite] connecting...
[vite] connected.
Statistics: minutes is a number
[warn] [Vue warn]: Invalid prop: type check failed for prop "minutes". Expected Number with value 30, got String with value "30". 
  at <GoalBar label="Spanish" minutes="30" > 
  at <PropsBasics>
Spanish: minutes is a string
[warn] [Vue warn]: Invalid prop: custom validator check failed for prop "unit". 
  at <GoalBar label="Guitar" minutes=20 unit="days" > 
  at <PropsBasics>
Guitar: minutes is a number
[warn] [Vue warn]: Missing required prop: "label" 
  at <GoalBar minutes=10 > 
  at <PropsBasics>
undefined: minutes is a number
== the text of #app
Statistics: 45 of 180 minutes

Spanish: 30 of 60 minutes

Guitar: 20 of 60 days

: 10 of 60 minutes
```

- **`minutes="30"` sem dois-pontos passou a string `"30"`.** Um atributo comum é sempre texto; só
  `:minutes="30"`, que é `v-bind`, avalia a expressão e passa o número. O Vue avisou e depois usou a
  string assim mesmo: os avisos são conselhos para você, nunca uma recusa.
- **`unit="days"` não passou no validator** que a declaração escreveu, e foi usado assim mesmo.
- **A quarta barra não tem `label`**, uma prop obrigatória, e foi renderizada com um vazio.
- **`goal` caiu no seu default**, 60, onde quer que tenha ficado de fora.

A declaração tem três formas, da que diz menos para a que diz mais: um array de nomes,
`defineProps(['label', 'minutes'])`; um objeto de tipos, `{ label: String, minutes: Number }`; e o
objeto completo acima, com `required`, `default` e `validator`. A aula 16 acrescenta uma quarta, com
TypeScript, em que os tipos são conferidos antes de o código rodar em vez de enquanto ele roda. **Use a
forma completa para tudo que é compartilhado**: ela é a documentação do componente, e é conferida.

## Props são reativas, mesmo desestruturadas

O valor do pai pode mudar, e a prop do filho acompanha: uma prop é estado reativo que o filho lê e de
que não é dono. A aula 2 disse que desestruturar um objeto reativo perde a reatividade. **Props são a
única exceção**, desde o Vue 3.5:

```javascript
const { done, goal } = defineProps({ done: Number, goal: Number })
const percent = computed(() => Math.round((done / goal) * 100))
```

O compilador vê que `done` veio de `defineProps` e reescreve cada uso dele como `props.done`, então o
`computed` continua lendo pelo proxy e continua acompanhando o pai. Funciona porque o compilador faz
isso, e só para as variáveis desestruturadas direto de `defineProps`; passe `done` para uma função sua e
a função recebe um número comum, como na aula 2. O `CourseCard` do planner, no fim desta aula, é escrito
assim, e um default pode então ser escrito como o do próprio JavaScript:
`const { planned = 0 } = defineProps(…)`.
