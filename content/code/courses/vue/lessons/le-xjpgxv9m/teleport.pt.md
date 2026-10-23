---
title: Teleport, desenhado em outro lugar
version: 1
---

**O `<Teleport to="body">` renderiza o conteúdo em outro lugar do documento, enquanto esse conteúdo
continua parte do componente que o escreveu.** O componente mantém o estado, as props e os eventos; só
os elementos se mudam. Ele existe para uma família de problemas: algo que precisa ficar por cima da
página inteira, um dialog, um toast, um menu, escrito dentro de um componente cuja caixa o cortaria ou
o empilharia por baixo.

```html
<!-- src/demos/TeleportDemo.vue -->
<script setup>
import { ref } from 'vue'

const open = ref(false)
</script>

<template>
  <div class="card">
    <p>A card that clips whatever overflows it.</p>
    <button @click="open = true">Show the note</button>
    <p v-if="open" class="note" id="stays">A note drawn inside the card</p>
    <Teleport to="body">
      <p v-if="open" class="note" id="moves">A note teleported to the body</p>
    </Teleport>
  </div>
</template>

<style scoped>
.card {
  height: 4rem;
  overflow: hidden;
  border: 1px solid #c9d8cf;
}
</style>
```

Mostre as duas notas e imprima o body inteiro:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TeleportDemo' --do 'click button' --html body --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of body
<body>
    <div id="app" data-v-app=""><div data-v-9092e573="" class="card"><p data-v-9092e573="">A card that clips whatever overflows it.</p><button data-v-9092e573="">Show the note</button><p data-v-9092e573="" class="note" id="stays">A note drawn inside the card</p><!--teleport start--><!--teleport end--></div></div>
    <script type="module" src="/src/main.js"></script>
  

<p data-v-9092e573="" class="note" id="moves">A note teleported to the body</p></body>
```

**A primeira nota está dentro da `<div>` do card; a segunda é o último elemento do `<body>`**, fora do
`#app`. Onde o teleport foi escrito, o Vue deixou dois comentários, `<!--teleport start-->` e
`<!--teleport end-->`, para lembrar o lugar. A segunda nota ainda carrega o atributo de estilo scoped do
card, `data-v-9092e573`, porque ela ainda é markup do card.

## Por que isso importa

O card tem `overflow: hidden` e uma altura fixa, então a primeira nota, desenhada dentro dele, é cortada
na borda do card: uma regra de CSS comum, posta por um motivo comum, da qual um dialog que mora dentro
do card não consegue escapar. O mesmo acontece com `transform` e `filter` em qualquer
ancestral, e com `z-index` num ancestral posicionado, e cada um deles cria uma camada nova onde o dialog fica preso. **Um elemento teleportado
não tem nenhum dos ancestrais antigos**, então nenhuma das regras deles o alcança.

O `to` aceita qualquer seletor CSS, `#modals` para um contêiner seu, e `:disabled="true"` renderiza o
conteúdo no lugar, afinal, o que serve para mostrar o mesmo componente embutido numa tela grande e como
sobreposição numa tela pequena.

## O que ele não muda

O Teleport move elementos, não o componente. As props, os eventos emitidos e o provide e inject
funcionam exatamente como antes, porque pertencem à árvore de componentes. **Os eventos do DOM seguem o
DOM**, porém: um clique dentro da nota teleportada sobe até o `<body>`, não passa pela `<div>` do card,
e um listener no card não o escuta. E o
foco não se move: uma nota teleportada que aparece não leva o usuário de teclado até ela. Para algo que
precisa do foco, um dialog, o próprio elemento `<dialog>` do navegador cuida dessa parte, e ele é a
próxima seção.
