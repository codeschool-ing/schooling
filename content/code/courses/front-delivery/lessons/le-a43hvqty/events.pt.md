---
title: Eventos através da fronteira
version: 1
---

**Um elemento responde à página do jeito que um nativo responde: disparando eventos.** `<button>` dispara
`click`; `<planner-session>` dispara `session-done` quando o seu botão é apertado, com o id da linha em
`detail`. A página escuta esse evento como qualquer outro, e o único listener da página de demonstração
escreve a frase debaixo das linhas.

```typescript
this.dispatchEvent(new CustomEvent("session-done", { bubbles: true, detail: { id: this.id } }));
```

- **`CustomEvent`** leva dados em `detail`, qualquer valor. Aqui é o id, então uma página que escuta uma
  vez só, em `document`, sabe qual linha foi marcada.
- **`bubbles: true`** deixa o evento subir do elemento pelos ancestrais até `document`. Um listener na
  própria linha funcionaria sem isso; o listener da demonstração, em `document`, nunca o ouviria.
- **O nome** é do próprio elemento. Um nome em minúsculas e com hífen não colide com um futuro evento
  nativo, e é a forma que todo framework consegue escutar, como a última seção mostra.

## Redirecionamento

O próprio `click` do botão começa dentro da árvore shadow, e um evento nativo assim é **composed**: ele
atravessa a fronteira e continua subindo pela página. Mas um listener na página que lê `event.target`
recebe o elemento `<planner-session>`, e não o botão. O navegador **redireciona** o evento a cada
fronteira que ele cruza, então a página vê o elemento mais externo que tem permissão de ver, e o lado de
dentro continua privado. `event.composedPath()` lista o caminho inteiro, árvore shadow incluída, numa
raiz aberta.

## Por que `composed` não está ligado

`CustomEvent` não é composed a menos que você peça, então um evento disparado de dentro de uma árvore
shadow para na raiz dela e a página nunca o ouve. Este elemento não precisa da opção, porque dispara em
**`this`, o host**, que já está na árvore da página. Se tivesse disparado no botão,

```typescript
this.#root.querySelector("button")!.dispatchEvent(new CustomEvent("session-done", { bubbles: true }));
```

o evento subiria até a raiz shadow e pararia ali, e a frase da demonstração nunca mudaria.
`composed: true` resolveria isso, e também deixaria o evento sair de toda árvore shadow acima dele, numa
página em que a linha estivesse dentro de outro componente. Disparar no host é a regra mais simples: **o
host é a face pública do elemento, então os eventos dele começam ali.**

## Propriedades primeiro, depois o evento

O handler do clique define `this.done = true` antes de disparar. Um listener que lê a linha quando o
evento chega, portanto, já a encontra feita, atributo incluído, e o teste de uma seção mais adiante
confere as duas coisas nessa ordem.
