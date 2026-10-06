---
title: Padrões de posicionamento que valem conhecer
version: 1
---

Quatro padrões pequenos usam posicionamento de jeitos que você vai encontrar em quase todo site. Estão todos numa página:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Patterns · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .skip {
        position: absolute;
        left: 8px;
        top: -100px;
        padding: 8px 16px;
        background: #2f6f4e;
        color: white;
      }
      .skip:focus { top: 8px; }
      .visually-hidden {
        position: absolute;
        width: 1px;
        height: 1px;
        overflow: hidden;
        clip-path: inset(50%);
        white-space: nowrap;
      }
      .card { position: relative; width: 300px; padding: 16px; margin: 60px 16px 16px; background: #f4f1ea; }
      .card a::after { content: ""; position: absolute; inset: 0; }
    </style>
  </head>
  <body>
    <a class="skip" href="#main">Skip to main content</a>
    <header><p>Andorinha Books</p></header>
    <main id="main">
      <article class="card">
        <h2><a href="swap.html">Book swap</a></h2>
        <p>Saturday 10 October, from 10 am.</p>
      </article>
      <table>
        <caption class="visually-hidden">Opening hours</caption>
        <tr><th scope="row">Saturday</th><td>10 am to 4 pm</td></tr>
      </table>
    </main>
  </body>
</html>
```

## Um link de pular

A aula 2 mencionou o **link de pular**, "pular para o conteúdo principal", o primeiro link de uma página, que deixa quem usa teclado pular o cabeçalho e o menu em vez de atravessá-los com Tab em toda página. Ele precisa ser a primeira coisa que o Tab alcança e deve ficar visível quando isso acontece, mas atrapalharia a página de todo mundo. Então ele espera fora da tela:

```
ana@laptop:~/site$ probe patterns.html box .skip tab box .skip
a.skip  x 8      y -100   width 176.97 height 40
focus: a "Skip to main content"
a.skip  x 8      y 8      width 176.97 height 40
```

Antes do Tab ele está em **y −100**, acima do topo da página. O primeiro Tab o foca, `.skip:focus { top: 8px; }` se aplica, e ele está em **y 8**, na tela, onde quem usa teclado vê o que o Enter vai fazer.

## Um cartão inteiro que é um link

Um cartão cujo título é um link costuma ser desejado clicável em todo lugar, não só nas palavras do título. Envolver o cartão inteiro num `<a>` faz do texto inteiro do cartão o nome do link, lido por completo por um leitor de tela. O **link esticado** (*stretched link*) mantém o link no título e estica a área clicável dele: `.card a::after { content: ""; position: absolute; inset: 0; }` estende um pseudo-elemento vazio sobre o cartão, medido contra o cartão porque o cartão é `position: relative`.

```
ana@laptop:~/site$ probe patterns.html box .card top 330 230 top 30 110
article.card  x 16     y 100    width 332    height 147.81
at 330,230: a  "Book swap"
at 30,110: a  "Book swap"
```

Um ponto no canto inferior direito do cartão, sobre o parágrafo, e um ponto no canto superior esquerdo, no padding, acertam os dois **o link**. Na cópia da página sem o `::after`, o mesmo canto acerta o article. O nome do link continua sendo só *Book swap*.

## Texto só para leitores de tela

A aula 4 prometeu uma técnica para uma legenda que deve estar na árvore de acessibilidade e não na tela. É um conjunto de declarações costumeiramente chamado pela classe `visually-hidden`:

```
ana@laptop:~/site$ probe patterns.html box caption tree table
caption.visually-hidden  x 2      y 265.81 width 1      height 1
- table "Opening hours":
  - caption: Opening hours
  - rowgroup:
    - row "Saturday 10 am to 4 pm":
      - rowheader "Saturday"
      - cell "10 am to 4 pm"
```

A legenda é desenhada como uma caixa de **1 por 1 pixel**, recortada até sumir, e a árvore continua nomeando a tabela *Opening hours*. `display: none` ou `visibility: hidden` a teriam tirado da árvore também, que é o oposto do que se quer.

## Um cabeçalho sticky que não esconde as âncoras

O quarto padrão são duas linhas e fecha a seção 06: um cabeçalho com `position: sticky; top: 0` mantém o menu na tela, e `html { scroll-padding-top: 4rem; }` faz um pulo para `#events` parar 4rem antes, para o título da seção não ficar embaixo do cabeçalho. Sticky costuma ser uma escolha melhor que fixed para um cabeçalho, porque ocupa o próprio espaço no topo da página em vez de cobrir conteúdo.
