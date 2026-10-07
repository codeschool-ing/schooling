---
title: fixed: preso à janela
version: 1
---

**`position: fixed`** tira a caixa do fluxo como o `absolute`, e a mede a partir **da janela** em vez de um elemento. Enquanto a página rola, a caixa fica onde está na tela. O sebo tem um link *Ask us* no canto inferior direito:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Fixed and sticky · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .chat {
        position: fixed;
        right: 16px;
        bottom: 16px;
        padding: 8px 16px;
        background: #2f6f4e;
        color: white;
      }
      .month h2 {
        position: sticky;
        top: 0;
        margin: 0;
        padding: 8px;
        background: #f4f1ea;
      }
      .month { height: 900px; }
    </style>
  </head>
  <body>
    <section class="month" id="october">
      <h2>October</h2>
      <p>Poetry reading, book swap and a bookbinding class.</p>
    </section>
    <section class="month" id="november">
      <h2>November</h2>
      <p>Nothing is planned yet.</p>
    </section>
    <a class="chat" href="contact.html">Ask us</a>
  </body>
</html>
```

```
ana@laptop:~/site$ probe fixed.html box .chat
a.chat  x 927.98 y 712    width 80.02  height 40
ana@laptop:~/site$ probe fixed.html scroll 500 box .chat
a.chat  x 927.98 y 1212   width 80.02  height 40
```

`probe box` imprime posições em coordenadas da página. Antes de rolar, o link está em y 712; depois de rolar 500 pixels, está em **y 1212**, exatamente 500 mais abaixo na página, o que quer dizer que ele não se mexeu na tela: 16 pixels acima do pé de uma janela de 768 pixels, como `bottom: 16px` diz.

## O que o fixed custa

Uma caixa fixa cobre o que rolar por baixo dela, **o tempo todo**. No celular, em que uma tela pequena é tudo o que existe, um cabeçalho fixo e um botão de chat fixo podem tirar um quinto da tela do conteúdo durante a visita inteira. Mantenha os elementos fixos pequenos, e pergunte se eles precisam estar na tela permanentemente.

Mais duas consequências. **O conteúdo pode rolar por baixo e ficar escondido**: a última linha da página fica atrás do link *Ask us*, a não ser que a página deixe espaço para ele, o que um `padding-bottom` no body faz. **E um link para uma âncora rola o alvo para baixo de um cabeçalho fixo**, e o título para o qual você pulou fica escondido. `scroll-padding-top` no elemento `<html>`, com a altura do cabeçalho, diz ao navegador para parar antes; a seção 10 usa isso.

Pela WCAG, conteúdo que fica na tela não pode cobrir o elemento que está com o foco do teclado: uma barra fixa que esconde o link que alguém acabou de alcançar com Tab reprova o critério 2.4.11, *Focus Not Obscured*.
