---
title: repeat(), minmax() e quantas colunas couberem
version: 1
---

Escrever `1fr 1fr 1fr 1fr` cansa, e **`repeat(4, 1fr)`** diz a mesma coisa. Até aí é abreviação. Combinado com mais duas ideias, vira a linha mais útil do Grid.

**`minmax(min, max)`** dimensiona uma trilha entre dois limites: `minmax(200px, 1fr)` nunca fica mais estreita que 200 pixels e, de resto, pega uma parte do espaço. E em vez de um número, `repeat()` aceita **`auto-fill`** ou **`auto-fit`**, que querem dizer "quantas trilhas couberem". Juntos:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>auto-fill and auto-fit · Andorinha Books</title>
    <style>
      body { margin: 0; padding: 8px; font: 16px/1.5 sans-serif; }
      .cards { display: grid; gap: 16px; margin-bottom: 16px; }
      .fill { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }
      .fit { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }
      .cards > article { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="cards fill">
      <article>Poetry reading</article>
      <article>Book swap</article>
      <article>Bookbinding</article>
    </div>
    <div class="cards fit">
      <article>Poetry reading</article>
      <article>Book swap</article>
      <article>Bookbinding</article>
    </div>
  </body>
</html>
```

O `probe` perguntou ao navegador que trilhas ele criou, e para onde foram os três cartões:

```
ana@laptop:~/site$ probe autofit.html style .fill grid-template-columns style .fit grid-template-columns
div.cards.fill  grid-template-columns: 240px 240px 240px 240px
div.cards.fit  grid-template-columns: 325.328px 325.328px 325.344px 0px
ana@laptop:~/site$ probe autofit.html box '.fill article' box '.fit article'
article  x 8      y 8      width 240    height 24
article  x 264    y 8      width 240    height 24
article  x 520    y 8      width 240    height 24
article  x 8      y 48     width 325.33 height 24
article  x 349.33 y 48     width 325.33 height 24
article  x 690.66 y 48     width 325.34 height 24
```

A página tem 1008 pixels de largura para trabalhar. Uma trilha de pelo menos 200 e vãos de 16 cabem **quatro vezes**: 4 × 200 + 3 × 16 = 848, e uma quinta precisaria de 1064. Então os dois grids criaram quatro trilhas. A diferença está no que aconteceu com a quarta, que não tem cartão:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Três cartões em dois grids de 1008 pixels de largura. Com repeat auto-fill e minmax 200px 1fr, o navegador criou quatro trilhas de 240 e a quarta fica vazia. Com auto-fit, criou as mesmas quatro trilhas, colapsou a vazia para 0 pixel, e os três cartões têm 325,33 de largura cada.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">repeat(auto-fill, minmax(200px, 1fr))</text><rect x=\"20\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"94.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"178.72\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"253.12\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"337.44\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"411.84\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"496.16\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></rect><text x=\"570.56\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">240</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">repeat(auto-fit, minmax(200px, 1fr))</text><rect x=\"20\" y=\"110\" width=\"201.7\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"120.85\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.33</text><rect x=\"231.62\" y=\"110\" width=\"201.7\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"332.48\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.33</text><rect x=\"443.25\" y=\"110\" width=\"201.71\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"544.1\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.34</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">auto-fill criou quatro trilhas e deixou a quarta vazia; auto-fit criou as mesmas quatro, colapsou a vazia</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">para 0px e dividiu o espaço dela entre os três cartões.</text></svg>", "caption": "Os dois só diferem quando há menos itens que trilhas."}
```

**`auto-fill` manteve a trilha vazia**: quatro colunas de **240**, os cartões nas três primeiras, e espaço para um quarto cartão à direita. **`auto-fit` colapsou a trilha vazia para 0px**, como o valor computado diz, e deu o espaço dela às outras: três cartões de **325,33**. Com doze cartões os dois seriam idênticos; só diferem quando há menos itens que trilhas. Escolha `auto-fit` quando os itens devem se esticar para preencher a fileira, `auto-fill` quando todo item deve manter o mesmo tamanho onde quer que a fileira termine.

## O layout que responde sozinho

Num celular de 390 de largura, o mesmo grid `auto-fit` cria uma coluna:

```
ana@laptop:~/site$ probe --width 390 autofit.html box '.fit article'
article  x 8      y 128    width 374    height 24
article  x 8      y 168    width 374    height 24
article  x 8      y 208    width 374    height 24
```

Havia espaço para uma trilha de 200 pixels e não para duas, então há uma coluna, de **374**, e os cartões se empilham. **Uma linha de CSS dá quatro colunas num desktop, duas num tablet e uma no celular**, sem nenhum ponto de quebra escolhido por ninguém, porque o número de colunas decorre do espaço e da largura mínima. A aula 11 se apoia exatamente nisso: um layout que se adapta sozinho precisa de menos media queries.
