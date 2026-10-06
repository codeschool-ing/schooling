---
title: Breakpoints: stopping the page
version: 1
---

**A breakpoint pauses the program on a line, before that line runs, and leaves everything as it
was.** While it is paused, you can read every variable in scope and the chain of calls that led
there. This page has a bug:

```html
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Shelf</title></head>
<body>
  <ul id="books"></ul>
  <script src="shelf.js"></script>
</body>
</html>
```

```javascript
async function load() {
  const res = await fetch("/api/books");
  const books = await res.json();
  render(books);
}

function render(books) {
  const list = document.querySelector("#books");
  for (let i = 0; i <= books.length; i++) {
    const book = books[i];
    const item = document.createElement("li");
    item.textContent = `${book.title} (${book.year})`;
    list.append(item);
  }
}

load();
```

```
ana@dev:~/js$ page shelf.html --dom '#books'
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

**The page looks right and is wrong.** All three books were rendered, and then the script threw.
Nobody looking only at the screen would know, which is why the console is the first thing to open
when a page misbehaves. The message names a property, `title`, and a value, `undefined`, but not
which book or why.

## Pausing on the error

In DevTools, the Sources panel has a switch to **pause on uncaught exceptions**. The lab's
`--break uncaught` asks Chromium for the same thing:

```
ana@dev:~/js$ page shelf.html --break uncaught
paused at shelf.js:12, on TypeError: Cannot read properties of undefined (reading 'title')
  call stack: render shelf.js:12  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A paused page, drawn as three panes. On the left, render&#x27;s code with line 12 marked as the line the browser stopped on, the template string that reads book.title. Top right, the call stack: render at line 12, called by load at line 4. Below it, the scopes: book is undefined, i is 3, books holds three items. The three facts together explain the error: the loop asked for a fourth book.\"><defs><marker id=\"paused-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf.js</text><text x=\"48\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"56.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">function render(books) {</text><text x=\"48\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"66.8\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const list = document.querySelector(&quot;#books&quot;);</text><text x=\"48\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"66.8\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">for (let i = 0; i &lt;= books.length; i++) {</text><text x=\"48\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"77.6\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const book = books[i];</text><text x=\"48\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><text x=\"77.6\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const item = document.createElement(&quot;li&quot;);</text><rect x=\"26\" y=\"164\" width=\"388\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">12</text><text x=\"77.6\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">item.textContent = `${book.title} (${book.year})`;</text><text x=\"48\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"77.6\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">list.append(item);</text><text x=\"48\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><text x=\"66.8\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"56.0\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Call stack</text><text x=\"462\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">render   shelf.js:12</text><text x=\"462\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load     shelf.js:4</text><rect x=\"450\" y=\"136\" width=\"250\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Scope</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book  = undefined</text><text x=\"462\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i     = 3</text><text x=\"462\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books = Array(3)</text><text x=\"462\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">list  = ul#books</text><path d=\"M420 174 L446 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#paused-ah-amber)\"></path></svg>", "caption": "Where it stopped, how it got there, and what every variable held at that moment."}
```

Three facts, read off one pause:

- **where**: line 12, the template string that reads `book.title`;
- **how it got there**: `render`, called by `load` at line 4. That list is the **call stack**,
  newest call first;
- **what everything held**: `book` is `undefined`, `i` is `3`, and `books` has three items. Index 3
  of a three-item array does not exist.

The scopes come in layers, the scope chain of lesson 6: two **block** scopes, one for the loop's
body and one for the loop's `i`, then the function's **local** scope. The cause is now one sentence:
the loop runs while `i <= books.length`, so it asks for one book too many.

## A breakpoint on a line, with a condition

Pausing on the error works when there is an error. More often there is only a wrong value, and you
pause on a line you choose. In DevTools you click the line number in the Sources panel. A plain
breakpoint on line 11 would pause four times, once per pass of the loop. A **conditional
breakpoint** pauses only when an expression is true:

```
ana@dev:~/js$ page shelf.html --break shelf.js:11 --if 'book === undefined'
paused at shelf.js:11
  call stack: render shelf.js:11  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

The condition ran on every pass and was true only on the last. This is the tool for a bug in the
900th item of a list: you write down what "wrong" looks like and let the browser wait for it.

## The fix

```
ana@dev:~/js$ sed -i 's/i <= books.length/i < books.length/' shelf.js
ana@dev:~/js$ sed -n 9p shelf.js
  for (let i = 0; i < books.length; i++) {
ana@dev:~/js$ page shelf.html --dom '#books'
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

No error, and the same three books. The fix is one character, and finding it took two runs and no
edit to the code.
