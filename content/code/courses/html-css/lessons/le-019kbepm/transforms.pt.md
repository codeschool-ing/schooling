---
title: Transforms movem o que é desenhado, não o layout
version: 1
---

A propriedade **`transform`** move, gira, escala ou inclina um elemento **depois que o layout o posicionou**. Esse fato explica todo o resto sobre transforms. Aqui estão três livros numa estante, com o do meio levantado:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 40px 16px; font-family: system-ui, sans-serif; }
      .shelf { display: flex; gap: 16px; }
      .book { width: 120px; height: 160px; background: #f4f1ea; border: 1px solid #8a8577; }
      .lifted { transform: translate(0, -24px) scale(1.1); }
    </style>
  </head>
  <body>
    <div class="shelf">
      <div class="book">One</div>
      <div class="book lifted">Two</div>
      <div class="book">Three</div>
    </div>
  </body>
</html>
```

`translate(0, -24px)` o move 24 pixels para cima, e `scale(1.1)` o deixa 10% maior. O `probe` mediu duas coisas diferentes: **`box`** pergunta onde o elemento é desenhado, com o transform, e o passo novo **`layout`** pergunta onde o layout o pôs, antes de qualquer transform:

```
ana@laptop:~/site$ probe move.html box .book layout .book
div.book         x 16     y 40     width 122    height 162
div.book.lifted  x 147.9  y 7.9    width 134.2  height 178.2
div.book         x 292    y 40     width 122    height 162
div.book  laid out at x 16, y 40, width 122, height 162
div.book.lifted  laid out at x 154, y 40, width 122, height 162
div.book  laid out at x 292, y 40, width 122, height 162
```

O livro levantado é **desenhado** em y 7,9, com 134,2 de largura e 178,2 de altura: 10% maior e mais acima. Mas o **layout** ainda o tem em x 154, y 40, 122 por 162, exatamente o tamanho e o lugar dos vizinhos. E o terceiro livro está em x 292, como se nada tivesse acontecido, porque para o layout nada aconteceu. O livro escalado agora cobre o vão dos dois lados, e a estante não abriu espaço para ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 204\" role=\"img\" aria-label=\"Três livros de move.html, desenhados a partir das caixas medidas. O do meio, Two, tem um contorno tracejado onde o layout o pôs, em x 154, y 40, 122 por 162, do tamanho dos vizinhos, e um cheio onde ele é desenhado, mais acima e 10% maior, em x 147,9, y 7,9, 134,2 por 178,2. O terceiro livro fica em x 292.\"><rect x=\"54.4\" y=\"46\" width=\"109.8\" height=\"145.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"62.4\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">One</text><rect x=\"302.8\" y=\"46\" width=\"109.8\" height=\"145.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"310.8\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Three</text><rect x=\"173.11\" y=\"17.11\" width=\"120.78\" height=\"160.38\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"181.11\" y=\"33.11\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Two</text><path d=\"M 178.6 46 H 288.4 V 191.8 H 178.6 Z\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><text x=\"440\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tracejado: onde o layout pôs Two,</text><text x=\"440\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">x 154, y 40, 122 por 162</text><text x=\"440\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cheio: onde ele é desenhado,</text><text x=\"440\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">x 147,9, y 7,9, 134,2 por 178,2</text><text x=\"440\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Three fica em x 292: para o</text><text x=\"440\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">layout, nada se moveu.</text></svg>", "caption": "Um transform muda o desenho e deixa o layout em paz, então nada em volta se move.", "same": ["One", "Three", "Two"]}
```

## O que isso compra, e o que custa

**Compra suavidade.** Mover algo mudando `margin` ou `top` muda o layout, e toda caixa depois dele pode se mover também. Um transform não muda nada que o navegador precise montar de novo, e é por isso que a seção 07 vai descobrir que ele é o jeito barato de animar movimento.

**Custa espaço.** Um elemento com transform pode cobrir os vizinhos, como faz o livro levantado, e pode passar da borda do contêiner ou da janela, onde o `overflow` o corta ou cria uma barra de rolagem. Se algo deve ocupar mais espaço, mude o tamanho, não a escala.

Transforms são desenhados a partir da **`transform-origin`**, que por padrão é o centro do elemento. É por isso que o livro escalado cresceu nas quatro direções, começando 6,1 pixels à esquerda de onde foi posto. `transform-origin: bottom` o faria crescer para cima a partir da estante.
