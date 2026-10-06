---
title: Listas, ordenadas ou não
version: 1
---

Listas estão por toda parte numa página, muitas vezes onde ninguém as chamaria de listas: um menu é uma lista de links, um conjunto de cartões é uma lista de itens, um rodapé tem uma lista de políticas. O HTML tem três tipos, e usá-los dá a um leitor de tela algo bem específico a dizer: quantos itens há e em qual o usuário está.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>How to order · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>How to order a book</h1>
      <ol>
        <li>Search the catalogue.</li>
        <li>Send us the title.</li>
        <li>Collect it within a week.</li>
      </ol>
      <h2>What we buy</h2>
      <ul>
        <li>Fiction in Portuguese and English</li>
        <li>Poetry</li>
      </ul>
      <h2>Prices</h2>
      <dl>
        <dt>Paperback</dt>
        <dd>R$ 15 to R$ 40</dd>
        <dt>Hardback</dt>
        <dd>R$ 30 to R$ 90</dd>
      </dl>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe lists.html tree
- main:
  - heading "How to order a book" [level=1]
  - list:
    - listitem: Search the catalogue.
    - listitem: Send us the title.
    - listitem: Collect it within a week.
  - heading "What we buy" [level=2]
  - list:
    - listitem: Fiction in Portuguese and English
    - listitem: Poetry
  - heading "Prices" [level=2]
  - term: Paperback
  - definition: R$ 15 to R$ 40
  - term: Hardback
  - definition: R$ 30 to R$ 90
```

**`<ol>` é uma lista ordenada, em que a ordem faz parte do significado.** Os passos de uma receita, um ranking, os três passos para encomendar um livro: ponha em outra ordem e eles dizem outra coisa. O navegador os numera, e `start` e `reversed` mudam a numeração.

**`<ul>` é uma lista não ordenada, em que a ordem não importa.** O que a loja compra poderia ser listado em qualquer ordem e significar o mesmo.

**`<dl>` é uma lista de descrição: pares de um termo e sua descrição.** `<dt>` é o termo e `<dd>` é o que ele significa, como nos preços acima, num glossário ou nos detalhes da página de um produto. A árvore os chama de **term** e **definition**.

Cada item de `<ol>` e `<ul>` é um `<li>`, e **só elementos `<li>` podem ser filhos diretos de uma lista**. Uma `<div>` ou um `<p>` direto dentro de um `<ul>` é inválido, e um validador aponta; ponha-o dentro do `<li>`.

## Um menu é uma lista

A navegação da página inicial semântica era um `<ul>` dentro de um `<nav>`, e a árvore a leu de volta como uma lista de três itens. É uma convenção, não uma regra, e uma convenção útil: quem escuta ouve "navegação, lista, três itens" e sabe o tamanho do menu antes de ouvir qualquer item. Os marcadores que o navegador desenha por padrão saem com uma linha de CSS, `list-style: none`, e a aula 8 põe os itens numa linha.

Listas também se aninham: um submenu é um `<ul>` dentro de um `<li>`. Mantenha o aninhamento de verdade, uma lista por nível, em vez de recuar itens com CSS para parecer uma hierarquia que o HTML não tem.
