---
title: Limites, transbordamento e manter uma forma
version: 1
---

Uma caixa que precisa funcionar em qualquer largura precisa de limites em vez de um tamanho fixo, e de uma regra para quando o conteúdo não cabe. Aqui estão quatro caixas, cada uma mostrando uma dessas coisas:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sizes · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card { max-width: 400px; padding: 16px; box-sizing: border-box; }
      .link { width: 240px; }
      .wraps { overflow-wrap: anywhere; }
      .poster { width: 300px; aspect-ratio: 16 / 9; }
    </style>
  </head>
  <body>
    <article class="card">Poetry reading: Hilda Hilst</article>
    <p class="link">https://andorinha.example/events/2026/october/poetry-reading</p>
    <p class="link wraps">https://andorinha.example/events/2026/october/poetry-reading</p>
    <div class="poster"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe sizes.html box .card spill .link box .link box .poster
article.card  x 0      y 0      width 400    height 50
p.link  content 351 wide in a box 240 wide: it spills
p.link.wraps  content 240 wide in a box 240 wide
p.link        x 0      y 66     width 240    height 36
p.link.wraps  x 0      y 118    width 240    height 36
div.poster  x 0      y 170    width 300    height 168.75
ana@laptop:~/site$ probe --width 320 sizes.html box .card
article.card  x 0      y 0      width 320    height 50
```

## `max-width` em vez de `width`

O cartão diz `max-width: 400px` e nenhum `width`. Na janela de 1024 ele tem **400**; numa janela de 320 tem **320**, a largura inteira disponível. `width: 400px` o teria deixado com 400 também na janela estreita, mais largo que a tela. **`max-width` é o hábito para tudo o que não deve passar de um tamanho e deve ficar menor quando precisar**, e `min-width` é o espelho dele. A aula 11 monta layouts responsivos exatamente sobre isso.

## Transbordamento

O primeiro parágrafo de link tem 240 de largura e guarda um endereço sem espaços. **O conteúdo tem 351 de largura numa caixa de 240: ele transborda.** O navegador quebra linhas em espaços e em alguns caracteres como barras e hifens, e um trecho comprido o bastante sem oportunidade de quebra é desenhado para além da borda da caixa, por cima do que estiver ao lado. O segundo parágrafo acrescenta `overflow-wrap: anywhere`, que permite quebrar entre quaisquer dois caracteres quando nada mais cabe, e o conteúdo dele tem exatamente 240.

Quando o conteúdo é maior que a caixa, a propriedade **`overflow`** diz o que fazer: `visible`, o padrão, desenha por fora; `hidden` corta; `auto` acrescenta uma barra de rolagem só se precisar; `scroll` sempre acrescenta uma. `overflow: auto` é a resposta certa para uma tabela larga no celular, em que a tabela rola dentro da caixa e a página não. `hidden` é o perigoso, porque conteúdo cortado é conteúdo que ninguém alcança.

## Mantendo uma forma: `aspect-ratio`

A última caixa diz `width: 300px; aspect-ratio: 16 / 9` e nenhuma altura. Ela tem **168,75** de altura, que é 300 × 9 / 16. É a promessa da aula 4: `aspect-ratio` dá a qualquer caixa a proporção que `width` e `height` dão a uma imagem, para que a moldura de um vídeo, um mapa ou a área de imagem de um cartão mantenham a forma em qualquer largura, sem o truque do padding da seção 09.

## Tamanhos baseados no conteúdo

Três palavras-chave dimensionam uma caixa pelo conteúdo: **`min-content`**, tão estreita quanto o conteúdo consegue ficar sem transbordar, o que para texto é a palavra mais longa; **`max-content`**, tão larga quanto o conteúdo quer numa linha só; e **`fit-content`**, que é `max-content` mas nunca mais larga que o espaço disponível. `width: fit-content` faz uma caixa abraçar o texto, que é como se dimensiona um rótulo ou um selo. O Grid, aula 9, usa as três como tamanhos de trilha.
