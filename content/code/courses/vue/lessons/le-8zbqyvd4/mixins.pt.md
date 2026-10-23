---
title: Mixins, e por que os composables os substituíram
version: 1
---

**Um mixin é um objeto de opções que o Vue junta a um componente**: o `data`, os `methods`, os
`computed`, os hooks e o resto dele são acrescentados aos do próprio componente. Era o jeito do Vue 2 de
compartilhar lógica entre componentes, ainda funciona no Vue 3, e a documentação do Vue não o recomenda
mais. Dois mixins e um componente mostram por quê.

```javascript
// src/demos/labelMixin.js: two mixins, written by two people, a year apart.
export const progressMixin = {
  data() {
    return { label: 'progress' }
  },
  methods: {
    describe() {
      return `progress: ${this.label}`
    },
  },
}

export const courseMixin = {
  data() {
    return { label: 'course' }
  },
  methods: {
    describe() {
      return `course: ${this.label}`
    },
  },
}
```

```html
<!-- src/demos/Mixins.vue -->
<script>
import { progressMixin, courseMixin } from './labelMixin.js'

export default {
  mixins: [progressMixin, courseMixin],
  mounted() {
    console.log(`label = ${this.label}; describe() = ${this.describe()}`)
  },
}
</script>

<template>
  <p>{{ describe() }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Mixins'
[vite] connecting...
[vite] connected.
label = course; describe() = course: course
== the text of #app
course: course
```

**Os dois mixins definem `label` e `describe`, e o segundo da lista venceu os dois**, em silêncio. O
`describe` do mixin de progresso sumiu; o `label` dele foi sobrescrito. Nada avisou, porque sobrescrever
é como a junção funciona: para `data` e `methods` o último vence, e as opções do próprio componente
vencem as de qualquer mixin. Os hooks são a exceção: todos são mantidos e rodam em ordem, os dos mixins
primeiro.

## Três problemas, todos sobre nomes

- **Colisões**, como acima. Dois mixins escritos com um ano de diferença por duas pessoas colidem numa
  palavra comum, e o componente perde um deles sem alarde.
- **Origem obscura.** Em `Mixins.vue`, nada diz de onde `label` vem. Um componente com quatro mixins
  tem quatro lugares para procurar cada nome do `this`, e os mixins também podem usar os nomes uns dos
  outros.
- **Sem parâmetros.** Um mixin é um objeto, não uma função, então não dá para dizer nada a ele. Duas
  cópias da mesma lógica com configurações diferentes precisam de dois mixins, ou de configurações lidas
  do `this` do componente por combinação.

**Um composable não tem nenhum dos três.** Ele devolve valores que quem chama nomeia: `const { label } =
useProgress()`, e um segundo pode ser renomeado na entrada, `const { label: courseLabel } =
useCourse()`. A origem de cada nome é a linha que chamou a função. E ele é uma função, então recebe
argumentos, como `useWeek('2026-10-19')` recebeu. É por isso que os mixins agora são legado: não porque
pararam de funcionar, mas porque os composables fazem o mesmo trabalho sem os três problemas.

Quando você encontrar mixins em código antigo, deixe em paz os que funcionam; quando precisar mudar um,
em geral é a hora de transformá-lo num composable e usá-lo a partir do `setup()` do componente, que é a
última seção.
