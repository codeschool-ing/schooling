---
title: this, e a arrow que o perde
version: 1
---

**Dentro de uma opção, `this` é a instância do componente só quando a opção é uma função comum.** Uma
arrow function não tem `this` próprio; ela pega o `this` do lugar onde foi escrita, que num módulo é
`undefined`. Então um método escrito como arrow não alcança o componente, e o primeiro clique prova isso.

```html
<!-- src/demos/ThisTrap.vue -->
<script>
export default {
  data() {
    return { minutes: 30 }
  },
  methods: {
    longer() {
      this.minutes += 15
    },
    shorter: () => {
      this.minutes -= 15
    },
  },
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <button id="longer" @click="longer">Longer</button>
  <button id="shorter" @click="shorter">Shorter</button>
</template>
```

Aperte `Longer` e depois `Shorter`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ThisTrap' --do 'click #longer' --do 'click #shorter'
[vite] connecting...
[vite] connected.
-- click #longer
-- click #shorter
[warn] [Vue warn]: Unhandled error during execution of native event handler 
  at <ThisTrap>
Uncaught TypeError: Cannot read properties of undefined (reading 'minutes')
== the text of #app
45 minutes

LongerShorter
```

**`Longer` funcionou e `Shorter` lançou um erro**: `Cannot read properties of undefined (reading
'minutes')`. O Vue chama cada método com `this` apontando para o componente, e para `longer`, um método
comum, foi isso que `this` virou. Uma arrow function ignora como é chamada: o `this` dela foi fixado
quando o módulo foi avaliado, e no nível de cima de um módulo ES `this` é `undefined`. A aula 6 de
`javascript` explicou por que as arrows se comportam assim; aqui está o preço de esquecer isso dentro de
um objeto de opções.

## A regra, e sua única exceção

**Toda opção que usa `this` é escrita como método**: `data() {}`, `mounted() {}`, `percent() {}`,
`ask() {}`. Nunca `data: () => {}` e nunca `ask: () => {}`.

**Dentro** de um método, arrow functions são o que você quer, justamente porque mantêm o `this` do
método:

```javascript
methods: {
  later() {
    setTimeout(() => {
      this.minutes += 15 // the method's `this`: the component
    }, 1000)
  },
},
```

Uma `function () {}` comum no `setTimeout` teria o próprio `this`, definido pelo timer, que não é o
componente. Código antigo resolve isso com `const self = this` ou `.bind(this)`; com arrows, não é
preciso.

## Por que a Composition API não tem essa armadilha

`<script setup>` não tem `this` para perder. `clicks` é uma variável, capturada pelo closure de cada
função que a usa, arrow ou não. Esse é um dos motivos discretos de a Composition API ser mais fácil de
acertar, e um dos motivos de a própria documentação do Vue recomendá-la para aplicações novas.
