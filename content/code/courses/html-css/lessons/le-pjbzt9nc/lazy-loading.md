---
title: Pictures that wait until they are needed
version: 1
---

A long page with thirty photographs does not need all thirty before the reader has seen the first. **`loading="lazy"`** tells the browser it may wait to fetch an image until the reader scrolls near it. Here is a page with three tall sections and a picture in each, the first loaded normally and the other two lazily:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shelves · Andorinha Books</title>
    <style>
      section { min-height: 4000px; }
    </style>
  </head>
  <body>
    <main>
      <h1>The shelves, one by one</h1>
      <section>
        <h2>Fiction</h2>
        <img src="shelves-480.png" width="480" height="320" alt="The fiction shelves">
      </section>
      <section>
        <h2>Poetry</h2>
        <img src="shelves-960.png" width="480" height="320" alt="The poetry corner" loading="lazy">
      </section>
      <section>
        <h2>Children</h2>
        <img src="shelves-1600.png" width="480" height="320" alt="The children's corner" loading="lazy">
      </section>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe lazy.html fetched box img
shelves-480.png
img  x 8      y 126.78 width 480    height 320
img  x 8      y 4146.69 width 480    height 320
img  x 8      y 8166.59 width 480    height 320
ana@laptop:~/site$ probe lazy.html scroll 2000 fetched
shelves-480.png
shelves-960.png
ana@laptop:~/site$ probe lazy.html scroll 6000 fetched
shelves-480.png
shelves-960.png
shelves-1600.png
```

At the top of the page, only the first picture was fetched; the others sit at y 4146.69 and 8166.59, far below the 768-pixel window. Scrolled to 2000, the second was fetched, while its top was still **about 1400 pixels below the bottom of the window**: the browser starts early so that the picture is there by the time the reader arrives. At 6000, the third.

## The one rule

**Never lazy-load the pictures at the top of the page.** The browser cannot know an image is visible until it has laid the page out, so a lazy image near the top starts later than it would have, and the most important picture on the page, the one the reader sees first, arrives last. That is why the first picture on this page has no `loading` attribute. Lazy is for what is below the first screen, and especially for what is far below it.

Lazy loading is one more reason for `width` and `height`. A lazy picture arrives while somebody is reading, by design, and without its size reserved every one of them is a layout shift.

`<iframe>`, the element that puts another page inside this one, such as an embedded map, takes the same attribute and benefits even more, because an iframe is a whole page.
