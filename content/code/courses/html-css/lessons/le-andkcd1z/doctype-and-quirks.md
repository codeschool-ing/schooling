---
title: The doctype, and the mode without it
version: 2
---

The first line of every page, `<!doctype html>`, looks like a formality. It is not a tag, and it does not create an element. **It is a switch**, and leaving it out changes how the browser lays out the whole page.

## Two modes

In the early 2000s, when browsers began to follow the CSS standards properly, there were already millions of pages written for the older, non-standard behaviour. Fixing the browsers would have broken those pages. So browsers kept both behaviours and chose between them per page: a page that starts with a modern doctype gets **standards mode**, and a page without one gets **quirks mode**, which imitates the browsers of around 2000.

`<!doctype html>` is the shortest doctype that selects standards mode, which is why it is the one HTML uses now. It is not case-sensitive, so `<!DOCTYPE html>` is the same switch.

## What the switch changes

The differences are small and scattered, and that is exactly why they hurt: a page in quirks mode looks almost right. Here is one you can measure. The two files are identical except for the first line: a `<div>` holding a single image 80 pixels tall.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Cover, with a doctype</title>
  </head>
  <body>
    <div class="frame"><img src="cover.png" alt="" width="120" height="80"></div>
  </body>
</html>
```

Save it as `standards.html`, with any small picture beside it named `cover.png`: the `width` and `height` attributes fix its size at 120 by 80 whatever the picture is. Then save a copy as `quirks.html`, delete its first line, and change its title to *Cover, without a doctype*.

With the doctype:

```
ana@laptop:~/site$ probe standards.html mode box div.frame
compatMode: CSS1Compat
div.frame  x 8      y 8      width 1008   height 84
```

Without it:

```
ana@laptop:~/site$ probe quirks.html mode box div.frame
compatMode: BackCompat
div.frame  x 8      y 8      width 1008   height 80
```

`compatMode` is the browser's own name for the mode: `CSS1Compat` is standards and `BackCompat` is quirks. In standards mode the `<div>` is **84** pixels tall for an 80-pixel image, because an image sits on the line of text like a letter does, and the line keeps room below it for the parts of letters that hang down, like the tail of a *g*. In quirks mode that space is not reserved and the `<div>` is exactly 80.

Four pixels does not sound like much. But the rest of the course explains layout in standards mode, and every rule about boxes and space in lessons 6 to 9 assumes it. In quirks mode some of those rules come out differently, without warning, and you would be debugging a layout against the wrong rulebook. The space under images is something lesson 6 shows you how to remove on purpose.

**A page without a doctype has no error message.** Nothing tells you which mode you are in, except DevTools if you know where to look and a validator, which reports it as an error, section 13. The cure is one line, and it goes first, before anything else.
