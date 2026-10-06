---
title: Lists, ordered and not
version: 1
---

Lists are everywhere on a page, often where nobody would call them lists: a menu is a list of links, a set of cards is a list of items, a footer has a list of policies. HTML has three kinds, and using them gives a screen reader something very specific to say: how many items there are, and which one the user is on.

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

**`<ol>` is an ordered list, where the order is part of the meaning.** Steps of a recipe, a ranking, the three steps of ordering a book: put them in a different order and they say something different. The browser numbers them, and `start` and `reversed` change the numbering.

**`<ul>` is an unordered list, where it is not.** What the shop buys could be listed in any order and mean the same.

**`<dl>` is a description list: pairs of a term and its description.** `<dt>` is the term and `<dd>` is what it means, as in the prices above, a glossary or the details on a product page. The tree calls them **term** and **definition**.

Each list item of `<ol>` and `<ul>` is an `<li>`, and **only `<li>` elements can be direct children of a list**. A `<div>` or a `<p>` straight inside a `<ul>` is invalid, and a validator says so; put it inside the `<li>`.

## A menu is a list

The navigation on the semantic home page was a `<ul>` inside a `<nav>`, and the tree read it back as a list of three items. That is a convention rather than a rule, and a useful one: the reader hears "navigation, list, three items" and knows the size of the menu before hearing any of it. The bullets the browser draws by default are removed with one line of CSS, `list-style: none`, and lesson 8 lays the items out in a row.

Lists nest, too: a sub-menu is a `<ul>` inside an `<li>`. Keep the nesting real, one list per level, rather than indenting items with CSS to look like a hierarchy the HTML does not have.
