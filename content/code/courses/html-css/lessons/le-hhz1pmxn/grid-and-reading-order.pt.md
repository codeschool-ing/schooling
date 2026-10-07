---
title: Posicionamento e a ordem em que se lê
version: 1
---

O Grid consegue pôr qualquer item em qualquer célula, seja qual for o lugar dele no HTML, e o empacotamento `dense` move itens para preencher buracos. Os dois mudam **o que é desenhado onde**. Nenhum dos dois muda **a ordem do documento**, e o foco do teclado e os leitores de tela seguem o documento. Aqui está um conjunto de links de estantes num grid denso:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reading order · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: 80px;
        grid-auto-flow: dense;
        gap: 10px;
      }
      .shelf a { background: #f4f1ea; }
      .wide { grid-column: span 2; }
    </style>
  </head>
  <body>
    <nav class="shelf" aria-label="Shelves">
      <a class="wide" href="fiction.html">Fiction</a>
      <a class="wide" href="poetry.html">Poetry</a>
      <a href="essays.html">Essays</a>
      <a href="children.html">Children</a>
    </nav>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box a tab tab tab tab
a.wide  x 0      y 0      width 410    height 80
a.wide  x 0      y 90     width 410    height 80
a       x 420    y 0      width 200    height 80
a       x 420    y 90     width 200    height 80
focus: a "Fiction"
focus: a "Poetry"
focus: a "Essays"
focus: a "Children"
```

Na tela, a linha 1 diz *Fiction*, *Essays* (x 420, y 0) e a linha 2 diz *Poetry*, *Children*: o empacotamento denso subiu *Essays* para o buraco. **O Tab vai Fiction, Poetry, Essays, Children**, a ordem do HTML: do canto superior esquerdo para a segunda linha, de volta para o canto superior direito, e para baixo de novo. Quem enxerga e usa teclado vê o foco pular de um lado para o outro, e quem usa leitor de tela ouve uma ordem que não bate com o que ninguém vê.

A regra é de novo a da seção 10 da aula 8, e com o Grid ela precisa de mais cuidado, porque o Grid consegue mover coisas muito mais longe do que o `order` jamais move: **escreva o HTML na ordem em que deve ser lido, e use o posicionamento para arrumar essa ordem na tela, não para mudá-la.** Posicionamento que mantém a sequência, como uma barra lateral ao lado do conteúdo em vez de depois dele, está certo. Posicionamento que a inverte, ou empacotamento `dense` em itens cuja ordem significa algo, precisa de outra ordem no HTML ou de outro layout.

Há uma propriedade CSS em desenvolvimento, `reading-flow`, que deixaria a ordem de foco de um grid seguir a ordem visual. Ela ainda não está em todos os navegadores, e a ordem do HTML continua sendo a coisa a acertar.
