---
title: O dialog, feito pelo navegador
version: 1
---

**O elemento `<dialog>`, aberto com `showModal()`, é um modal que o navegador desenha na top layer: ele
fica acima de tudo, deixa o resto da página inerte, leva o foco para dentro, fecha com Escape e devolve
o foco para onde ele estava.** Cada uma dessas coisas é algo que um modal feito à mão com `<div>`s
posicionadas precisa acertar, e costuma acertar só em parte. A parte do Vue é pequena: uma template ref
para chamar o `showModal()`.

```html
<!-- src/demos/DialogDemo.vue -->
<script setup>
import { useTemplateRef } from 'vue'

const dialog = useTemplateRef('dialog')

function open() {
  dialog.value.showModal()
  console.log(`opened; focus is on #${document.activeElement.id}`)
}
function closed() {
  console.log(`closed with "${dialog.value.returnValue}"; focus is back on #${document.activeElement.id}`)
}
</script>

<template>
  <button id="open" @click="open">Add a session</button>
  <dialog ref="dialog" aria-labelledby="dialog-title" @close="closed">
    <h2 id="dialog-title">Add a session</h2>
    <form method="dialog">
      <label>Minutes <input id="minutes" type="number" value="30" /></label>
      <button id="cancel" value="cancel">Cancel</button>
      <button id="add" value="add">Add</button>
    </form>
  </dialog>
</template>
```

Abra e aperte Escape; abra de novo e aperte *Add*:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DialogDemo' --do 'click #open' --do 'press Escape' --do 'click #open' --do 'click #add' --text -
[vite] connecting...
[vite] connected.
-- click #open
opened; focus is on #minutes
-- press Escape
closed with ""; focus is back on #open
-- click #open
opened; focus is on #minutes
-- click #add
closed with "add"; focus is back on #open
```

**Toda vez que abriu, o foco foi para o primeiro campo de dentro, `#minutes`; toda vez que fechou, o
foco voltou para o botão que o abriu.** O Escape fechou com um `returnValue` vazio; o botão *Add*,
dentro de um `<form method="dialog">`, fechou com o próprio `value`, `"add"`. Nenhuma linha da demo
move o foco ou escuta o Escape.

## O que acrescentar

- **Um nome**: `aria-labelledby` apontando para o título do dialog, para que um leitor de tela anuncie
  *Add a session, dialog* quando ele abrir.
- **Um jeito de fechar que quem usa mouse consiga ver**: o Escape é invisível. Um botão de fechar, de
  preferência num `<form method="dialog">`, para não precisar de handler.
- **Um Teleport, às vezes.** A top layer já põe um dialog modal acima de qualquer `overflow` ou
  `z-index`, então o Teleport não é necessário para desenhá-lo. Ele ainda ajuda a manter o dialog fora
  do markup do componente que o abriu, e o dialog do planner usa um para isso, como a última seção
  desta aula mostra.

O `dialog.show()`, sem o *Modal*, abre como uma caixa comum na página, sem top layer e sem fundo
inerte. Um modal é o que as pessoas querem dizer quando falam em dialog.
