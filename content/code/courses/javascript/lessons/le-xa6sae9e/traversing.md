---
title: Walking from one element to another
version: 1
---

Code often starts from one element and needs another near it: **a button was clicked, and the program
needs the book that button belongs to**. The tree has properties for every direction:

```html
<!doctype html>
<ul id="books">
  <li class="book" data-id="7"><span class="title">Iracema</span> <button class="lend">Lend</button></li>
  <li class="book" data-id="12"><span class="title">Dom Casmurro</span> <button class="lend">Lend</button></li>
</ul>
<script>
  const button = document.querySelectorAll(".lend")[1];
  const row = button.closest(".book");
  console.log(row.dataset.id, row.querySelector(".title").textContent);
  console.log(button.parentElement === row, row.parentElement.id);
  console.log(row.previousElementSibling.dataset.id, row.nextElementSibling);
  console.log(button.matches(".lend"), button.closest("table"));
  console.log(row.childNodes.length, row.children.length);
</script>
```

```
ana@dev:~/js$ page traverse.html
12 Dom Casmurro
true books
7 null
true null
3 2
```

- **`closest(".book")` walks up from the button**, through its ancestors, to the first that matches.
  It found the row, and the row's `data-id` said which book it was. This is the line lesson 12 uses
  for every click;
- `parentElement` is one step up, and `previousElementSibling` and `nextElementSibling` are one step
  sideways. The second row had no next sibling, so the answer was `null`;
- `matches(".lend")` asks whether an element fits a selector, and `closest` that finds nothing,
  `closest("table")` here, returns `null`;
- the row has **three** `childNodes` and **two** `children`: the space between the title and the
  button is a text node.

## Keep the data in the page or beside it

`data-id` on the row is what made the walk useful: **the element carried the id of the thing it
shows**, so the code did not have to match titles or count positions. A row's position changes when
the list is sorted, and its title changes when somebody corrects a typo; an id does neither. That is
the reason to put an id on the element you build, as `create.html` could have done with
`dataset.id = b.id`.
