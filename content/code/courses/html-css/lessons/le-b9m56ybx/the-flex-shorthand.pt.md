---
title: A forma abreviada flex
version: 2
---

As três propriedades quase sempre são definidas juntas, com **`flex`**, e três valores dela cobrem quase tudo:

| forma abreviada | quer dizer | faz |
| --- | --- | --- |
| `flex: 1` | `1 1 0%` | cresce a partir de zero: os itens dividem todo o espaço igualmente |
| `flex: auto` | `1 1 auto` | cresce a partir do conteúdo: conteúdo maior, item maior |
| `flex: none` | `0 0 auto` | fica do tamanho do conteúdo, nem cresce nem encolhe |

A primeira linha é a que vale ler duas vezes. Aqui estão as três nos mesmos três nomes de estante, em `shorthand.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>flex · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .row { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .row p { margin: 0; background: #2f6f4e; color: white; }
      .one p { flex: 1; }
      .auto p { flex: auto; }
      .none p { flex: none; }
    </style>
  </head>
  <body>
    <div class="row one"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
    <div class="row auto"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
    <div class="row none"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
  </body>
</html>
```

O navegador confirma o que `flex: 1` quer dizer:

```
ana@laptop:~/site$ probe shorthand.html style '.one p:first-child' flex-grow,flex-shrink,flex-basis
p  flex-grow: 1
p  flex-shrink: 1
p  flex-basis: 0%
ana@laptop:~/site$ probe shorthand.html box '.one p' box '.auto p' box '.none p'
p  x 0      y 0      width 200    height 24
p  x 200    y 0      width 200    height 24
p  x 400    y 0      width 200    height 24
p  x 0      y 32     width 160.86 height 24
p  x 160.86 y 32     width 264.92 height 24
p  x 425.78 y 32     width 174.2  height 24
p  x 0      y 64     width 46.25  height 24
p  x 46.25  y 64     width 150.31 height 24
p  x 196.56 y 64     width 59.59  height 24
```

`flex: 1` define a base como **0%**, não como `auto`. Depois vêm as três fileiras da mesma página, três itens cada com rótulos de tamanhos diferentes: *Poetry*, *Fiction in Portuguese* e *Children*:

- Com **`flex: 1`**, os três itens têm **200, 200 e 200**. Toda base é zero, então os 600 pixels são todos espaço livre, divididos em três partes iguais, e o tamanho do texto deixa de importar.
- Com **`flex: auto`**, têm **160,86, 264,92 e 174,2**. Cada um parte da largura do conteúdo, e a sobra é dividida igualmente por cima, então o rótulo mais longo continua sendo o mais largo.
- Com **`flex: none`**, têm **46,25, 150,31 e 59,59**: exatamente o conteúdo, e o resto da fileira fica vazio.

**`flex: 1` é o das colunas iguais**, e é por isso que é o valor mais comum em folhas de estilo reais. `flex: auto` é para itens que devem preencher uma fileira mantendo as proporções, como as abas de um menu. `flex: none` é para algo que não pode mudar de tamanho, como um ícone ou o preço da seção anterior.

Escrever `flex` em vez das três propriedades longas também é mais seguro: `flex: 1` define as três, enquanto `flex-grow: 1` sozinho deixa a base em `auto`, e é assim que alguém que esperava colunas iguais acaba com a segunda fileira.
