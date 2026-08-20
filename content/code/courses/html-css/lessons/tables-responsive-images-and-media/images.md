---
title: Images that do not waste bandwidth
---

Serving the same 2000px image to a phone throws away the bandwidth and the battery of whoever has least of both. `srcset` lets the browser choose:

```html
<img
  src="photo-800.jpg"
  srcset="photo-400.jpg 400w, photo-800.jpg 800w, photo-1600.jpg 1600w"
  sizes="(max-width: 700px) 100vw, 700px"
  alt="The school front seen from the pavement"
  width="800" height="600"
  loading="lazy" />
```

`width` and `height` do not fix the size when there is CSS — they state the **aspect ratio**, and that is what stops the page from jumping when the image finishes loading. `loading="lazy"` defers whatever is off screen.

```schooling-figure
{
  "image": "data:image/svg+xml,<svg%20xmlns=%22http://www.w3.org/2000/svg%22%20viewBox=%220%200%20640%20200%22><g%20fill=%22none%22%20stroke=%22%238a8f98%22%20stroke-width=%221.3%22><rect%20x=%2212%22%20y=%22118%22%20width=%2270%22%20height=%2252%22%20rx=%223%22/><rect%20x=%22106%22%20y=%2284%22%20width=%22120%22%20height=%2286%22%20rx=%223%22/><rect%20x=%22250%22%20y=%2226%22%20width=%22230%22%20height=%22144%22%20rx=%223%22/></g><g%20fill=%22%238a8f98%22%20font-family=%22monospace%22%20font-size=%2211%22%20text-anchor=%22middle%22><text%20x=%2247%22%20y=%22148%22>400w</text><text%20x=%22166%22%20y=%22130%22>800w</text><text%20x=%22365%22%20y=%22102%22>1600w</text><text%20x=%2247%22%20y=%22188%22>phone</text><text%20x=%22166%22%20y=%22188%22>tablet</text><text%20x=%22365%22%20y=%22188%22>desktop</text></g><g%20fill=%22none%22%20stroke=%22%238a8f98%22%20stroke-width=%221%22%20stroke-dasharray=%223%203%22%20opacity=%22.7%22><path%20d=%22M520%2026v144%22/></g><g%20fill=%22%238a8f98%22%20font-family=%22monospace%22%20font-size=%2210%22><text%20x=%22534%22%20y=%2290%22>the%20browser</text><text%20x=%22534%22%20y=%22106%22>picks%20one,</text><text%20x=%22534%22%20y=%22122%22>not%20all%20three</text></g></svg>",
  "alt": "Three rectangles of different sizes labelled 400w, 800w and 1600w, under the labels phone, tablet and desktop",
  "caption": "`srcset` offers all three; the one who chooses is the browser, which knows the screen width and its density — things the server does not know."
}
```

`alt` describes the image for whoever cannot see it. A purely decorative image takes `alt=""` — empty, not absent: that way the screen reader ignores it instead of announcing the file name.
