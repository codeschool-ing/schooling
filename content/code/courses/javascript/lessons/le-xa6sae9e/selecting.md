---
title: Finding elements
version: 1
---

**`querySelector` takes a CSS selector and returns the first element that matches**, or `null`.
`querySelectorAll` returns all of them. The selector is the same language a stylesheet uses, so
`.book`, `#books .read` and `li:nth-child(2)` all work:

```html
<!doctype html>
<h1>My shelf</h1>
<ul id="books">
  <li class="book">Iracema</li>
  <li class="book read">Dom Casmurro</li>
</ul>
<script>
  console.log(document.querySelector(".book").textContent);
  console.log(document.querySelector("#books .read").textContent);
  console.log(document.querySelector(".missing"));

  const all = document.querySelectorAll(".book");
  const live = document.getElementsByClassName("book");
  console.log(all.length, live.length);

  const li = document.createElement("li");
  li.className = "book";
  li.textContent = "Macunaíma";
  document.getElementById("books").append(li);
  console.log(all.length, live.length);
</script>
```

```
ana@dev:~/js$ page select.html
Iracema
Dom Casmurro
null
2 2
2 3
```

## Three things the output shows

- **A selector that matches nothing gives `null`**, not an error. The next line that uses it, such as
  `.textContent`, is where the error appears, and its message is lesson 4's `Cannot read properties
  of null`. When you see that message in page code, the selector is the first suspect: a typo, or a
  script that ran before the element existed;
- `querySelectorAll` returns a **static** `NodeList`: a snapshot taken when it ran. After a third book
  was added, it still said 2;
- `getElementsByClassName` returns a **live** `HTMLCollection`, which updates itself as the page
  changes, and said 3. A live list changing while a loop walks it is a classic bug, which is one
  reason most code today uses `querySelectorAll`.

`getElementById` is the old, fast way to find one element by its `id`, and you will see it everywhere.
`document.querySelector("#books")` does the same.

## Searching inside an element

Every element has `querySelector` and `querySelectorAll` too, and **searching from an element looks
only inside it**. `row.querySelector(".title")` finds the title in that row and not in any other,
which is how the traversing section of this lesson reaches one item's parts. Lesson 7 showed the
other thing to remember about the result: a `NodeList` has `forEach` and no `map`, so
`Array.from(list, fn)` turns it into an array when you need the array methods.
