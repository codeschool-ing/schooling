---
title: inset, e uma caixa centralizada sobre a página
version: 1
---

**`inset`** é a forma abreviada das quatro propriedades de inset, na mesma ordem horária da `margin`: `inset: 0` é `top: 0; right: 0; bottom: 0; left: 0`, e `inset: 10px 20px` é 10 em cima e embaixo e 20 dos lados.

Definir **insets opostos** na mesma caixa faz algo útil: uma caixa absoluta ou fixa com `left: 0; right: 0` e sem largura se estica entre eles, e uma com `inset: 0` preenche o bloco de contenção inteiro. É assim que se faz uma camada que cobre a janela toda:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Overlay · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .overlay {
        position: fixed;
        inset: 0;
        background: rgb(0 0 0 / 0.5);
      }
      .notice {
        position: absolute;
        inset: 0;
        margin: auto;
        width: 300px;
        height: 200px;
        padding: 16px;
        box-sizing: border-box;
        background: white;
      }
    </style>
  </head>
  <body>
    <main><h1>Events</h1></main>
    <div class="overlay">
      <div class="notice">
        <p>The shop is closed on 12 October for a public holiday.</p>
      </div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe overlay.html box .overlay box .notice
div.overlay  x 0      y 0      width 1024   height 768
div.notice  x 362    y 284    width 300    height 200
ana@laptop:~/site$ probe --width 390 --height 844 overlay.html box .notice
div.notice  x 45     y 322    width 300    height 200
```

A camada tem **1024 por 768**, a janela inteira, por causa de `position: fixed; inset: 0` e nenhum tamanho. Dentro dela o aviso está centralizado, e a técnica vale uma leitura atenta: `position: absolute; inset: 0` diz "estique até as quatro bordas", um `width` e um `height` fixos dizem "mas deste tamanho", e **`margin: auto`** divide o espaço que sobra igualmente nos quatro lados, o vertical também, o que o fluxo normal nunca faz. O aviso está em **x 362, y 284**, que é (1024 − 300) / 2 e (768 − 200) / 2. Numa janela de 390 por 844 ele está em x 45, y 322: centralizado de novo, sem mudança no CSS.

A aula 8 centraliza coisas num contêiner de um jeito mais simples, com Flexbox. Esta técnica é para uma caixa posta por cima de tudo, em que não há contêiner onde centralizá-la.

## Uma camada que é um diálogo

Um aviso com que o leitor precisa lidar antes de continuar é um **diálogo**, e o HTML tem um elemento para isso, `<dialog>`, que traz o que este CSS não traz: o navegador põe o foco dentro dele, mantém o Tab lá dentro, fecha com Escape e torna a página de trás inerte. O pseudo-elemento `::backdrop` dele é a camada escurecida, então até a camada já vem pronta. Abri-lo precisa de uma linha de JavaScript, `showModal()`, que cabe ao curso `javascript` ensinar. Para qualquer coisa que interrompa o leitor, use o elemento; o CSS acima é a forma que ele desenha.
