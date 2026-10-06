---
title: Imagens que esperam até serem necessárias
version: 1
---

Uma página longa com trinta fotos não precisa das trinta antes de o leitor ter visto a primeira. **`loading="lazy"`** diz ao navegador que ele pode esperar para buscar uma imagem até o leitor rolar perto dela. Aqui está uma página com três seções altas e uma imagem em cada, a primeira carregada normalmente e as outras duas de forma preguiçosa:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shelves · Andorinha Books</title>
    <style>
      section { min-height: 4000px; }
    </style>
  </head>
  <body>
    <main>
      <h1>The shelves, one by one</h1>
      <section>
        <h2>Fiction</h2>
        <img src="shelves-480.png" width="480" height="320" alt="The fiction shelves">
      </section>
      <section>
        <h2>Poetry</h2>
        <img src="shelves-960.png" width="480" height="320" alt="The poetry corner" loading="lazy">
      </section>
      <section>
        <h2>Children</h2>
        <img src="shelves-1600.png" width="480" height="320" alt="The children's corner" loading="lazy">
      </section>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe lazy.html fetched box img
shelves-480.png
img  x 8      y 126.78 width 480    height 320
img  x 8      y 4146.69 width 480    height 320
img  x 8      y 8166.59 width 480    height 320
ana@laptop:~/site$ probe lazy.html scroll 2000 fetched
shelves-480.png
shelves-960.png
ana@laptop:~/site$ probe lazy.html scroll 6000 fetched
shelves-480.png
shelves-960.png
shelves-1600.png
```

No topo da página, só a primeira imagem foi buscada; as outras ficam em y 4146,69 e 8166,59, muito abaixo da janela de 768 pixels. Rolando até 2000, a segunda foi buscada, quando o topo dela ainda estava **uns 1400 pixels abaixo do fim da janela**: o navegador começa cedo para a imagem estar lá quando o leitor chegar. Em 6000, a terceira.

## A regra única

**Nunca carregue preguiçosamente as imagens do topo da página.** O navegador não sabe se uma imagem está visível até montar a página, então uma imagem preguiçosa perto do topo começa mais tarde do que começaria, e a imagem mais importante da página, a primeira que o leitor vê, chega por último. É por isso que a primeira imagem desta página não tem atributo `loading`. Preguiçoso é para o que está abaixo da primeira tela, e sobretudo para o que está bem abaixo.

O carregamento preguiçoso é mais um motivo para `width` e `height`. Uma imagem preguiçosa chega enquanto alguém está lendo, por definição, e sem o tamanho reservado cada uma delas é um deslocamento de layout.

`<iframe>`, o elemento que põe outra página dentro desta, como um mapa incorporado, aceita o mesmo atributo e ganha ainda mais com ele, porque um iframe é uma página inteira.
