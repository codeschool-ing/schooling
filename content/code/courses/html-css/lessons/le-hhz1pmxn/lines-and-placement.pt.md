---
title: Linhas, e pondo itens nelas
version: 1
---

Por padrão os itens preenchem o grid em ordem. Para pôr um item num lugar específico, você diz **em que linhas ele começa e termina**. As linhas são numeradas a partir de 1 no começo do grid, e a partir de **-1 de trás para frente** a partir do fim. Aqui está um quadro de quatro colunas e três linhas com itens posicionados de quatro jeitos:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Lines · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .board {
        display: grid;
        grid-template-columns: repeat(4, 200px);
        grid-template-rows: repeat(3, 100px);
        gap: 10px;
      }
      .board > * { background: #f4f1ea; }
      .feature { grid-column: 1 / 3; grid-row: 1 / 3; }
      .banner { grid-column: 1 / -1; }
      .tall { grid-row: span 2; }
    </style>
  </head>
  <body>
    <section class="board">
      <article class="feature">Feature: Hilda Hilst</article>
      <article class="tall">Book swap</article>
      <article>Bookbinding</article>
      <article>New arrivals</article>
      <article class="banner">Closed on 12 October</article>
    </section>
  </body>
</html>
```

```
ana@laptop:~/site$ probe lines.html box '.board > *'
article.feature  x 0      y 0      width 410    height 210
article.tall     x 420    y 0      width 200    height 210
article          x 630    y 0      width 200    height 100
article          x 630    y 110    width 200    height 100
article.banner   x 0      y 220    width 830    height 100
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"O quadro de lines.html desenhado a partir das caixas medidas, com as linhas do grid numeradas: 1 a 5 atravessando as quatro colunas e 1 a 4 descendo as três linhas. O destaque vai das linhas de coluna 1 a 3 e das linhas de linha 1 a 3. O item alto ocupa duas linhas na terceira coluna. Dois itens sem posição preenchem a quarta coluna. A faixa vai da linha 1 à linha -1, a largura inteira da linha de baixo.\"><line x1=\"50\" y1=\"20\" x2=\"50\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"50\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"177.1\" y1=\"20\" x2=\"177.1\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"177.1\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"307.3\" y1=\"20\" x2=\"307.3\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"307.3\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"437.5\" y1=\"20\" x2=\"437.5\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"437.5\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><line x1=\"564.6\" y1=\"20\" x2=\"564.6\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"564.6\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><line x1=\"36\" y1=\"34\" x2=\"568.6\" y2=\"34\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"36\" y1=\"99.1\" x2=\"568.6\" y2=\"99.1\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"99.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"36\" y1=\"167.3\" x2=\"568.6\" y2=\"167.3\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"167.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"36\" y1=\"232.4\" x2=\"568.6\" y2=\"232.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"232.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><rect x=\"50\" y=\"34\" width=\"254.2\" height=\"130.2\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"58\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.feature  1 / 3, 1 / 3</text><rect x=\"310.4\" y=\"34\" width=\"124\" height=\"130.2\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"318.4\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.tall  span 2</text><rect x=\"440.6\" y=\"34\" width=\"124\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"440.6\" y=\"102.2\" width=\"124\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"50\" y=\"170.4\" width=\"514.6\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"58\" y=\"186.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.banner  1 / -1</text><text x=\"580\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">As linhas são numeradas</text><text x=\"580\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a partir de 1, e a partir</text><text x=\"580\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de -1 de trás para frente:</text><text x=\"580\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 / -1 é a largura inteira.</text><text x=\"580\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Um item sem posição</text><text x=\"580\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ocupa a próxima célula</text><text x=\"580\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">livre.</text></svg>", "caption": "Os itens são postos entre linhas numeradas, não em células numeradas."}
```

- **`.feature { grid-column: 1 / 3; grid-row: 1 / 3; }`** começa na linha de coluna 1 e termina na 3, então cobre duas colunas, e o mesmo nas linhas: **410 por 210**, duas trilhas de 200 mais o vão de 10 pixels entre elas, em cada direção.
- **`.tall { grid-row: span 2; }`** diz só "duas linhas de altura" e deixa o navegador escolher onde: o primeiro lugar livre, a terceira coluna, **200 por 210**.
- Os dois articles sem posição preenchem as próximas células livres, a quarta coluna das linhas 1 e 2.
- **`.banner { grid-column: 1 / -1; }`** vai da primeira linha à última, **830** de largura, a largura inteira, sejam quantas forem as colunas. É o motivo de contar de trás para frente: `1 / -1` é "de ponta a ponta" em qualquer grid.

## As formas de grid-column

`grid-column` é abreviação de `grid-column-start` e `grid-column-end`, escritas com uma barra. Cada ponta pode ser um número de linha, um número negativo, `span n` ou um nome de linha (a próxima seção). `grid-column: 2` sozinho põe o item na coluna 2, uma trilha de largura. `grid-area: 1 / 1 / 3 / 3` define as quatro de uma vez, na ordem início da linha, início da coluna, fim da linha, fim da coluna, o que é fácil de errar, e a próxima seção dá a `grid-area` um uso melhor.

**Posicionar itens não muda o HTML.** Um item posto na primeira célula pode ser o último do arquivo, e isso tem uma consequência para quem usa teclado e leitor de tela que a seção 10 mede.
