---
title: Quando os itens não cabem: quebra de linha
version: 1
---

Por padrão um contêiner flex mantém todos os itens numa **linha só**, quantos forem, e os encolhe para caber se puder. Isso está certo para um menu de quatro links e errado para uma grade de trinta capas de livro, que deviam correr por quantas linhas precisarem. **`flex-wrap: wrap`** deixa:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Covers · Andorinha Books</title>
    <style>
      .covers { display: flex; flex-wrap: wrap; gap: 16px; }
    </style>
  </head>
  <body>
    <div class="covers">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
    </div>
  </body>
</html>
```

Oito capas de 120 pixels de largura, com 16 pixels entre elas, numa janela de 1024 de largura e depois numa de 390:

```
ana@laptop:~/site$ probe covers.html box img
img  x 8      y 8      width 120    height 180
img  x 144    y 8      width 120    height 180
img  x 280    y 8      width 120    height 180
img  x 416    y 8      width 120    height 180
img  x 552    y 8      width 120    height 180
img  x 688    y 8      width 120    height 180
img  x 824    y 8      width 120    height 180
img  x 8      y 204    width 120    height 180
ana@laptop:~/site$ probe --width 390 covers.html box img
img  x 8      y 8      width 120    height 180
img  x 144    y 8      width 120    height 180
img  x 8      y 204    width 120    height 180
img  x 144    y 204    width 120    height 180
img  x 8      y 400    width 120    height 180
img  x 144    y 400    width 120    height 180
img  x 8      y 596    width 120    height 180
img  x 144    y 596    width 120    height 180
```

Com `wrap`, os itens que não cabem na linha vão para uma nova embaixo, como as palavras num parágrafo. Na janela larga, **sete capas cabem na primeira linha**, em y 8, e a oitava começa uma segunda linha em y 204: sete capas e seis vãos dão 936 pixels, e uma oitava precisaria de 1072 dos 1008 disponíveis. No celular são **duas por linha**, quatro linhas até y 596. Nenhuma media query entrou nisso, e a aula 11 vai se apoiar nisso: um layout que se adapta sozinho é um para o qual você nunca precisa escrever pontos de quebra.

## Cada linha é montada por conta própria

Quando um contêiner flex quebra, **cada linha é uma fileira separada** no que diz respeito ao eixo principal: `justify-content` espalha os itens de cada linha de forma independente, então uma última linha com duas capas é montada como duas capas, não alinhada às colunas de cima. Se você precisa que os itens de todas as linhas se alinhem em colunas, isso é uma grade, aula 9, e essa diferença é o jeito mais confiável de escolher entre os dois: **Flexbox monta coisas em uma dimensão, uma linha, e Grid em duas, linhas e colunas ao mesmo tempo.**

Com várias linhas existe mais uma propriedade, **`align-content`**, que posiciona as próprias linhas no eixo cruzado quando o contêiner é mais alto do que elas precisam: juntas em cima, espalhadas, centralizadas. Num contêiner de uma linha só ela não faz nada, que é o motivo usual de parecer não funcionar.

## A forma abreviada

`flex-flow` junta as duas: `flex-flow: row wrap` é `flex-direction: row; flex-wrap: wrap`. É comum em código mais antigo e economiza uma linha.
