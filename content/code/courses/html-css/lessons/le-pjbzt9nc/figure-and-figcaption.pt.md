---
title: Figure e figcaption
version: 1
---

Algumas imagens andam com uma legenda: uma foto com uma linha sobre quando foi tirada, um gráfico com a fonte, um diagrama com o que ele mostra. **`<figure>` agrupa um conteúdo com a sua legenda, e `<figcaption>` é a legenda.**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>The shop</h1>
      <p>The fiction shelves run the length of the front room.</p>
      <figure>
        <img src="shelves-480.png" width="480" height="320"
             alt="Floor-to-ceiling shelves of paperbacks, with a ladder on a rail">
        <figcaption>The front room in 2026, after the new shelves went in.</figcaption>
      </figure>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe figure.html tree
- main:
  - heading "The shop" [level=1]
  - paragraph: The fiction shelves run the length of the front room.
  - figure "The front room in 2026, after the new shelves went in.":
    - img "Floor-to-ceiling shelves of paperbacks, with a ladder on a rail"
    - text: The front room in 2026, after the new shelves went in.
```

A árvore criou uma **figure** nomeada pela legenda, com a imagem e o texto da legenda dentro. O `alt` e a legenda são textos diferentes com trabalhos diferentes: **o `alt` substitui a imagem, a legenda acrescenta a ela**. *Floor-to-ceiling shelves of paperbacks, with a ladder on a rail* é o que alguém que não vê a imagem perderia; *The front room in 2026, after the new shelves went in* é o que todos leem, enxergando ou não. Se a legenda já descreve tudo o que a imagem mostra, a imagem pode ter `alt=""` e deixar a descrição para a legenda, para não ser ouvida duas vezes.

## Não só imagens

Uma figure é qualquer conteúdo autônomo a que o texto se refere: uma listagem de código, uma citação, uma tabela, um vídeo, um diagrama. O teste é o mesmo do article na aula 2, numa escala menor: o texto em volta se refere a ela, e ela poderia ir para um apêndice sem quebrar esse texto. Uma imagem que faz parte da frase, como um ícone ao lado de uma palavra, não é uma figure.
