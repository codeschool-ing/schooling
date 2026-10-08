---
title: Como um controle se chama
version: 2
---

Todo link, botão e campo de formulário tem um **nome acessível**: as palavras que um leitor de tela diz quando chega nele, e as palavras que quem usa controle por voz diz para ativá-lo. A árvore os imprimiu entre aspas: `link "Events"`, `button "Reserve (button)"`. O navegador calcula o nome a partir da marcação, e na maior parte das vezes é só o texto dentro do elemento.

É por isso que o texto dentro de um link importa tanto. Aqui estão três links e duas imagens dentro de links, em `names.html`. Qualquer imagem pequena salva ao lado como `shelf.png` serve:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <p>Poetry reading on Thursday. <a href="poetry.html">Click here</a>.</p>
      <p>Book swap on Saturday. <a href="swap.html">Click here</a>.</p>
      <p><a href="poetry.html">Poetry reading on Thursday</a>.</p>
      <a href="shelf.html"><img src="shelf.png" width="60" height="40"></a>
      <a href="shelf.html"><img src="shelf.png" width="60" height="40" alt="Browse the shelves"></a>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe names.html tree axe
- main:
  - heading "Events" [level=1]
  - paragraph:
    - text: Poetry reading on Thursday.
    - link "Click here":
      - /url: poetry.html
    - text: .
  - paragraph:
    - text: Book swap on Saturday.
    - link "Click here":
      - /url: swap.html
    - text: .
  - paragraph:
    - link "Poetry reading on Thursday":
      - /url: poetry.html
    - text: .
  - link:
    - /url: shelf.html
    - img
  - link "Browse the shelves":
    - /url: shelf.html
    - img "Browse the shelves"
image-alt (critical, 1 element): Images must have alternative text
link-name (serious, 1 element): Links must have discernible text
```

## Clique aqui

Os dois primeiros links se chamam **"Click here"**. Lidos no fluxo do parágrafo fazem sentido; mas quem usa leitor de tela muitas vezes pede a lista de todos os links da página, e essa lista diz *Click here, Click here, Poetry reading on Thursday*. Dois dos três não dizem nada sobre para onde vão. O terceiro link carrega o próprio significado: **escreva as palavras que dizem para onde o link vai, e faça dessas palavras o link.**

## Uma imagem num link

Quando o único conteúdo de um link é uma imagem, o texto do `alt` da imagem vira o nome do link. O primeiro link com imagem não tem `alt`, então o link não tem nome nenhum: a árvore imprime um `link` sem nada, e o axe apontou duas regras para esse único elemento, **image-alt** para a imagem e **link-name** para o link. O segundo tem `alt="Browse the shelves"`, e o link é nomeado por ele. A aula 4 trata de `alt` em geral; dentro de um link, a regra é que o `alt` descreve **para onde o link vai**, não o que a foto mostra.

## Quando não há texto visível

Às vezes um controle não tem palavra nenhuma: uma lupa para a busca, um xis que fecha um diálogo. Aí ele precisa de um nome vindo de um atributo: `aria-label="Search"` dá um diretamente, e `aria-labelledby` aponta para o `id` de um elemento cujo texto deve ser usado, como as sections da seção 05 fizeram com os títulos. Use-os onde não há texto visível para nomear o controle, e não para sobrescrever um texto que existe: um botão que mostra *Reserve* e se chama *Book now* pelo `aria-label` diz uma coisa ao olho e outra ao ouvido, e quem usa controle por voz e diz "clicar Reserve" não chega a lugar nenhum.
