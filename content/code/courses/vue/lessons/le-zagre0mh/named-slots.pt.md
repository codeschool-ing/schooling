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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A demo NamedSlots. À esquerda, o que o pai escreve entre as tags do primeiro TitledPanel: um template chamado header com um h2, This week; um parágrafo fora de qualquer template; e um template chamado footer com 75 of 195 minutes done. À direita, os três slots do TitledPanel: o slot chamado header, o slot sem nome, chamado default, e o slot chamado footer. Uma seta liga cada pedaço ao seu slot. Embaixo, o segundo painel, que não preencheu nada: o header dele desenhou a reserva, Untitled, e onde estaria o footer há só um comentário v-if.\"><text x=\"145\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pai escreve</text><text x=\"560\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">TitledPanel.vue</text><rect x=\"420\" y=\"30\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"36\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">#header</text><text x=\"145\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt;This week&lt;/h2&gt;</text><rect x=\"435\" y=\"36\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot name=\"header\"&gt;</text><line x1=\"272\" y1=\"57\" x2=\"431\" y2=\"57\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,57.0 423.6,60.1 423.6,53.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"88\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">fora de qualquer template</text><text x=\"145\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt;Five sessions planned.&lt;/p&gt;</text><rect x=\"435\" y=\"88\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot /&gt;</text><line x1=\"272\" y1=\"109\" x2=\"431\" y2=\"109\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,109.0 423.6,112.1 423.6,105.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"140\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">#footer</text><text x=\"145\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75 of 195 minutes done</text><rect x=\"435\" y=\"140\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot name=\"footer\" /&gt;</text><line x1=\"272\" y1=\"161\" x2=\"431\" y2=\"161\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,161.0 423.6,164.1 423.6,157.9\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundo painel, nada preenchido:</text><rect x=\"230\" y=\"208\" width=\"210\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;header&gt;Untitled&lt;/header&gt;</text><rect x=\"460\" y=\"208\" width=\"130\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--v-if--&gt;</text><text x=\"600\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem footer</text></svg>", "caption": "Cada template preenche o slot que nomeia, o resto vai para o default, e um slot não preenchido desenha a sua reserva."}
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
