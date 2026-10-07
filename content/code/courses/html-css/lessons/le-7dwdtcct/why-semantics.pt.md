---
title: Duas páginas que parecem iguais
version: 2
---

**HTML semântico** quer dizer escolher cada elemento pelo que o conteúdo é, para que a marcação diga o significado em voz alta. O contrário também tem nome, **sopa de divs** (*div soup*): uma página feita de elementos `<div>` com nomes de classe, em que o significado mora nos nomes de classe e no CSS, e o HTML não diz nada.

Aqui está a página inicial do sebo escrita como sopa de divs:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="soup.css">
  </head>
  <body>
    <div class="top">
      <div class="logo">Andorinha Books</div>
      <div class="menu">
        <div class="item"><a href="events.html">Events</a></div>
        <div class="item"><a href="order.html">Order a book</a></div>
        <div class="item"><a href="hours.html">Opening hours</a></div>
      </div>
    </div>
    <div class="content">
      <div class="title">This week</div>
      <div class="event">
        <div class="event-title">Poetry reading: Hilda Hilst</div>
        <div>Thursday 8 October, 7 pm. Free entry.</div>
      </div>
      <div class="event">
        <div class="event-title">Book swap</div>
        <div>Saturday 10 October, from 10 am.</div>
      </div>
    </div>
    <div class="bottom">Rua dos Pinheiros, 1000 · São Paulo</div>
  </body>
</html>
```

Com umas poucas linhas de CSS para o negrito e os tamanhos, o `soup.css`, ela parece uma página perfeitamente razoável:

```css
.logo { font-size: 2em; font-weight: bold; }
.title { font-size: 1.5em; font-weight: bold; margin: 0.8em 0; }
.event-title { font-weight: bold; }
.event { margin-bottom: 1em; }
```

Agora o mesmo conteúdo, com cada parte no elemento que diz o que ela é:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
  </head>
  <body>
    <header>
      <p class="logo">Andorinha Books</p>
      <nav aria-label="Main">
        <ul>
          <li><a href="events.html">Events</a></li>
          <li><a href="order.html">Order a book</a></li>
          <li><a href="hours.html">Opening hours</a></li>
        </ul>
      </nav>
    </header>
    <main>
      <h1>This week</h1>
      <article>
        <h2>Poetry reading: Hilda Hilst</h2>
        <p><time datetime="2026-10-08T19:00">Thursday 8 October, 7 pm</time>. Free entry.</p>
      </article>
      <article>
        <h2>Book swap</h2>
        <p><time datetime="2026-10-10T10:00">Saturday 10 October, from 10 am</time>.</p>
      </article>
    </main>
    <footer>
      <address>Rua dos Pinheiros, 1000 · São Paulo</address>
    </footer>
  </body>
</html>
```

Abra as duas e você vê a mesma imagem. A diferença está no que o navegador entrega a todo o resto que lê a página. A seção 07 da aula 1 apresentou a **árvore de acessibilidade**, a versão da página que leitores de tela e outras tecnologias assistivas usam, e `probe tree` a imprime. Para a sopa:

```
ana@laptop:~/site$ probe soup.html tree
- text: Andorinha Books
- link "Events":
  - /url: events.html
- link "Order a book":
  - /url: order.html
- link "Opening hours":
  - /url: hours.html
- text: "This week Poetry reading: Hilda Hilst Thursday 8 October, 7 pm. Free entry. Book swap Saturday 10 October, from 10 am. Rua dos Pinheiros, 1000 · São Paulo"
```

Três links sobrevivem, porque `<a>` é link seja lá o que estiver em volta. Todo o resto virou uma linha só de texto: o título, os dois eventos e o endereço, sem nada que diga onde um termina e o outro começa. Para a versão semântica:

```
ana@laptop:~/site$ probe semantic.html tree
- banner:
  - paragraph: Andorinha Books
  - navigation "Main":
    - list:
      - listitem:
        - link "Events":
          - /url: events.html
      - listitem:
        - link "Order a book":
          - /url: order.html
      - listitem:
        - link "Opening hours":
          - /url: hours.html
- main:
  - heading "This week" [level=1]
  - article:
    - 'heading "Poetry reading: Hilda Hilst" [level=2]'
    - paragraph:
      - time: Thursday 8 October, 7 pm
      - text: . Free entry.
  - article:
    - heading "Book swap" [level=2]
    - paragraph:
      - time: Saturday 10 October, from 10 am
      - text: .
- contentinfo: Rua dos Pinheiros, 1000 · São Paulo
```

Agora há um **banner** com o nome do site e a sua **navigation**, chamada *Main*, com uma lista de três links. Há o **main**, com um título de nível 1 e dois **articles**, cada um com o seu título de nível 2. As datas estão marcadas como **time**, e o endereço fica em **contentinfo**. Cada uma dessas palavras vem de um elemento; nenhuma foi escrita como atributo.

## O que quem lê essa árvore consegue fazer

Quem usa leitor de tela não escuta uma página de cima a baixo, assim como você não a lê desse jeito. A pessoa passa os olhos: pede a lista de títulos e pula para um, vai direto ao conteúdo principal ou anda de um landmark para o próximo. Na página semântica isso funciona. Na sopa há uma coisa com cara de título na imagem e nenhuma na árvore, então não há por onde passar os olhos.

A sopa também cobra de quem enxerga. Um buscador pesa os títulos quando decide do que uma página trata; o modo de leitura do navegador usa `<main>` e `<article>` para decidir o que manter; e a próxima pessoa que abrir o arquivo tem de ler o CSS para descobrir que `.title` é um título. **HTML semântico não é trabalho extra acrescentado por acessibilidade.** É o mesmo número de elementos, escolhidos de outro jeito, e o resto desta aula é como escolhê-los.
