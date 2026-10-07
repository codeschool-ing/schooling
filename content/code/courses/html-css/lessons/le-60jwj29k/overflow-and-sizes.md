---
title: Limits, overflow and keeping a shape
version: 1
---

A box that must work at every width needs limits rather than a fixed size, and a rule for what happens when its content does not fit. Here are four boxes, each showing one of those:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sizes · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card { max-width: 400px; padding: 16px; box-sizing: border-box; }
      .link { width: 240px; }
      .wraps { overflow-wrap: anywhere; }
      .poster { width: 300px; aspect-ratio: 16 / 9; }
    </style>
  </head>
  <body>
    <article class="card">Poetry reading: Hilda Hilst</article>
    <p class="link">https://andorinha.example/events/2026/october/poetry-reading</p>
    <p class="link wraps">https://andorinha.example/events/2026/october/poetry-reading</p>
    <div class="poster"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe sizes.html box .card spill .link box .link box .poster
article.card  x 0      y 0      width 400    height 50
p.link  content 351 wide in a box 240 wide: it spills
p.link.wraps  content 240 wide in a box 240 wide
p.link        x 0      y 66     width 240    height 36
p.link.wraps  x 0      y 118    width 240    height 36
div.poster  x 0      y 170    width 300    height 168.75
ana@laptop:~/site$ probe --width 320 sizes.html box .card
article.card  x 0      y 0      width 320    height 50
```

## `max-width` instead of `width`

The card says `max-width: 400px` and no `width`. On the 1024 window it is **400**; on a 320 window it is **320**, the whole width available. `width: 400px` would have made it 400 on the narrow window as well, wider than the screen. **`max-width` is the habit for anything that should be no bigger than a size and smaller when it must**, and `min-width` is its mirror. Lesson 11 builds responsive layouts on exactly this.

## Overflow

The first link paragraph is 240 wide and holds an address with no spaces in it. **Its content is 351 wide in a box 240 wide: it spills.** The browser breaks lines at spaces and at a few characters such as slashes and hyphens, and a long enough run with no break opportunity is drawn past the edge of the box, over whatever is next to it. The second paragraph adds `overflow-wrap: anywhere`, which allows a break between any two characters when nothing else fits, and its content is exactly 240.

When content is bigger than its box, the **`overflow`** property says what to do: `visible`, the default, draws it outside; `hidden` cuts it off; `auto` adds a scrollbar only if needed; `scroll` always adds one. `overflow: auto` is the right answer for a wide table on a phone, where the table scrolls inside its box and the page does not. `hidden` is the dangerous one, because content that is cut off is content nobody can reach.

## Keeping a shape: `aspect-ratio`

The last box says `width: 300px; aspect-ratio: 16 / 9` and no height. It is **168.75** tall, which is 300 × 9 / 16. That is lesson 4's promise: `aspect-ratio` gives any box the proportion that `width` and `height` give an image, so a video frame, a map or a card's picture area keeps its shape at every width, without the padding trick from section 09.

## Content-based sizes

Three keywords size a box by its content: **`min-content`**, as narrow as the content can be without spilling, which for text is its longest word; **`max-content`**, as wide as the content wants on one line; and **`fit-content`**, which is `max-content` but never wider than the space available. `width: fit-content` makes a box hug its text, which is how a label or a badge is sized. Grid, lesson 9, uses all three as track sizes.
