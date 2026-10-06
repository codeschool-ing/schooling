---
title: Ordem visual e ordem de leitura
version: 1
---

O Flexbox consegue mudar a ordem em que os itens são desenhados sem mudar o HTML. **`order`** num item o move: os itens são desenhados em ordem crescente de `order`, que por padrão é 0, então `order: -1` põe um item primeiro e `order: 1` por último. `row-reverse` e `column-reverse` desenham o conjunto inteiro de trás para frente. Isso é útil e tem um custo. Aqui está um conjunto de links de um livro, com o mais importante movido para a frente pelo CSS:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Order · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .actions { display: flex; gap: 8px; }
      .actions a { padding: 8px 16px; background: #f4f1ea; }
      .actions .primary { order: -1; background: #2f6f4e; color: white; }
    </style>
  </head>
  <body>
    <nav class="actions" aria-label="Book">
      <a href="details.html">Details</a>
      <a href="reviews.html">Reviews</a>
      <a href="order.html" class="primary">Order this book</a>
    </nav>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box a tab tab tab
a          x 149.39 y 0      width 80.91  height 40
a          x 238.3  y 0      width 92.47  height 40
a.primary  x 0      y 0      width 141.39 height 40
focus: a "Details"
focus: a "Reviews"
focus: a "Order this book"
```

Na tela, *Order this book* vem primeiro, em **x 0**, com *Details* e *Reviews* depois. Mas **o Tab foi primeiro para *Details***, depois *Reviews*, depois *Order this book*: o foco do teclado segue o HTML, não o desenho. Quem enxerga e usa teclado vê o anel de foco pular do meio da fileira para a direita e depois voltar para a esquerda. Um leitor de tela também os lê na ordem do HTML, então quem o usa ouve uma sequência diferente da que todo mundo vê.

## A regra

A WCAG pede que, quando a ordem do conteúdo importa para o significado, a ordem de leitura a acompanhe (1.3.2, *Meaningful Sequence*), e que o foco se mova numa ordem que preserve significado e operabilidade (2.4.3, *Focus Order*). A regra prática é curta: **se algo deve vir primeiro, ponha-o primeiro no HTML**. Use `order` e as direções invertidas só para rearrumar coisas cuja ordem não importa a ninguém, como decoração, ou para um ajuste visual que mantém a mesma sequência. A aula 9 encontra a mesma regra no Grid, que consegue mover itens muito mais longe.
