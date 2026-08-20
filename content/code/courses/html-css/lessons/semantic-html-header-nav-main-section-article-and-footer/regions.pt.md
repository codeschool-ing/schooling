---
title: Os elementos de região
---

Seis elementos cobrem quase toda página:

```html
<body>
  <header>
    <nav>… menu …</nav>
  </header>

  <main>
    <article>
      <h1>Título do texto</h1>
      <section>… um bloco do texto …</section>
    </article>
  </main>

  <footer>… contato, direitos …</footer>
</body>
```

`<main>` é o único que deve aparecer **uma vez só** por página, e é ele que dá ao leitor de tela o atalho "pular para o conteúdo". `<header>` e `<footer>` podem se repetir: um `<article>` pode ter os seus próprios.
