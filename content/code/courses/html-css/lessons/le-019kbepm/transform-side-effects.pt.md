---
title: Duas coisas que um transform também faz
version: 2
---

Um transform faz mais duas coisas que surpreendem as pessoas, e a aula 7 apontou para as duas.

## Vira o bloco de contenção dos descendentes fixos

A seção 06 da aula 7 disse que um elemento `position: fixed` é posicionado em relação à janela. **A não ser que um ancestral tenha um transform**: aí esse ancestral vira o bloco de contenção, e o elemento "fixo" se move com ele. Aqui estão dois avisos idênticos, `position: fixed; bottom: 16px; right: 16px`, um na página e um dentro de um painel com `transform: translateX(0)`, um transform que não move nada. A página é o `fixed.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; }
      .page { height: 2000px; }
      .panel { transform: translateX(0); height: 300px; }
      .toast { position: fixed; bottom: 16px; right: 16px; width: 200px; height: 40px; }
    </style>
  </head>
  <body>
    <div class="page">
      <p class="toast outside">Saved</p>
      <div class="panel">
        <p class="toast inside">Saved</p>
      </div>
    </div>
  </body>
</html>
```

Medidos antes e depois de rolar 600:

```
ana@laptop:~/site$ probe fixed.html box .toast scroll 600 box .toast
p.toast.outside  x 808    y 696    width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
p.toast.outside  x 808    y 1296   width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
```

Antes da rolagem, o aviso de fora está em y **696**, no pé da janela, e o de dentro em y **228**, no pé do painel de 300 pixels. Depois de rolar 600, o aviso de fora está em **1296**: ainda no pé da janela, como o fixed promete. O de dentro continua em **228**, e rolou embora com a página. Um transform em qualquer ancestral, mesmo um que não muda nada visível, faz isso. Quando um cabeçalho fixo ou um modal deixa de ser fixo, procure um transform, um `filter` ou um `will-change: transform` acima dele.

## Cria um contexto de empilhamento

A seção 08 da aula 7 mostrou que um contexto de empilhamento prende o `z-index` de tudo dentro dele. Um transform cria um. Um cartão tem um menu com `z-index: 100`, e o cartão seguinte tem `z-index: 1`. Aqui estão eles no `stack.html`, com o primeiro cartão levantado por um `translateY` de 4 pixels:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card { position: relative; width: 300px; height: 120px; background: #f4f1ea; }
      .lifted { transform: translateY(-4px); }
      .menu { position: absolute; top: 80px; left: 20px; z-index: 100; width: 200px; height: 100px; background: #ffffff; }
      .next { position: relative; z-index: 1; width: 300px; height: 120px; background: #e6dfd0; }
    </style>
  </head>
  <body>
    <div class="card lifted">
      <p>Poetry reading</p>
      <div class="menu">Share · Save · Report</div>
    </div>
    <div class="next">Book swap</div>
  </body>
</html>
```

O `flat.html` é uma cópia com o `lifted` retirado do `class` do primeiro cartão. Com o levantamento, e sem:

```
ana@laptop:~/site$ probe stack.html top 100 140
at 100,140: div.next  "Book swap"
ana@laptop:~/site$ probe flat.html top 100 140
at 100,140: div.menu  "Share · Save · Report"
```

Com o transform, o ponto onde o menu fica por cima do cartão seguinte mostra **o cartão seguinte**: o 100 do menu só vale dentro do contexto de empilhamento do cartão levantado, e esse contexto inteiro é desenhado abaixo de um irmão com `z-index: 1`. Sem o transform, o menu fica por cima. Um efeito de hover que levanta um cartão pode, portanto, esconder o próprio dropdown sob o cartão de baixo, e é por isso que a correção da aula 7 vale aqui também: dê ao cartão aberto um `z-index` maior que o dos irmãos, ou tire o menu de dentro dele.
