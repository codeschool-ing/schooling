---
title: Três jeitos de perdê-la
version: 1
---

**A reatividade mora no invólucro, então ela se perde no instante em que você tira dele um valor
comum.** O Vue não tem como avisar, porque tirar um valor de um objeto é JavaScript comum. Todos os
casos abaixo têm a mesma forma, e depois que você enxerga a forma os casos deixam de ser regras
separadas.

## Desestruturar um objeto reativo

```html
<!-- src/demos/LostReactivity.vue -->
<script setup>
import { reactive, toRefs } from 'vue'

const week = reactive({ planned: 195, done: 75 })

// A copy of the number, taken once.
const { done } = week
// A ref that stays connected to week.done.
const { done: doneRef } = toRefs(week)

function finishOne() {
  week.done += 20
}
</script>

<template>
  <p id="a">week.done: {{ week.done }}</p>
  <p id="b">destructured: {{ done }}</p>
  <p id="c">through toRefs: {{ doneRef }}</p>
  <button @click="finishOne">Finish a 20-minute session</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LostReactivity' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
== the text of #app
week.done: 95

destructured: 75

through toRefs: 95

Finish a 20-minute session
```

**A linha desestruturada ainda diz 75.** `const { done } = week` leu `week.done` uma vez, pelo proxy,
e pôs o número 75 numa variável nova. A variável é um número, e um número não tem como relatar que
mudou. A primeira linha e a terceira acompanharam a mudança para 95.

`toRefs(week)` é a correção quando você precisa dos pedaços: ele devolve um objeto em que cada
propriedade é um ref ligado à propriedade correspondente do proxy, então desestruturá-lo entrega refs.
`toRef(week, 'done')` cria um só.

## Trocar um objeto reativo

```javascript
let week = reactive({ planned: 0, done: 0 })
// later, when the data arrives
week = reactive(loaded)   // the template still holds the first proxy
```

O template foi compilado contra a variável como ela estava quando o componente foi montado, e ele
guarda o primeiro proxy. Apontar a variável para um segundo proxy não muda nada na tela. **Este é o
caso que a tabela da última seção chamou de "impossível"**, e o motivo de a recomendação ser `ref`:
`week.value = loaded` troca o conteúdo do mesmo ref, que o template de fato guarda.

`Object.assign(week, loaded)` também funciona com `reactive`, porque escreve no proxy existente,
propriedade por propriedade. Ele não remove as propriedades que faltam em `loaded`, o que é uma segunda
surpresa, mais silenciosa.

## Passar um valor para uma função

```javascript
function minutesLeft(planned, done) {
  return planned - done
}
const left = minutesLeft(week.planned, week.done)   // a number, computed once
```

`left` é um número tirado num momento. Quando `week.done` muda, nada chama a função de novo. Este não é
um erro numa função: é um valor que precisava ser recalculado sempre que as entradas dele mudam, que é
para o que serve o `computed`, e a aula 3 é sobre ele. Uma função chamada **dentro do template** roda
de novo, porque o template é rodado de novo; uma função chamada uma vez no script, não.

## A forma que os três têm em comum

| você escreveu | você recebeu | a correção |
|---|---|---|
| `const { done } = week` | um número | `toRefs(week)`, ou ler `week.done` onde você precisa dele |
| `week = reactive(other)` | um segundo proxy que ninguém observa | um `ref`, e `week.value = other` |
| `const left = f(week.done)` | um número calculado uma vez | `computed(() => f(week.done))`, aula 3 |

**Leia pelo invólucro no último momento**, dentro do template, de um `computed` ou de um watcher, e a
leitura é rastreada. Leia cedo, numa variável comum, e você fica com uma cópia.
