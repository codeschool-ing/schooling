---
title: The picture element: different crops and formats
version: 1
---

`srcset` offers **the same picture** at different sizes. Sometimes a narrow screen needs **a different picture**: the wide photograph of the shelves becomes a strip of nothing on a phone, and a square crop of one shelf reads better. That is called **art direction**, and `<picture>` does it.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>The shop · Andorinha Books</title>
    <style>
      body { margin: 0; }
      img { width: 100%; height: auto; }
    </style>
  </head>
  <body>
    <picture>
      <source media="(max-width: 600px)" srcset="shelves-crop-600.png">
      <img src="shelves-960.png" width="960" height="640"
           alt="The shelves of the shop, floor to ceiling">
    </picture>
  </body>
</html>
```

`<picture>` wraps an ordinary `<img>`, and adds `<source>` elements before it. The browser takes the **first** `<source>` whose `media` condition matches and uses its `srcset`; if none matches, it uses the `<img>`. The `<img>` is never optional: it is what gets drawn, it carries the `alt`, the `width` and `height`, and it is what a browser too old for `<picture>` shows.

```
ana@laptop:~/site$ probe --width 390 picture.html img img
img  chose shelves-crop-600.png (600×600 pixels), drawn 390 wide
ana@laptop:~/site$ probe --width 1024 picture.html img img
img  chose shelves-960.png (960×640 pixels), drawn 1024 wide
```

On a window 390 wide, `(max-width: 600px)` matches and the square crop is used. At 1024 it does not, and the `<img>`'s own file is used.

## Newer formats, with an old one to fall back on

The other use of `<source>` is the file format. WebP and AVIF compress photographs better than JPEG and PNG, and every current browser reads WebP, but a page may still want to keep a fallback. `type` on a `<source>` names the format, and a browser that cannot read it skips to the next:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <picture>
      <source type="image/webp" srcset="shelves-960.webp">
      <img src="shelves-960.png" width="960" height="640"
           alt="The shelves of the shop, floor to ceiling">
    </picture>
  </body>
</html>
```

```
ana@laptop:~/site$ probe formats.html img img
img  chose shelves-960.webp (960×640 pixels), drawn 960 wide
ana@laptop:~/site$ wc -c shelves-960.png shelves-960.webp
6878 shelves-960.png
2914 shelves-960.webp
9792 total
```

Chromium reads WebP, so it took the first source. The size difference is real but the pictures in this lab are flat colour with a label on them, so the ratio, 2914 bytes against 6878, says little about photographs; on real photographs the saving is the reason the format exists. A browser that did not know `image/webp` would have skipped that `<source>` and drawn the PNG.

**Use `<picture>` when the browser needs to be told something it cannot work out**: a different crop, or a format it may not support. For the same picture at different sizes, `srcset` and `sizes` on a plain `<img>` are enough and are simpler.
