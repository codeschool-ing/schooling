---
title: Colunas, linhas e a unidade fr
version: 1
---

**`grid-template-columns`** lista as colunas, um tamanho por coluna; `grid-template-rows` faz o mesmo para as linhas. Aqui está um grid de três colunas: uma fixa de 200 pixels e duas que dividem o que sobra, a segunda recebendo o dobro da primeira:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Tracks · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .grid {
        display: grid;
        grid-template-columns: 200px 1fr 2fr;
        gap: 16px;
        width: 800px;
      }
      .grid > div { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="grid">
      <div>Filters</div>
      <div>Fiction</div>
      <div>Poetry, essays and everything else on the shelves</div>
      <div>Sort</div>
      <div>12 titles</div>
      <div>31 titles</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe tracks.html box '.grid > div'
div  x 0      y 0      width 200    height 24
div  x 216    y 0      width 189.33 height 24
div  x 421.33 y 0      width 378.67 height 24
div  x 0      y 40     width 200    height 24
div  x 216    y 40     width 189.33 height 24
div  x 421.33 y 40     width 378.67 height 24
```

Os seis itens preenchem as células em ordem, da esquerda para a direita e depois para a linha seguinte. A primeira coluna tem **200** de largura, como está escrito. As outras duas têm **189,33** e **378,67**, e a conta é o sentido inteiro do **`fr`**. O contêiner tem 800 de largura; a coluna fixa leva 200 e os dois vãos levam 32; sobram **568**. Os valores fr somam 3, então 1fr é 568 / 3 = 189,33 e 2fr é o dobro disso, 378,67.

**Um `fr` é uma parte do espaço que sobra depois de tirar tudo o que é fixo**, vãos incluídos. É o `flex: 1` da aula 8 ganhando uma unidade: valores fr iguais são colunas iguais seja qual for o conteúdo, e é para isso que serve `1fr 1fr 1fr`. E como os vãos saem primeiro, três colunas de `1fr` mais dois vãos de 16 sempre cabem exatamente no contêiner, o que porcentagens nunca conseguiram: `33.33%` três vezes mais dois vãos dá mais que 100%.

## Misturando unidades

Um tamanho de trilha pode ser qualquer comprimento, `200px` ou `15rem`; uma porcentagem do contêiner; `fr`; ou uma das palavras-chave de conteúdo da aula 6: `min-content`, `max-content`, `auto`. Colunas `auto` são dimensionadas pelo conteúdo e depois esticadas para preencher o espaço livre se não houver colunas `fr`, o que faz de `auto 1fr` o jeito usual de dizer "uma coluna de rótulo da largura que precisar, e o resto para o conteúdo".

Um grid sem `grid-template-rows` continua tendo linhas: tantas quantas os itens precisarem, cada uma da altura do conteúdo. Essas são linhas **implícitas**, seção 07.
