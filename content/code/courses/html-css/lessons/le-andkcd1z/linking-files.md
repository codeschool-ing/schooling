---
title: Bringing in CSS, scripts and images
version: 2
---

A page is rarely one file. The bookshop's home page needs a stylesheet, a small script for its menu, and a photograph, and the HTML says where each one is. Here is the page, `links.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="site.css">
    <script src="menu.js" defer></script>
  </head>
  <body>
    <h1>Andorinha Books</h1>
    <img src="cover.png" alt="The shop's front door" width="120" height="80">
  </body>
</html>
```

Three elements point at three other files, and each is written differently because each is a different kind of thing:

- **`<link rel="stylesheet" href="site.css">`** brings in CSS. `rel` says what the relationship is, and `stylesheet` is one of several; the icon in the last section was another. It goes in the head.
- **`<script src="menu.js" defer></script>`** brings in JavaScript. It is not a void element: it always needs its closing tag, even when empty, and it is the one element where forgetting it swallows the rest of the page as section 09 described. `defer` is explained below.
- **`<img src="cover.png" alt="…">`** brings in an image, and it goes in the body because an image is content. Lesson 4 is about images in detail, including what to write in `alt`.

The two files it points at are one line each, and they go beside the page. `site.css` colours the heading:

```css
h1 { color: #2f6f4e; }
```

`menu.js` marks the page as ready for a menu, which is as far as a course about HTML takes it:

```js
document.documentElement.dataset.menu = 'ready';
```

`cover.png` is any small picture, as in section 08.

When the browser opens the page it asks for each of them. `probe fetched` lists what it asked for, and `style` confirms the stylesheet arrived and applied:

```
ana@laptop:~/site$ probe links.html fetched style h1 color
site.css
menu.js
cover.png
h1  color: rgb(47, 111, 78)
```

The colour in `site.css` is `#2f6f4e`, and the browser reports it as `rgb(47, 111, 78)`: the same colour in the form the browser stores it.

## Paths

`href="site.css"` is a **relative path**: the browser looks for `site.css` in the same directory as the page. `href="css/site.css"` would look one directory down, and `href="../site.css"` one directory up. A path starting with `/`, such as `/site.css`, starts at the root of the site, which works on a server and not when you double-click a file on your disk, because there the root is the root of your whole drive. The pages in this course use relative paths for exactly that reason.

## Why `defer`

Without `defer`, a `<script>` in the head stops the parser: the browser fetches the script, runs it, and only then carries on reading the HTML. Nothing below it is on the screen in the meantime. With `defer`, the browser fetches the script while it keeps parsing and runs it once the whole document has been read. `web-fundamentals` lesson 10 calls this the critical path, and the rule it gives is the one to follow: **a script in the head gets `defer`**, or `type="module"`, which defers on its own. The script itself is the subject of the `javascript` course.

A stylesheet does not have that problem in the same way. The browser keeps parsing while it downloads CSS, but it waits for the stylesheet before drawing anything, because drawing unstyled content and then restyling it would make the page jump. That is why stylesheets go in the head, early: the sooner the browser knows about them, the sooner it can draw.
