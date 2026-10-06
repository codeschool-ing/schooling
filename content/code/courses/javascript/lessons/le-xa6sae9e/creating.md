---
title: Making new elements
version: 1
---

New elements are made with `document.createElement`, filled in, and attached to the tree. **Until an
element is attached, it exists only in memory and nothing is drawn.** For a row with several parts, a
`<template>` holds the markup once, and each copy is filled in from data:

```html
<!doctype html>
<ul id="books"></ul>
<template id="row">
  <li class="book"><span class="title"></span> <small class="year"></small></li>
</template>
<script>
  const books = [
    { title: "Iracema", year: 1865 },
    { title: "Dom Casmurro", year: 1899 },
    { title: "Macunaíma", year: 1928 },
  ];
  const list = document.querySelector("#books");
  const template = document.querySelector("#row");

  const rows = books.map((b) => {
    const row = template.content.cloneNode(true);
    row.querySelector(".title").textContent = b.title;
    row.querySelector(".year").textContent = b.year;
    return row;
  });
  list.replaceChildren(...rows);

  list.querySelector("li:nth-child(2)").remove();
  console.log(list.children.length);
</script>
```

```
ana@dev:~/js$ page create.html --dom '#books'
2
<ul id="books">
  <li class="book"><span class="title">Iracema</span> <small class="year">1865</small></li>

  

  <li class="book"><span class="title">Macunaíma</span> <small class="year">1928</small></li>
</ul>
```

## The steps, in the order they ran

- a `<template>` element is **not drawn**; its `content` is a ready-made piece of tree waiting to be
  copied. `cloneNode(true)` copies it with everything inside it;
- each copy was filled in with `textContent`, so the titles and years are text however they look;
- **`replaceChildren(...rows)`** emptied the list and put the three rows in, in one change to the
  page rather than three. `append` adds at the end instead, and `prepend` at the start;
- `remove()` took the second row out, and `list.children.length` said 2.

The printed list keeps the whitespace the template had, and the blank lines are where the removed
row's surrounding text nodes stayed. The browser does not draw that whitespace; it is the
`childNodes` of section 02 again.

## Building lists from data

**Data in, elements out** is the shape of most interface code: an array of objects from a server
becomes a list on the page. The frameworks in the next courses exist largely to do this step for you,
and to redo it efficiently when the data changes. Writing it once by hand is how you will understand
what they are doing.
