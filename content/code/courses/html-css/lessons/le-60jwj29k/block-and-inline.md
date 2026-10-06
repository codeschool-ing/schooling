---
title: Block, inline and inline-block
version: 1
---

Whether width, height and margins do anything to an element depends on its **`display`**. Two values were there before anything else, and the browser gives one of them to every element by default:

- **`block`**: the box takes the whole width available and starts on a new line. `<p>`, `<h1>`, `<div>`, `<article>`, `<ul>` are block.
- **`inline`**: the box flows inside a line of text, as wide as its content. `<a>`, `<span>`, `<em>`, `<strong>`, `<img>` are inline.

Here is a `<span>` with a width, a height, padding and margins, three times: as it comes, as `inline-block`, and as `block`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Display · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .tag {
        width: 200px;
        height: 60px;
        padding: 4px 8px;
        margin: 20px;
        background: #f4f1ea;
      }
      .as-block { display: block; }
      .as-inline-block { display: inline-block; }
    </style>
  </head>
  <body>
    <p>A <span class="tag">poetry</span> event.</p>
    <p>A <span class="tag as-inline-block">poetry</span> event.</p>
    <p>A <span class="tag as-block">poetry</span> event.</p>
  </body>
</html>
```

```
ana@laptop:~/site$ probe display.html style .tag display box .tag
span.tag  display: inline
span.tag.as-inline-block  display: inline-block
span.tag.as-block  display: block
span.tag                  x 34.23  y 15     width 60.47  height 25
span.tag.as-inline-block  x 34.23  y 76     width 216    height 68
span.tag.as-block         x 20     y 224    width 216    height 68
```

**The inline span ignored its width and height.** It is 60.47 pixels wide, the width of the word *poetry* plus 16 pixels of padding, and 25 tall, the line's text plus 8 pixels of padding. Its vertical margins did nothing either: an inline box's vertical padding is drawn, and it pushes nothing above or below it out of the way.

**`inline-block` obeys all of them and still sits in the line**: 216 by 68, which is 200 plus 16 of padding and 60 plus 8, with the words *A* and *event.* on either side of it. It is how a button-like link sits in a sentence.

**`block` obeys them and leaves the line**: the same 216 by 68, but now on its own line, 20 pixels in from the left because its margins apply on every side.

## The gap under an image

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Cover · Andorinha Books</title>
    <style>
      .frame { border: 1px solid #2f6f4e; width: 120px; }
      .fixed img { display: block; }
    </style>
  </head>
  <body>
    <div class="frame"><img src="cover.png" alt="" width="120" height="80"></div>
    <div class="frame fixed"><img src="cover.png" alt="" width="120" height="80"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe gap.html box .frame
div.frame        x 8      y 8      width 122    height 86
div.frame.fixed  x 8      y 94     width 122    height 82
```

The first frame is 86 pixels tall for an 80-pixel image and 2 pixels of border, so 4 pixels are left over: the space below the line's baseline that lesson 1 met in standards mode. The second frame says `img { display: block; }`, the image is no longer on a line of text, and the frame is 82, exactly image plus border. `vertical-align: bottom` on the image also removes it, by moving the image off the baseline. Either is the usual first line in a stylesheet's treatment of images.

Lessons 8 and 9 add two more values, `flex` and `grid`, which change how an element lays out its **children**. Everything in this lesson is about the box itself.
