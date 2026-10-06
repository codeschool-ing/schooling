---
title: Patterns: a menu, a split row, a centred message and a footer at the bottom
version: 1
---

Four small layouts make up most of what Flexbox does on a real site. Here they are on one page:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="patterns.css">
  </head>
  <body>
    <header>
      <p class="logo">Andorinha Books</p>
      <nav aria-label="Main">
        <ul>
          <li><a href="events.html">Events</a></li>
          <li><a href="order.html">Order a book</a></li>
          <li class="account"><a href="account.html">Your account</a></li>
        </ul>
      </nav>
    </header>
    <main>
      <article class="review">
        <img src="cover.png" alt="" width="60" height="90">
        <div>
          <h2>Vidas Secas</h2>
          <p>Graciliano Ramos, 1938. Reviewed by Ana.</p>
        </div>
      </article>
      <div class="empty">
        <p>Nothing in your basket yet.</p>
      </div>
    </main>
    <footer>Rua dos Pinheiros, 1000 · São Paulo</footer>
  </body>
</html>
```

```css
body {
  margin: 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
main { flex: 1; }

nav ul {
  display: flex;
  gap: 16px;
  list-style: none;
  margin: 0;
  padding: 0;
}
nav .account { margin-left: auto; }

.review { display: flex; gap: 16px; align-items: flex-start; }
.review h2 { margin-top: 0; }

.empty {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  background: #f4f1ea;
}
```

```
ana@laptop:~/site$ probe patterns.html box 'nav li' box '.review img' box '.review h2'
li          x 0      y 50     width 43.55  height 18
li          x 59.55  y 50     width 84.42  height 18
li.account  x 938.97 y 50     width 85.03  height 18
img  x 0      y 68     width 60     height 90
h2  x 76     y 68     width 281.72 height 27
ana@laptop:~/site$ probe patterns.html box .empty box ".empty p" box main box footer
div.empty  x 0      y 158    width 1024   height 200
p  x 424.67 y 249    width 174.64 height 18
main  x 0      y 68     width 1024   height 682
footer  x 0      y 750    width 1024   height 18
```

## A menu in a row, with one item pushed to the end

Lesson 2 promised that the list of links in the menu would be laid out in a row. `display: flex` on the `<ul>` does it, `gap: 16px` spaces the items, and the list is still a list in the HTML. The account link is at the far right, **x 938.97**, because of one declaration: **`margin-left: auto`**. In a flex container, an `auto` margin takes all the free space on that side, which pushes the item, and everything after it, to the end. Lesson 6 said a vertical `auto` margin did nothing in the normal flow and that this lesson would show where it does more: in Flexbox, auto margins work on both axes, and they are how one item is moved away from its group.

## A picture beside its text

The review is the **media object**: an image and a block of text side by side, the text taking the rest of the width. `display: flex` with `gap: 16px` puts the heading at **x 76**, the 60-pixel cover plus the gap. `align-items: flex-start` stops the default `stretch` from stretching the image to the height of the text.

## Centred in both directions

The empty-basket message is centred with `justify-content: center` and `align-items: center` in a box 200 tall. The paragraph is at x 424.67, which is (1024 − 174.64) / 2, and vertically in the middle of the box. Two declarations, and the message stays centred whatever its length or the window's width.

## A footer that stays at the bottom

On a page with little content, the footer would normally sit right under it, halfway up the window. Here the body is a flex **column** at least as tall as the window, `min-height: 100vh`, and `main` has `flex: 1`, so it takes all the free height: **main is 682 tall and the footer starts at 750**, at the bottom of the 768 window. On a long page, `main` is simply as tall as its content and the footer follows it.
