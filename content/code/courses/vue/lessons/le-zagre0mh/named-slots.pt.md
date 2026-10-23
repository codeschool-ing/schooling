---
title: Slots nomeados
version: 1
---

**Um componente pode ter vários slots, cada um com um nome, e o pai preenche cada um com um
`<template>` que o nomeia.** O caso comum é uma moldura com mais de um lugar para conteúdo: um painel
com cabeçalho, corpo e rodapé, em que cada parte é do pai para escrever.

```html
<!-- src/demos/TitledPanel.vue -->
<template>
  <section class="panel">
    <header>
      <slot name="header">Untitled</slot>
    </header>
    <slot />
    <footer v-if="$slots.footer">
      <slot name="footer" />
    </footer>
  </section>
</template>
```

```html
<!-- src/demos/NamedSlots.vue -->
<script setup>
import TitledPanel from './TitledPanel.vue'
</script>

<template>
  <TitledPanel>
    <template #header><h2>This week</h2></template>
    <p>Five sessions planned.</p>
    <template #footer>75 of 195 minutes done</template>
  </TitledPanel>
  <TitledPanel>
    <p>A panel with no header and no footer.</p>
  </TitledPanel>
</template>
```

Desta vez a prova é o HTML, então o `look` o imprime:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=NamedSlots' --html '#app' --text -
[vite] connecting...
[vite] connected.
== the HTML of #app
<div id="app" data-v-app=""><section class="panel"><header><h2>This week</h2></header><p>Five sessions planned.</p><footer>75 of 195 minutes done</footer></section><section class="panel"><header>Untitled</header><p>A panel with no header and no footer.</p><!--v-if--></section></div>
```

**`<template #header>` preencheu o slot chamado `header`.** `#header` é atalho para `v-slot:header`,
como `@` é para `v-on`. O conteúdo fora de qualquer `<template #…>`, o parágrafo, foi para o slot sem
nome, que se chama `default`. O próprio elemento `<template>` não deixa nada na página.

**O segundo painel não tinha cabeçalho e desenhou o conteúdo reserva, `Untitled`. E não tinha rodapé,
então não tem elemento `<footer>` nenhum**, só o marcador `<!--v-if-->`. É para isso que serve o
`v-if="$slots.footer"`: `$slots` guarda uma função para cada slot que o pai de fato preencheu, então
o painel pode perguntar se há rodapé antes de desenhar uma caixa vazia com uma borda em volta de nada.

## Quando um slot conta como vazio

O conteúdo reserva é desenhado quando o conteúdo do pai para aquele slot está vazio, e **um conteúdo
que é só um `v-if` que deu falso conta como vazio**: ele não renderizou nada além de um comentário
marcador. O painel do planner no fim desta aula depende exatamente disso. É também onde o `$slots` pode
enganar: `$slots.footer` é verdadeiro sempre que o pai escreveu um `#footer`, mesmo um cujo único
conteúdo seja um `v-if` que deu falso, e o painel desenharia um rodapé vazio. Para esse caso, o conteúdo
reserva é uma ferramenta melhor que o `$slots`.

## Ordem e grafia

A ordem dos `<template>`s no pai não importa; o template do filho decide onde cada slot vai. O nome de
um slot é uma string comum, então `#footer` no pai precisa bater exatamente com `name="footer"` no
filho. Um nome de slot escrito errado não preenche nada e não avisa nada: o conteúdo simplesmente não
aparece, e essa é a única falha silenciosa dos slots. Se algo que você escreveu entre as tags de um
componente está faltando na página, compare os nomes primeiro.
