---
title: What the browser does with broken HTML
version: 1
---

The browser's HTML parser never stops with an error. That is a deliberate decision, written into the HTML standard: for every possible sequence of characters, the standard says exactly what tree the parser must build. So broken HTML does not crash anything. **It gets repaired, by rules you did not choose**, and the repaired tree is what the browser draws and what every script and stylesheet sees.

Here is a page with three ordinary mistakes in it: a `<b>` that is never closed in its paragraph, a `</b>` and an `</i>` closed in the wrong order, and a `<div>` inside a paragraph.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Opening hours</title>
</head>
<body>
<p>We are open <b>every day
<p>Closed on <i>public holidays</b></i>
<p>Our shop: <div>Rua dos Pinheiros, 1000</div>
</body>
```

Open it and it looks fine: three lines about opening hours. Here is the tree the browser actually built, printed by `probe dom`:

```
ana@laptop:~/site$ probe broken.html dom
<html lang="en"><head>
<meta charset="utf-8">
<title>Opening hours</title>
</head>
<body>
<p>We are open <b>every day
</b></p><p><b>Closed on <i>public holidays</i></b>
</p><p>Our shop: </p><div>Rua dos Pinheiros, 1000</div>

</body></html>
```

Read it against the file, and three repairs come out.

**The unclosed `<b>` leaked into the next paragraph.** The file opens `<b>` in the first paragraph and never closes it there. When the second `<p>` starts, the parser closes the first paragraph, and with it the `<b>`, then reopens a fresh `<b>` inside the new paragraph, because the bold was still "on". So *Closed on public holidays* is bold, which the author never wrote.

**The misnested `</b></i>` was untangled.** The parser closed the `<i>` inside the `<b>`, which is the only nesting the tree can hold.

**The `<div>` broke the paragraph in two.** A paragraph cannot contain a block like `<div>`, so when the parser meets one it closes the `<p>` first. *Our shop:* is one paragraph and the address is a `<div>` after it, a sibling rather than a child. Any CSS written for "the address inside the paragraph" matches nothing, and the author has no idea why.

## The repair that empties the page

Most repairs are like these: the page looks almost right. One is not. Here is the same page with a single change: the title has no closing tag.

```html
<title>Opening hours
</head>
```

```
ana@laptop:~/site$ probe unclosed-title.html title box body
title: "Opening hours </head> <body> <p>We are open <b>every day <p>Closed on <i>public holidays</b></i> <p>Our shop: <div>Rua dos Pinheiros, 1000</div> </body>"
body  x 8      y 8      width 1008   height 0
```

**The page is blank.** The body is 0 pixels tall. Inside `<title>`, the parser does not look for tags at all: everything until it finds the characters `</title>` is text, because a title cannot contain elements. It never finds them, so the whole rest of the file, tags included, became the title. The browser tab shows a long title full of angle brackets and the window shows nothing.

`<title>` is not the only element that reads like this. `<textarea>` and `<style>` and `<script>` do too, which is why an unclosed `<textarea>` in a form swallows every field after it.

## What to take from it

You cannot see repairs by looking at the page, because the repaired page is what you see. Two tools show them. **DevTools' Elements panel shows the tree, not the file**, so a `<div>` you wrote inside a `<p>` appears after it there, and that mismatch between what you typed and what you see is the clue. And a validator, section 11, reads the file itself and tells you every place the parser had to guess.
