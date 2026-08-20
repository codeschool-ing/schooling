---
title: The region elements
---

Six elements cover almost any page:

```html
<body>
  <header>
    <nav>… menu …</nav>
  </header>

  <main>
    <article>
      <h1>Title of the text</h1>
      <section>… a block of the text …</section>
    </article>
  </main>

  <footer>… contact, rights …</footer>
</body>
```

`<main>` is the only one that should appear **once only** per page, and it is what gives the screen reader the "skip to content" shortcut. `<header>` and `<footer>` may repeat: an `<article>` can have its own.
