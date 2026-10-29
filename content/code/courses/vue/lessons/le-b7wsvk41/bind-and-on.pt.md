---
title: v-bind e v-on, e os seus modificadores
version: 1
---

**O `v-bind` define um atributo ou propriedade a partir de uma expressão, e o `v-on` escuta um
evento.** São as duas diretivas que você mais vai digitar, então as duas têm um atalho: **`:`** para o
`v-bind` e **`@`** para o `v-on`. `:key="session.id"` é `v-bind:key`, e `@click="count++"` é
`v-on:click`.

```html
<!-- src/demos/BindAndOn.vue -->
<script setup>
import { ref } from 'vue'

const done = ref(false)
const minutes = ref(45)
const field = { id: 'minutes', name: 'minutes', min: 5, max: 240 }

function submitted() {
  console.log(`submitted ${minutes.value} minutes, and the page stayed`)
}
</script>

<template>
  <p :class="{ done, long: minutes >= 60 }" :style="{ opacity: done ? 0.6 : 1 }">Statistics</p>
  <form @submit.prevent="submitted">
    <input v-bind="field" type="number" v-model="minutes" @keyup.enter="console.log('Enter pressed')" />
    <button>Save</button>
  </form>
  <button id="done" @click="done = !done">Toggle done</button>
</template>
```

Alterne o feito, digite 60 no campo e aperte Enter, depois imprima o parágrafo:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=BindAndOn' --do 'click #done' --do 'fill #minutes 60' --do 'press Enter' --html p --text -
[vite] connecting...
[vite] connected.
-- click #done
-- fill #minutes 60
-- press Enter
submitted 60 minutes, and the page stayed
Enter pressed
== the HTML of p
<p class="done long" style="opacity: 0.6;">Statistics</p>
```

## Três coisas que o v-bind faz e o HTML não

- **`:class` aceita um objeto**, e cada chave cujo valor é verdadeiro vira uma classe. `{ done, long:
  minutes >= 60 }` deu `class="done long"`: `done` é atalho para `done: done`, como em qualquer objeto
  JavaScript. Ele também aceita um array, e se junta a um atributo `class` comum no mesmo elemento em
  vez de substituí-lo.
- **`:style` aceita um objeto** de propriedades CSS, escritas em camelCase ou em kebab-case entre
  aspas. As unidades são suas para escrever: `{ width: '40px' }`, não `{ width: 40 }`.
- **`v-bind` sem argumento aceita um objeto inteiro de atributos**, como o input mostra:
  `v-bind="field"` definiu `id`, `name`, `min` e `max` de uma vez. É como um componente repassa um
  grupo de atributos sem nomeá-los, e a aula 6 o encontra de novo.

Um valor ligado `null` ou `undefined` remove o atributo; `false` remove um atributo booleano como
`disabled`. Então `:disabled="saving"` é o idioma para um botão que espera.

## Modificadores no v-on

**`@submit.prevent` chamou `event.preventDefault()`** antes do handler, e a transcrição diz "the page
stayed": sem ele, enviar um formulário faz o navegador carregar o endereço do formulário, que, sem
endereço, é a mesma página, do zero, perdendo todos os refs. Todo formulário de uma aplicação Vue tem
`.prevent` no submit, ou chama o `preventDefault()` ele mesmo.

**`@keyup.enter`** só roda quando a tecla solta foi o Enter. Repare na ordem na transcrição: o
formulário foi enviado primeiro, com a tecla *descendo*, que é quando um navegador envia um formulário;
o handler de `keyup` rodou depois, quando ela voltou.

| modificador | o que ele acrescenta |
|---|---|
| `.prevent` | `event.preventDefault()` |
| `.stop` | `event.stopPropagation()`: o evento não sobe até os pais |
| `.self` | só se o evento aconteceu neste elemento, não num filho |
| `.once` | o listener é removido depois da primeira vez |
| `.enter`, `.esc`, `.space`, `.tab`, `.up`, `.down` | só para aquela tecla |
| `.ctrl`, `.shift`, `.alt`, `.meta` | só enquanto aquela tecla está pressionada |

Os modificadores se encadeiam, e em ordem: `@click.stop.prevent`. Eles existem para que um handler
possa tratar do que o componente faz, não dos comportamentos padrão do navegador.

## Um handler é um nome ou uma instrução

`@click="toggle"` passa a função, e o Vue a chama com o evento. `@click="toggle(session.id)"` é uma
instrução que o Vue embrulha numa função, então você pode passar o que quiser; o evento continua lá
como `$event`, se você precisar. `@click="done = !done"` também é uma instrução. Mantenha as
instruções numa linha curta; qualquer coisa mais longa pertence a uma função no script, onde ela tem
um nome.
