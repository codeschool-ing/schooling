---
title: Margens, e quando duas viram uma
version: 1
---

As margens têm um comportamento que padding e borda não têm, e que surpreende todo mundo uma vez: **margens verticais que se tocam colapsam numa só**, do tamanho da maior delas. Aqui estão quatro cartões de evento, cada um com 24 pixels de margem em cima e embaixo, cada um com um título de 16 pixels de margem em cima e embaixo:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Margins · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .event { margin: 24px 0; background: #f4f1ea; }
      .event h2 { margin: 16px 0; }
      .boxed { padding: 1px 0; }
      .centred { width: 400px; margin: 0 auto; }
    </style>
  </head>
  <body>
    <article class="event"><h2>Poetry reading</h2></article>
    <article class="event"><h2>Book swap</h2></article>
    <article class="event boxed"><h2>Bookbinding</h2></article>
    <article class="event centred"><h2>Centred</h2></article>
  </body>
</html>
```

```
ana@laptop:~/site$ probe margins.html box .event box h2
article.event          x 0      y 24     width 1024   height 27
article.event          x 0      y 75     width 1024   height 27
article.event.boxed    x 0      y 126    width 1024   height 61
article.event.centred  x 312    y 211    width 400    height 27
h2  x 0      y 24     width 1024   height 27
h2  x 0      y 75     width 1024   height 27
h2  x 0      y 143    width 1024   height 27
h2  x 312    y 211    width 400    height 27
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Três articles de margins.html, desenhados nas posições medidas. O primeiro começa em y 24, o segundo em 75 e o terceiro em 126, então os vãos são de 24 cada: as margens de 24 pixels dos articles e as de 16 dos títulos colapsaram num vão só de 24. O terceiro article tem 1 pixel de padding, que impede as margens do título de atravessá-lo, e tem 61 de altura: 1 mais 16 mais 27 mais 16 mais 1.\"><rect x=\"40\" y=\"51.2\" width=\"300\" height=\"35.1\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"68.75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 1</text><rect x=\"40\" y=\"117.5\" width=\"300\" height=\"35.1\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"135.05\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 2</text><rect x=\"40\" y=\"183.8\" width=\"300\" height=\"79.3\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"223.45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 3, padding 1px</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"51.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"35.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><line x1=\"360\" y1=\"86.3\" x2=\"360\" y2=\"117.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"101.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><line x1=\"360\" y1=\"152.6\" x2=\"360\" y2=\"183.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"168.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><text x=\"420\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cada article tem margem de 24px e o</text><text x=\"420\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">h2 dele uma de 16px. Entre dois articles</text><text x=\"420\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o vão é 24, não 24 + 16 + 16 + 24:</text><text x=\"420\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">margens que se tocam colapsam na maior.</text><text x=\"420\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Um pixel de padding separa a margem do</text><text x=\"420\" y=\"211.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h2 da do article, e a caixa cresce</text><text x=\"420\" y=\"229.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para 61: 1 + 16 + 27 + 16 + 1.</text></svg>", "caption": "Margens verticais que se tocam viram uma margem só, a maior delas."}
```

Leia os dois primeiros articles. O primeiro começa em y 24 e tem 27 de altura, então termina em 51; o segundo começa em 75. **O vão é de 24 pixels**, não os 24 + 24 que você somaria, e não 24 + 16 + 16 + 24 contando também as margens dos títulos. Cada uma dessas margens tocava outra, e elas colapsaram num 24 só, o maior.

Há um segundo colapso nos mesmos números. O primeiro article e o título dele começam os dois em y 24, e o article tem exatamente a altura do título, 27. **A margem do título atravessou o article**: sem nada entre a borda de cima do pai e a do filho, a margem do filho colapsa com a do pai e vai parar fora do pai.

O terceiro article tem `padding: 1px 0`, e esse um pixel basta para impedir. Agora as margens do título ficam dentro: o título começa em 143, que é 126 + 1 + 16, e o article tem **61** de altura, 1 + 16 + 27 + 16 + 1. Uma borda faz o mesmo, e também transformar o article num contêiner flex ou grid, como as aulas 8 e 9 farão.

## Quando as margens colapsam, e quando não

Só margens **verticais** colapsam, e só entre caixas **block** no fluxo normal da página. Margens horizontais nunca colapsam. Margens de itens flex e grid nunca colapsam. Caixas flutuantes e posicionadas de forma absoluta, aula 7, nunca colapsam. É uma regra para texto, e foi desenhada para texto: a margem de um parágrafo e a de um título não deviam se somar num buraco entre eles.

## Margens `auto`

O quarto article tem `width: 400px; margin: 0 auto`. Uma margem horizontal `auto` pega todo o espaço que sobra, e duas delas o dividem igualmente: (1024 − 400) / 2 = 312, que é onde o `probe` o encontrou. É assim que se centraliza horizontalmente um bloco de largura fixa. Uma margem vertical `auto`, no fluxo normal, é 0; a aula 8 mostra onde ela faz mais.
