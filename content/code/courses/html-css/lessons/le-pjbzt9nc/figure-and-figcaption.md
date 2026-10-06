---
title: Figure and figcaption
version: 1
---

Some pictures belong with a caption: a photograph with a line about when it was taken, a chart with its source, a diagram with what it shows. **`<figure>` groups a piece of content with its caption, and `<figcaption>` is the caption.**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>The shop</h1>
      <p>The fiction shelves run the length of the front room.</p>
      <figure>
        <img src="shelves-480.png" width="480" height="320"
             alt="Floor-to-ceiling shelves of paperbacks, with a ladder on a rail">
        <figcaption>The front room in 2026, after the new shelves went in.</figcaption>
      </figure>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe figure.html tree
- main:
  - heading "The shop" [level=1]
  - paragraph: The fiction shelves run the length of the front room.
  - figure "The front room in 2026, after the new shelves went in.":
    - img "Floor-to-ceiling shelves of paperbacks, with a ladder on a rail"
    - text: The front room in 2026, after the new shelves went in.
```

The tree made a **figure** named by its caption, holding the image and the caption's text. The `alt` and the caption are different texts with different jobs: **the `alt` replaces the picture, the caption adds to it**. *Floor-to-ceiling shelves of paperbacks, with a ladder on a rail* is what somebody who cannot see the image would otherwise miss; *The front room in 2026, after the new shelves went in* is what everybody reads, sighted or not. If the caption already describes everything the picture shows, the image can have `alt=""` and leave the description to the caption, so that it is not heard twice.

## Not only images

A figure is any self-contained piece of content referred to from the text: a code listing, a quotation, a table, a video, a diagram. The test is the same as for an article in lesson 2, at a smaller scale: the text around it refers to it, and it could be moved to an appendix without breaking that text. A picture that is part of the sentence, like an icon next to a word, is not a figure.
