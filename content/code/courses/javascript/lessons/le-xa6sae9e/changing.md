---
title: Changing what an element shows
version: 1
---

An element object has properties for everything the browser draws, and **setting one changes the page
at once**. Four groups cover most of what you will do:

```html
<!doctype html>
<h1 id="title">My shelf</h1>
<li id="book" class="book" data-book-id="42" style="color: rebeccapurple">Iracema</li>
<input id="copies" value="1">
<script>
  const title = document.querySelector("#title");
  title.textContent = "Ana's shelf";

  const book = document.querySelector("#book");
  book.classList.add("read");
  book.classList.toggle("lent");
  console.log(book.className, book.classList.contains("read"));

  console.log(book.dataset.bookId, typeof book.dataset.bookId);
  book.dataset.lentTo = "bia";

  book.style.fontWeight = "bold";
  console.log(book.style.color, getComputedStyle(book).color);
</script>
```

```
ana@dev:~/js$ page change.html --dom '#book'
book read lent true
42 string
rebeccapurple rgb(102, 51, 153)
<li id="book" class="book read lent" data-book-id="42" style="color: rebeccapurple; font-weight: bold;" data-lent-to="bia">Iracema</li>
```

`--dom '#book'` printed the element's HTML after the script had run, so the last line is the
element **as the browser now holds it**, not as the file wrote it.

## Text, classes, data and style

- **`textContent`** replaces the text of an element. The title said `Ana's shelf` after the script;
- **`classList`** adds, removes, toggles and checks classes one at a time, without touching the
  others. The book kept `book` and gained `read` and `lent`. Changing classes and letting the
  stylesheet decide what they look like is the usual way to change appearance;
- **`dataset`** reads and writes `data-` attributes, the place HTML keeps for your own information on
  an element. `data-book-id` became `dataset.bookId`, with the dash turned into a capital, and its
  value came back as the string `"42"`: attributes are always text, so lesson 2's conversion applies;
- **`style`** sets inline styles. It only reads what is written in the `style` attribute;
  `getComputedStyle` gives the value the browser actually used, after every stylesheet, as
  `rgb(102, 51, 153)`.

## Text or markup

```html
<!doctype html>
<li id="book"><span class="title">Iracema</span> <small>1865</small></li>
<script>
  const book = document.querySelector("#book");
  console.log(JSON.stringify(book.textContent));
  console.log(book.innerHTML);
</script>
```

```
ana@dev:~/js$ page read.html
"Iracema 1865"
<span class="title">Iracema</span> <small>1865</small>
```

Read from the same element, **`textContent` gives the text alone and `innerHTML` gives the markup**,
tags included. Writing works the same way round: `textContent` puts in text exactly as it is, and
`innerHTML` asks the browser to read the string as HTML. **Use `textContent` for any value that came
from outside your code**, such as a field, a server or an address bar; `innerHTML` is for markup you
wrote yourself. The `front-quality` course, lesson 9, explains what goes wrong otherwise and how pages
defend against it.

## Properties and attributes are not the same thing

```
ana@dev:~/js$ page change.html --do 'fill #copies 3' --do 'eval [document.querySelector("#copies").value, document.querySelector("#copies").getAttribute("value")].join(" / ")'
book read lent true
42 string
rebeccapurple rgb(102, 51, 153)
-- fill #copies 3
-- eval [document.querySelector("#copies").value, document.querySelector("#copies").getAttribute("value")].join(" / ")
3 / 1
```

**An attribute is what the HTML said; a property is the element's current state.** The field's
`value` attribute was `1` in the file. After `page` typed `3` into it, the `value` *property* said 3
and `getAttribute("value")` still said 1. The attribute is the starting value and the property is
what the user has done since. For a form field, read the property.
