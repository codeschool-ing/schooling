---
title: Refs de template, uma mão no elemento
version: 1
---

**Um ref de template dá ao seu script o elemento real do DOM, ou a instância do componente filho, em que
uma tag do template se transformou.** É a saída de emergência entre descrever a página e tocar nela,
para as poucas coisas que uma descrição não consegue dizer: ponha o foco aqui, meça isto, entregue este
elemento a uma biblioteca.

`useTemplateRef('name')`, do Vue 3.5, devolve um ref que o Vue preenche com o elemento cujo atributo
`ref` é `"name"`:

```html
<!-- src/demos/TemplateRefs.vue -->
<script setup>
import { ref, nextTick, useTemplateRef, onMounted } from 'vue'

const adding = ref(false)
const minutesField = useTemplateRef('minutes')
const rows = useTemplateRef('rows')

console.log(`during setup the field is ${minutesField.value}`)
onMounted(() => console.log(`mounted: ${rows.value.length} rows in the list`))

async function startAdding() {
  adding.value = true
  console.log(`before nextTick the field is ${minutesField.value}`)
  await nextTick()
  minutesField.value.focus()
  console.log(`after nextTick, focus is on #${document.activeElement.id}`)
}
</script>

<template>
  <ul>
    <li v-for="c in ['statistics', 'spanish', 'guitar']" :key="c" ref="rows">{{ c }}</li>
  </ul>
  <button @click="startAdding">Add a session</button>
  <label v-if="adding">Minutes <input id="new-minutes" ref="minutes" type="number" /></label>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TemplateRefs' --do 'click button' --text -
[vite] connecting...
[vite] connected.
during setup the field is null
mounted: 3 rows in the list
-- click button
before nextTick the field is null
after nextTick, focus is on #new-minutes
```

Quatro momentos, e os refs só estão cheios no segundo e no quarto:

- **Durante o setup, o campo é `null`.** Nada foi renderizado; o elemento não existe.
- **No `onMounted`, `rows` guarda 3 elementos.** Um `ref` dentro de um `v-for` junta todos os elementos
  do laço num array. A ordem do array não é garantida igual à da lista, então procure os itens por algo
  no elemento, e não pela posição.
- **Logo depois de `adding.value = true`, o campo ainda é `null`.** O `v-if` ainda não foi
  renderizado de novo: a fila da aula 2.
- **Depois de `await nextTick()`, ele existe**, e o `focus()` pôs o cursor nele, que é o que o aluno
  que apertou *Add a session* espera.

Esse último padrão, mostrar algo e depois focar, é o uso mais comum de um ref de template, e também é
uma regra de acessibilidade: um campo que aparece porque o aluno pediu deve receber o foco, senão quem
usa o teclado fica parado no botão sem saber para onde o campo foi.

## A grafia antiga

Antes do 3.5, um ref de template era um `ref` comum cujo nome de variável era igual ao atributo:

```javascript
const minutes = ref(null)   // filled by <input ref="minutes">
```

Isso ainda funciona, e a maior parte do código que você vai ler está escrita assim. O `useTemplateRef`
diz para que serve o ref e deixa a variável ter um nome diferente do atributo, o que a demo usa: a
variável é `minutesField`, o atributo `minutes`.

## Num componente

Um `ref` num componente filho dá a instância do componente, não um elemento. Com `<script setup>`, uma
instância não expõe nada ao pai a não ser que diga isso com `defineExpose({ focus })`. É de propósito: o
pai mexendo nas entranhas de um filho é o acoplamento que props e eventos existem para evitar, então o
filho decide os poucos métodos que oferece, como `focus()` num input personalizado.
