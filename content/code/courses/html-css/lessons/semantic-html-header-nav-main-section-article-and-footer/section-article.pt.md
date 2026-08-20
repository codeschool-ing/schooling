---
title: section, article ou div?
---

A dúvida mais comum do HTML semântico tem uma régua curta.

- **`<article>`** — faz sentido sozinho, fora da página. Um post, uma notícia, um comentário, um cartão de produto. Teste: dá para publicar isto num feed RSS?
- **`<section>`** — um bloco temático **dentro** de algo maior, e que tem um título. Se você não consegue dar um título a ele, provavelmente não é uma `section`.
- **`<div>`** — não significa nada, e está certo assim. É o elemento para agrupar por motivo puramente visual: um contêiner que existe só para receber um `display: flex`.

`<div>` não é derrota. Usar `<section>` onde só havia necessidade de layout é pior: cria estrutura semântica falsa, e o leitor de tela anuncia uma região que não existe.
