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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Duas árvores da TeleportDemo. À esquerda, onde a marcação está escrita, o template do card: a div com classe card tem um parágrafo, o botão, a nota com id stays, e um Teleport para o body com a nota de id moves. À direita, onde é desenhado, o documento: o body tem a div com id app, que tem o card, que tem a nota stays e dois comentários, teleport start e teleport end, onde o Teleport foi escrito; depois do script, o último elemento do body é a nota moves, fora do app. Uma seta tracejada liga o Teleport, à esquerda, a essa nota, à direita.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde está escrito: o template</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde é desenhado: o documento</text><rect x=\"40\" y=\"36\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">div.card</text><rect x=\"64\" y=\"70\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p</text><rect x=\"64\" y=\"104\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button</text><rect x=\"64\" y=\"138\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">p#stays</text><rect x=\"64\" y=\"172\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"159\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;Teleport to=\"body\"&gt;</text><rect x=\"88\" y=\"206\" width=\"190\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p#moves</text><rect x=\"400\" y=\"34\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">body</text><rect x=\"422\" y=\"62\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">div#app</text><rect x=\"444\" y=\"90\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"529\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">div.card</text><rect x=\"466\" y=\"118\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"551\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">p#stays</text><rect x=\"466\" y=\"146\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"551\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--teleport start--&gt;</text><rect x=\"466\" y=\"174\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"551\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--teleport end--&gt;</text><rect x=\"422\" y=\"202\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">script</text><rect x=\"422\" y=\"230\" width=\"170\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">p#moves</text><path d=\"M 282 219 C 340 219, 360 241, 418 241\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"410\" y1=\"241\" x2=\"420\" y2=\"241\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,241.0 412.6,244.1 412.6,237.9\" fill=\"var(--amber)\"></polygon></svg>", "caption": "O conteúdo do Teleport continua no componente do card e é desenhado no fim do body."}
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
