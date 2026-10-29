---
title: Templates e slots
version: 1
---

**Um `<template>` é marcação que o navegador interpreta e nunca renderiza, e um `<slot>` é um buraco numa
árvore shadow onde aparecem os filhos do próprio host.** Juntos, deixam um elemento dizer onde vai o
conteúdo da página sem mexer no conteúdo da página.

## O template

O arquivo do elemento monta um template quando o módulo é carregado pela primeira vez:

```typescript
const template = document.createElement("template");
template.innerHTML = `
  <style>…</style>
  <slot></slot>
  <span class="when"></span>
  <button type="button" part="button">Mark done</button>
  <span class="done" hidden>done</span>
`;
```

O que está dentro de um template é **inerte**: interpretado em elementos, mas não desenhado, com os
scripts sem rodar e as imagens sem ser buscadas. `template.content` é um fragmento de documento que os
guarda, e cada construtor faz a sua cópia com `template.content.cloneNode(true)`. A marcação é interpretada
uma vez, quantas linhas a página tiver; clonar uma árvore já interpretada sai mais barato do que
interpretar uma string de novo para cada elemento.

O `<style>` lá dentro é a folha de estilo inteira do elemento, e como é clonado para cada árvore shadow,
vale só para aquela árvore. Uma biblioteca com muitos elementos pode, em vez disso, montar um único
`CSSStyleSheet` e entregá-lo a cada raiz por `shadowRoot.adoptedStyleSheets`, para que todas as linhas
compartilhem uma só folha interpretada.

## O slot

`<slot></slot>` é o slot padrão. Os nós filhos do host, aqui o texto *JavaScript*, são desenhados onde ele
está, na frente da data. Eles não são movidos: no DOM continuam sendo filhos de `<planner-session>`, e é
por isso que a página pode mudá-los e estilizá-los.

Um elemento com mais de um buraco dá nome a eles:

```html
<!-- inside the shadow tree -->
<slot name="title"></slot>
<slot></slot>

<!-- in the page -->
<planner-card>
  <h3 slot="title">JavaScript</h3>
  <p>Two sessions this week.</p>
</planner-card>
```

Um filho com `slot="title"` vai para o slot com esse nome, e todo o resto vai para o padrão. O que estiver
escrito dentro de um `<slot>` é a **alternativa** dele, mostrada quando nada foi encaixado ali.

## Texto dentro, ou texto por atributo

O nome do curso poderia ter sido um atributo, `course="JavaScript"`, desenhado pelo `#render` como a data.
Passá-lo como conteúdo é a melhor escolha para texto que uma pessoa lê: ele aparece antes de o script
rodar, é traduzido pela página como o resto dela, e pode conter marcação, como um link. Os dados com que o
elemento faz contas, os minutos e a data, ficam em atributos.
