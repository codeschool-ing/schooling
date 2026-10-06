---
title: Section e article
version: 1
---

Dois elementos agrupam conteúdo dentro do `<main>`, e a diferença entre eles é a pergunta a fazer antes de usar qualquer um.

**`<article>` é conteúdo que faria sentido sozinho**, tirado da página: um post de blog, uma notícia, o cartão de um produto, um comentário, a ficha de um evento. O teste é se você poderia pô-lo num feed, num e-mail ou em outra página e ele continuaria completo. Cada evento das páginas do sebo é um article.

**`<section>` é uma parte de algo maior**: um grupo temático de conteúdo que apareceria no esboço, e é por isso que deve ter um título. Os meses da página de eventos são sections: *October* não é uma coisa em si, é uma parte da lista de eventos.

Aqui estão os dois juntos, com um article dentro de uma section e um header e um footer dentro do article:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
  </head>
  <body>
    <header>
      <p>Andorinha Books</p>
    </header>
    <main>
      <h1>Events</h1>
      <section aria-labelledby="october">
        <h2 id="october">October</h2>
        <article>
          <header>
            <h3>Poetry reading: Hilda Hilst</h3>
            <p><time datetime="2026-10-08T19:00">8 October, 7 pm</time></p>
          </header>
          <p>Three readers, one hour, and a glass of wine afterwards.</p>
          <footer>Free entry. No booking needed.</footer>
        </article>
      </section>
      <section aria-labelledby="november">
        <h2 id="november">November</h2>
        <p>Nothing is planned yet.</p>
      </section>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe sections.html tree
- banner:
  - paragraph: Andorinha Books
- main:
  - heading "Events" [level=1]
  - region "October":
    - heading "October" [level=2]
    - article:
      - 'heading "Poetry reading: Hilda Hilst" [level=3]'
      - paragraph:
        - time: 8 October, 7 pm
      - paragraph: Three readers, one hour, and a glass of wine afterwards.
      - text: Free entry. No booking needed.
  - region "November":
    - heading "November" [level=2]
    - paragraph: Nothing is planned yet.
```

Três coisas nessa árvore valem uma leitura lenta.

**O `<header>` da página virou banner, e o do artigo não.** O `<header>` dentro do artigo é só um grupo com o título do artigo e a data. O `<footer>` dele é igual: *Free entry. No booking needed.* é texto comum, não um landmark contentinfo. A regra da seção anterior, tornada visível.

**As sections viraram regions só porque têm nome.** `aria-labelledby="october"` aponta para o `id` do título, então a section é nomeada pelo próprio título, e a árvore a chama de *region "October"*. Sem nome, uma `<section>` não tem papel nenhum na árvore e é só um grupo, o que está tudo bem; ela então serve ao esboço só pelo título.

**Os títulos acompanham o aninhamento.** O `<h1>` da página é *Events*, cada section abre com um `<h2>` e o artigo dentro de uma section tem um `<h3>`. Nada nos elementos faz isso por você: você escolhe cada nível pelo lugar dele, como a seção 03 disse.

## Quando não usar nenhum dos dois

Se você está agrupando coisas só para o CSS encontrá-las, dois cartões numa linha, por exemplo, o elemento é `<div>`, que não diz nada e está certo justamente porque não há nada a dizer. A seção 10 trata disso. **Uma `<section>` sem título costuma ser uma `<div>` que ganhou um nome mais importante.**
