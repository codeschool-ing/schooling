---
title: A palavra longa que não encolhe
version: 1
---

Um item flex não encolhe abaixo do seu **tamanho mínimo de conteúdo**: para texto, a largura da palavra mais longa ou do trecho que não pode ser quebrado. É o efeito do `min-width: auto` padrão nos itens flex, e ele existe para que o texto não seja espremido em letras sobrepostas. É também a causa de fileiras que transbordam sem motivo visível. Aqui está uma fileira com um título que cresce para preencher o espaço e um preço de largura fixa, duas vezes:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>min-width · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .row { display: flex; gap: 8px; width: 400px; margin-bottom: 8px; background: #f4f1ea; }
      .title { flex: 1; }
      .price { flex: none; width: 80px; }
      .fixed .title { min-width: 0; overflow-wrap: anywhere; }
    </style>
  </head>
  <body>
    <div class="row">
      <p class="title">grande_sertao_veredas_first_edition_1956.pdf</p>
      <p class="price">R$ 240</p>
    </div>
    <div class="row fixed">
      <p class="title">grande_sertao_veredas_first_edition_1956.pdf</p>
      <p class="price">R$ 240</p>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe minwidth.html box .title box .price spill .row
p.title  x 0      y 16     width 330.91 height 24
p.title  x 0      y 80     width 312    height 48
p.price  x 338.91 y 16     width 80     height 24
p.price  x 320    y 80     width 80     height 48
div.row  content 419 wide in a box 400 wide: it spills
div.row.fixed  content 400 wide in a box 400 wide
```

O título é um nome de arquivo sem espaços nem hifens, que o navegador não consegue quebrar. Na primeira fileira, o título deveria ter 312 de largura, 400 menos o vão de 8 pixels e o preço de 80. **Ele se recusou a ficar abaixo de 330,91**, a largura desse trecho inquebrável, e empurrou o preço para x 338,91, de modo que ele termina em 418,91: **o conteúdo da fileira tem 419 de largura numa caixa de 400**. Numa página de verdade, isso é o preço pendurado para fora do cartão, ou uma página que rola para o lado no celular.

A segunda fileira acrescenta duas declarações ao título: **`min-width: 0`**, que tira o piso e deixa o item encolher até a sua parte, e o `overflow-wrap: anywhere` da aula 6, que deixa o trecho quebrar para caber. O título tem 312 de largura e duas linhas de altura, e a fileira tem exatamente 400.

## Como reconhecê-lo

Uma fileira flex mais larga que o contêiner, em que um item guarda uma URL longa, um nome de arquivo, um trecho de código, uma tabela ou outro contêiner flex com conteúdo longo. A correção é `min-width: 0` no item que deve encolher, mais o que deixar o conteúdo dele lidar com isso: quebra de linha, `overflow: hidden` com `text-overflow: ellipsis`, ou `overflow: auto` para uma tabela. Numa coluna, o mesmo piso vale para a altura, e a correção é `min-height: 0`.
