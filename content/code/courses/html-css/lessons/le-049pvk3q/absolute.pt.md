---
title: absolute: fora do fluxo, posicionada contra um ancestral
version: 1
---

**`position: absolute`** tira uma caixa do fluxo normal por completo: ela não ocupa espaço, as caixas em volta se fecham como se ela não estivesse lá, e os insets dela a posicionam contra o seu **bloco de contenção**. Aqui estão dois cartões de evento, cada um com um selo pensado para o canto superior direito:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Absolute · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .card { width: 300px; padding: 16px; margin: 40px; background: #f4f1ea; }
      .anchored { position: relative; }
      .badge {
        position: absolute;
        top: -10px;
        right: -10px;
        padding: 2px 8px;
        background: #8a1c1c;
        color: white;
      }
    </style>
  </head>
  <body>
    <article class="card anchored">
      <h2>Book swap</h2>
      <p>Saturday 10 October, from 10 am.</p>
      <span class="badge">New</span>
    </article>
    <article class="card">
      <h2>Poetry reading</h2>
      <p>Thursday 8 October, 7 pm.</p>
      <span class="badge">Free</span>
    </article>
  </body>
</html>
```

```
ana@laptop:~/site$ probe absolute.html box .card box .badge
article.card.anchored  x 40     y 40     width 332    height 147.81
article.card           x 40     y 227.81 width 332    height 147.81
span.badge  x 333.98 y 30     width 48.02  height 28
span.badge  x 985.09 y -10    width 48.91  height 28
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois cartões na página, desenhados a partir das caixas medidas, a 60 por cento. O primeiro cartão tem position: relative, e o selo New fica no canto superior direito dele, 10 pixels para fora. O segundo cartão não tem position, então o selo Free foi posicionado contra a página: em x 985,09, y -10, no canto superior direito da página e metade acima do topo.\"><path d=\"M20 30 h614.4 v240 h-614.4 z\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></path><text x=\"626.4\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a página</text><path d=\"M44 54 h199.2 v88.69 h-199.2 z\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"54\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.card.anchored</text><text x=\"54\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">position: relative</text><rect x=\"220.39\" y=\"48\" width=\"28.81\" height=\"16.8\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"234.79\" y=\"56.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">New</text><rect x=\"44\" y=\"166.69\" width=\"199.2\" height=\"88.69\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"188.69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.card</text><text x=\"54\" y=\"206.69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem position</text><rect x=\"611.05\" y=\"24\" width=\"29.35\" height=\"16.8\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"625.73\" y=\"32.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Free</text><text x=\"356\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">top: -10px; right: -10px</text><text x=\"356\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">New é medido a partir do cartão,</text><text x=\"356\" y=\"135.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">que é posicionado.</text><text x=\"356\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Free não achou ancestral</text><text x=\"356\" y=\"177.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">posicionado e foi para a página:</text><text x=\"356\" y=\"193.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">x 985,09, y -10, metade fora.</text></svg>", "caption": "Uma caixa absoluta é posicionada contra o ancestral posicionado mais próximo, e contra a página quando não há nenhum."}
```

**O primeiro selo está onde devia estar.** O cartão dele termina em x 372 e começa em y 40, e a borda direita do selo está em 382 e o topo em 30: `top: -10px` e `right: -10px` o puseram 10 pixels para fora do canto superior direito do cartão. O cartão tem `position: relative`, e foi isso que o tornou o bloco de contenção do selo.

**O segundo selo voou para o canto da página.** O cartão dele não tem `position`, então o selo procurou mais acima na árvore um ancestral que tivesse, não achou nenhum e foi posicionado contra a própria página: a borda direita 10 pixels depois da direita da página, em x 985,09 + 48,91 = 1034, e o topo em **y -10**, dez pixels acima do topo da página, onde parte dele nem pode ser vista. Nada quebrou e nenhum erro foi informado; o selo só foi para a única referência que conseguiu achar.

## O que o absolute faz com o fluxo

O selo não ocupa espaço, que é o que um selo precisa: a altura do cartão, 147,81, é o título e o parágrafo, e pôr ou tirar o selo não muda nada nela. O outro lado disso é que **uma caixa absoluta não consegue empurrar nada para fora do caminho**, e nada abre espaço para ela. Um selo com uma palavra mais longa cresce por cima do título embaixo. Posicionamento absoluto é certo para coisas pequenas postas em cima de algo cujo tamanho não depende delas.

Uma caixa absoluta sem largura encolhe para caber no conteúdo, como os selos fizeram, em vez de se esticar pelo contêiner como um bloco no fluxo faria. E as margens dela nunca colapsam com as de ninguém, seção 05 da aula 6.
