---
title: Unidades de viewport
version: 2
---

Quatro unidades medem a janela do navegador, o **viewport**, e não um elemento: **`vw`** é um por cento da largura dela, **`vh`** um por cento da altura, e `vmin` e `vmax` são um por cento da menor ou da maior das duas. Uma seção que deve preencher a primeira tela é `min-height: 100vh`.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Viewport units · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .hero { height: 100vh; width: 100vw; }
      .tall { height: 2000px; }
    </style>
  </head>
  <body>
    <div class="hero"></div>
    <div class="tall"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe viewport.html window box .hero
window: 1024×768, device pixel ratio 1
div.hero  x 0      y 0      width 1024   height 768
ana@laptop:~/site$ probe --mobile --width 390 --height 844 viewport.html window box .hero
window: 390×844, device pixel ratio 1
div.hero  x 0      y 0      width 390    height 844
```

Numa janela de 1024 por 768, `100vw` por `100vh` dá 1024 por 768. Num celular de 390 de largura por 844 de altura, com a tag viewport da aula 1, dá 390 por 844. Sem essa tag, a aula 1 mostrou, o celular finge ter 980 de largura, e `100vw` seria 980.

## A barra do celular

No celular, a barra de endereços do navegador some quando o leitor rola para baixo e volta quando rola para cima, então a altura visível muda enquanto ele lê. `100vh` foi definido como a **maior** dessas alturas, então uma seção de `100vh` fica mais alta que a tela enquanto a barra aparece, e o pé dela fica escondido embaixo da barra. Três unidades mais novas dizem a que altura se referem: **`svh`**, o viewport pequeno, com as barras à mostra; **`lvh`**, o grande, com elas escondidas; e **`dvh`**, o dinâmico, que acompanha a barra enquanto ela se move. `min-height: 100svh` é a escolha segura para uma primeira tela que precisa caber. O Chromium sem interface de onde vêm estas medições não tem barra de endereços para sumir, então não consegue mostrar a diferença; num celular de verdade as unidades diferem pela altura da barra.

## A barra de rolagem

Num desktop com barras de rolagem clássicas, `100vw` inclui a largura da barra de rolagem vertical, então um elemento com `width: 100vw` fica alguns pixels mais largo que a página e a faz rolar para o lado. O Chromium sem interface de onde vêm estas medições não desenha barra de rolagem, então a medição acima não consegue mostrar isso, e você vai ver no Windows e na maioria dos desktops Linux. **`width: 100%` é o que se usa para "a largura inteira da página"**; deixe `vw` para coisas que são de fato uma fração da janela, como um título cujo tamanho cresce com ela, que a aula 11 constrói com `clamp()`.
