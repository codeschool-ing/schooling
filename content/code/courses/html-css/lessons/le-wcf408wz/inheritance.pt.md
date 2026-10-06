---
title: Herança
version: 1
---

Alguns valores nunca são definidos num elemento por regra nenhuma; eles descem do pai. Isso é **herança**, e é por isso que definir uma fonte no `<body>` muda a fonte de todo parágrafo da página sem uma regra para parágrafos. Aqui está `inherit.css`:

```css
main {
  color: #2f6f4e;
  font-family: Georgia, serif;
  border: 2px solid #2f6f4e;
}
.more { color: inherit; }
.cancelled { color: #8a1c1c; }
.cancelled h2 { color: initial; }
```

A cor, a fonte e a borda são todas definidas no `<main>`. Aqui está o que chegou à nota, dois níveis abaixo, dentro de um article:

```
ana@laptop:~/site$ probe inherit.html style .note color,font-family,border-top-width rules .note color
p.note  color: rgb(47, 111, 78)
p.note  font-family: Georgia, serif
p.note  border-top-width: 0px
.note  no rule sets color
```

A nota está verde e em Georgia, **e nenhuma regra define a cor dela**: `probe rules` não achou nada para listar, porque nada casou. O valor foi herdado do `<main>`, através do `<article>`. A borda não desceu: a borda da nota tem 0 pixel.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"Herança a partir de main, que define color #2f6f4e e uma borda de 2px. O parágrafo .note herda a cor e não tem borda. O link .more define color: inherit, que pega o verde do pai em vez do azul de link do navegador. .cancelled h2 define color: initial e volta ao preto. Cor e fonte descem pela árvore; borda não.\"><line x1=\"360\" y1=\"70\" x2=\"140\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"70\" x2=\"360\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"70\" x2=\"580\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"270\" y=\"18\" width=\"180\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">main</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: #2f6f4e</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">border: 2px</text><rect x=\"65\" y=\"132\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">p.note</text><text x=\"140\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: herdada</text><text x=\"140\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">border: nenhuma</text><rect x=\"265\" y=\"132\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">a.more</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: inherit</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(vence o azul do link)</text><rect x=\"495\" y=\"132\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">.cancelled h2</text><text x=\"580\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: initial</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">volta ao preto</text><text x=\"20\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">color e font-family descem pela árvore; border não.</text><text x=\"20\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">inherit pega o valor do pai de propósito; initial pega o padrão da própria propriedade.</text></svg>", "caption": "As propriedades herdadas são as que tratam de texto; as de caixa ficam com a caixa que as definiu."}
```

**As propriedades herdadas são, grosso modo, as que tratam de texto**: `color`, `font-family`, `font-size`, `font-weight`, `line-height`, `text-align`, `letter-spacing`, `visibility` e as propriedades de lista. **As propriedades da caixa não são herdadas**: `border`, `margin`, `padding`, `width`, `height`, `background`, `display`. Essa divisão é o que você ia querer: uma borda num article que também aparecesse em cada parágrafo dentro dele seria inútil.

Um valor definido por qualquer regra, mesmo o padrão do navegador, vence um herdado, porque a herança só preenche onde nada casou. É por isso que um link dentro de um parágrafo verde continua azul:

```
ana@laptop:~/site$ probe events.html rules .more color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
computed color: rgb(0, 0, 238)
```

A folha de estilos do próprio navegador tem uma regra para links, `a:-webkit-any-link`, que define `color: -webkit-link`, o nome interno dele para o azul de link, e uma regra que casa vence a herança.

## Quatro palavras-chave

Toda propriedade aceita quatro palavras-chave que pedem um valor vindo de outro lugar:

- **`inherit`**: pega o valor do pai, mesmo numa propriedade que não herda por padrão, ou mesmo quando uma regra se aplicaria. `.more { color: inherit; }` venceu o azul do navegador.
- **`initial`**: pega o valor inicial da própria propriedade, como a especificação o define. Para `color` isso é preto.
- **`unset`**: `inherit` se a propriedade herda, `initial` se não herda.
- **`revert`**: volta ao que a folha de estilos padrão do navegador teria dado.

```
ana@laptop:~/site$ probe inherit.html style .more color style '.cancelled h2' color
a.more  color: rgb(47, 111, 78)
h2  color: rgb(0, 0, 0)
```

O link pegou o verde do pai. O título do evento cancelado pegou `color: initial`, que é preto, `rgb(0, 0, 0)`, mesmo com o article dele definindo vermelho. `initial` é o padrão da especificação, não o estilo padrão do navegador nem a cor do pai, o que surpreende as pessoas; `revert` é o que quer dizer "como se eu não tivesse estilizado isto".
