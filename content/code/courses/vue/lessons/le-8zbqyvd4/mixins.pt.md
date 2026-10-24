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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A demo Mixins. À esquerda, dois mixins na ordem da lista mixins: progressMixin, com label progress e o seu próprio describe, e courseMixin, com label course e o seu próprio describe. À direita, o que o this do componente acaba tendo: label é course e describe devolve course: course. A seta que sai do progressMixin é tracejada: tanto o label quanto o describe dele foram sobrescritos, em silêncio, porque o mixin que vem depois na lista vence.\"><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">mixins: [progressMixin, courseMixin]</text><rect x=\"30\" y=\"40\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"145\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">progressMixin</text><text x=\"145\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label: 'progress'</text><text x=\"145\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">describe() → progress: …</text><rect x=\"30\" y=\"135\" width=\"230\" height=\"76\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">courseMixin</text><text x=\"145\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">label: 'course'</text><text x=\"145\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe() → course: …</text><line x1=\"262\" y1=\"78\" x2=\"446\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"446.0,112.0 438.2,113.7 439.3,107.6\" fill=\"var(--wire)\"></polygon><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobrescrito</text><line x1=\"262\" y1=\"173\" x2=\"446\" y2=\"142\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"446.0,142.0 439.3,146.3 438.2,140.2\" fill=\"var(--phosphor)\"></polygon><text x=\"345\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">depois na lista: vence</text><rect x=\"450\" y=\"78\" width=\"250\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o this do componente</text><text x=\"575\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label = course</text><text x=\"575\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">describe() = course: course</text><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nada avisou</text></svg>", "caption": "Juntar mixins guarda um de cada nome, o que vem depois, e não diz nada sobre o outro."}
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
