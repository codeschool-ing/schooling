---
title: subgrid: alinhando o interior de itens separados
version: 1
---

Um grid alinha os itens. Ele não alinha **o conteúdo** dos itens: um cartão é um item grid, e o título, o texto e o link dentro dele são montados pelo cartão, que não sabe nada dos cartões ao lado. Quando os títulos têm tamanhos diferentes, os links no pé dos cartões acabam em alturas diferentes. **`subgrid`** deixa um item participar das trilhas do pai, para que as partes de cartões diferentes usem as mesmas linhas. Aqui estão três cartões de evento duas vezes, a segunda com subgrid:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Subgrid · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .events {
        display: grid;
        grid-template-columns: repeat(3, 220px);
        gap: 16px;
        margin-bottom: 24px;
      }
      .events article { background: #f4f1ea; padding: 8px; }
      .events h2 { margin: 0; font-size: 1.1rem; }
      .events p { margin: 0; }
      .aligned article {
        display: grid;
        grid-row: span 3;
        grid-template-rows: subgrid;
        gap: 8px;
      }
    </style>
  </head>
  <body>
    <div class="events plain">
      <article><h2>Book swap</h2><p>Saturday, from 10 am.</p><a href="swap.html">Details</a></article>
      <article><h2>Poetry reading: Hilda Hilst and her contemporaries</h2><p>Thursday, 7 pm.</p><a href="poetry.html">Details</a></article>
      <article><h2>Bookbinding</h2><p>A two-hour class for beginners, with all materials included.</p><a href="binding.html">Details</a></article>
    </div>
    <div class="events aligned">
      <article><h2>Book swap</h2><p>Saturday, from 10 am.</p><a href="swap.html">Details</a></article>
      <article><h2>Poetry reading: Hilda Hilst and her contemporaries</h2><p>Thursday, 7 pm.</p><a href="poetry.html">Details</a></article>
      <article><h2>Bookbinding</h2><p>A two-hour class for beginners, with all materials included.</p><a href="binding.html">Details</a></article>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe subgrid.html box '.plain p' box '.plain a'
p  x 8      y 34.39  width 204    height 24
p  x 244    y 87.17  width 204    height 24
p  x 480    y 34.39  width 204    height 72
a  x 8      y 61.39  width 48.91  height 17
a  x 244    y 114.17 width 48.91  height 17
a  x 480    y 109.39 width 48.91  height 17
ana@laptop:~/site$ probe subgrid.html box '.aligned p' box '.aligned a'
p  x 8      y 262.34 width 204    height 72
p  x 244    y 262.34 width 204    height 72
p  x 480    y 262.34 width 204    height 72
a  x 8      y 342.34 width 204    height 24
a  x 244    y 342.34 width 204    height 24
a  x 480    y 342.34 width 204    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Três cartões de evento, duas vezes. No grid simples, cada cartão monta título, parágrafo e link por conta própria, então os links caem em três alturas diferentes, 61,39, 114,17 e 109,39. Com subgrid, os cartões usam as linhas do pai, então todo parágrafo começa na mesma altura, e todo link também.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">grid</text><rect x=\"20\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"26\" y=\"46.63\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"26\" y=\"62.83\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"124\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"78.3\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"94.5\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"228\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"46.63\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"91.63\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><text x=\"380\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">grid + subgrid</text><rect x=\"380\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"490\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"490\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"588\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"594\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"594\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><text x=\"20\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">O parágrafo (cinza) e o link (verde) de cada cartão. À esquerda, cada cartão monta as próprias linhas, e os links</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">caem em 61,39, 114,17 e 109,39. Com subgrid eles usam as linhas do pai: os três na mesma altura.</text></svg>", "caption": "subgrid deixa as partes de cartões separados se alinharem entre si."}
```

No grid simples, o parágrafo de cada cartão começa abaixo do próprio título: em **34,39, 87,17 e 34,39**, porque o segundo título ocupa três linhas. Os links caem em **61,39, 114,17 e 109,39**, três alturas diferentes, o que parece descuidado numa fileira de cartões. Com subgrid, todo parágrafo começa em **262,34** e todo link em **342,34**.

O que fez isso: cada cartão ocupa três linhas do grid pai, `grid-row: span 3`, e declara `grid-template-rows: subgrid`, que quer dizer "as minhas linhas são essas três linhas do meu pai". As linhas implícitas do pai são dimensionadas pelo conteúdo mais alto entre todos os cartões, o título longo, o parágrafo longo, então a linha de título de todo cartão tem a altura do título mais alto. Os links também se esticam até a largura do cartão, **204**, porque um item grid se estica por padrão; um `justify-self: start` os manteria do tamanho do texto.

`subgrid` funciona também para colunas, e é suportado em todo navegador atual. Antes de ele existir, isso se fazia com alturas fixas para os títulos, que quebravam sempre que um título era mais longo que o esperado.
