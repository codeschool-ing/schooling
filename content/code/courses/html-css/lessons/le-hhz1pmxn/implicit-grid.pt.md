---
title: O grid implícito, e preenchendo os buracos
version: 1
---

Um template de grid declara algumas trilhas. Quando há mais itens que células declaradas, ou um item é posto fora delas, o navegador **acrescenta trilhas por conta própria**. Essas são o **grid implícito**, e duas propriedades o controlam: **`grid-auto-rows`** dimensiona as linhas que ele acrescenta (e `grid-auto-columns` as colunas), e **`grid-auto-flow`** decide como os itens sem posição entram.

Aqui está uma prateleira de três colunas que não declara linha nenhuma, com `grid-auto-rows: minmax(80px, auto)`: toda linha com pelo menos 80 de altura, e mais alta se o conteúdo precisar:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Implicit grid · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: minmax(80px, auto);
        gap: 10px;
        margin-bottom: 20px;
      }
      .shelf > * { background: #f4f1ea; }
      .wide { grid-column: span 2; }
      .dense { grid-auto-flow: dense; }
    </style>
  </head>
  <body>
    <div class="shelf sparse">
      <article class="a wide">A, wide</article>
      <article class="b wide">B, wide</article>
      <article class="c">C</article>
      <article class="d">D, with a description long enough to need several lines in a column two hundred pixels wide, which makes its row grow.</article>
    </div>
    <div class="shelf dense">
      <article class="a wide">A, wide</article>
      <article class="b wide">B, wide</article>
      <article class="c">C</article>
      <article class="d">D</article>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe implicit.html style .sparse grid-template-rows box '.sparse > *'
div.shelf.sparse  grid-template-rows: 80px 80px 120px
article.a.wide  x 0      y 0      width 410    height 80
article.b.wide  x 0      y 90     width 410    height 80
article.c       x 420    y 90     width 200    height 80
article.d       x 0      y 180    width 200    height 120
```

São três linhas, **80, 80 e 120**, todas implícitas: a terceira cresceu para 120 porque a descrição de D precisou, enquanto as duas primeiras ficaram no mínimo. `minmax(80px, auto)` é o valor usual para linhas de cartões: um piso que mantém o grid regular, e espaço para o cartão que tem mais a dizer.

## O buraco, e o `dense`

Leia as posições. A tem duas colunas de largura e fica na linha 1. B também tem duas colunas, e só sobra uma coluna na linha 1, então B vai para a linha 2. **A célula do fim da linha 1 fica vazia**: C, que caberia ali, vem depois de B no HTML, e o navegador põe os itens em ordem, sem nunca voltar. Esse buraco é o padrão, `grid-auto-flow: row`.

A segunda prateleira da página é igual, com **`grid-auto-flow: dense`**:

```
ana@laptop:~/site$ probe implicit.html box '.dense > *'
article.a.wide  x 0      y 320    width 410    height 80
article.b.wide  x 0      y 410    width 410    height 80
article.c       x 420    y 320    width 200    height 80
article.d       x 420    y 410    width 200    height 80
```

Agora **C está no fim da linha 1**, em y 320, no buraco, e D no fim da linha 2. O navegador voltou e preencheu cada buraco com o primeiro item posterior que cabe. É a ferramenta certa para uma galeria de imagens de tamanhos misturados em que a ordem não importa. Onde a ordem importa, ele rearruma o que o leitor vê sem mudar o que ele ouve ou percorre com Tab, que é a seção 10.

`grid-auto-flow: column` preenche colunas primeiro em vez de linhas, acrescentando colunas implícitas pelo caminho, o que serve a uma lista curta que deve descer e depois atravessar.
