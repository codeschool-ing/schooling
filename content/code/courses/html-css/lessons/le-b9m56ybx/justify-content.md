---
title: Distributing along the main axis: justify-content
version: 1
---

When the items do not fill the main axis, **`justify-content`** decides what to do with the space left over. Here are six shelves, each 600 wide with three books 100 wide, so there are always 300 pixels to place; each shelf uses a different value:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>justify-content · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .book { width: 100px; background: #2f6f4e; color: white; }
      #flex-start { justify-content: flex-start; }
      #center { justify-content: center; }
      #flex-end { justify-content: flex-end; }
      #space-between { justify-content: space-between; }
      #space-around { justify-content: space-around; }
      #space-evenly { justify-content: space-evenly; }
    </style>
  </head>
  <body>
    <div class="shelf" id="flex-start">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="center">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="flex-end">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-between">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-around">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
    <div class="shelf" id="space-evenly">
      <div class="book">A</div>
      <div class="book">B</div>
      <div class="book">C</div>
    </div>
  </body>
</html>
```

`probe` printed where each book starts. Four of the six:

```
ana@laptop:~/site$ probe justify.html box '#center .book'
div.book  x 150    y 32     width 100    height 24
div.book  x 250    y 32     width 100    height 24
div.book  x 350    y 32     width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-between .book'
div.book  x 0      y 96     width 100    height 24
div.book  x 250    y 96     width 100    height 24
div.book  x 500    y 96     width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-around .book'
div.book  x 50     y 128    width 100    height 24
div.book  x 250    y 128    width 100    height 24
div.book  x 450    y 128    width 100    height 24
ana@laptop:~/site$ probe justify.html box '#space-evenly .book'
div.book  x 75     y 160    width 100    height 24
div.book  x 250    y 160    width 100    height 24
div.book  x 425    y 160    width 100    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Six containers 600 pixels wide, each holding three items 100 wide, drawn at their measured x positions. flex-start: 0, 100, 200. center: 150, 250, 350. flex-end: 300, 400, 500. space-between: 0, 250, 500. space-around: 50, 250, 450. space-evenly: 75, 250, 425.\"><text x=\"20\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-start</text><rect x=\"150\" y=\"14\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"230\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"310\" y=\"17\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 100 200</text><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">center</text><rect x=\"150\" y=\"50\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"270\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"310\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"430\" y=\"53\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"470\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150 250 350</text><text x=\"20\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-end</text><rect x=\"150\" y=\"86\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"430\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"470\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"510\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"550\" y=\"89\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"590\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 400 500</text><text x=\"20\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-between</text><rect x=\"150\" y=\"122\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"150\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"190\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"550\" y=\"125\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"590\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 250 500</text><text x=\"20\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-around</text><rect x=\"150\" y=\"158\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"190\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"230\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"510\" y=\"161\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"550\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50 250 450</text><text x=\"20\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">space-evenly</text><rect x=\"150\" y=\"194\" width=\"480\" height=\"26\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A</text><rect x=\"350\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">B</text><rect x=\"490\" y=\"197\" width=\"80\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">C</text><text x=\"640\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75 250 425</text></svg>", "caption": "The 300 pixels left over, shared out six ways. The numbers are where each item starts."}
```

- **`flex-start`**, the default: the books at 0, 100 and 200, and all 300 pixels after them.
- **`center`**: 150 pixels before and 150 after. The books at 150, 250, 350.
- **`flex-end`**: all 300 before them.
- **`space-between`**: the first book at the start, the last at the end, and the 300 shared between the two gaps, 150 each. The books at 0, 250, 500.
- **`space-around`**: each book gets an equal share on both sides, 50 each, so the gaps between books, 100, are twice the gaps at the ends, 50. The books at 50, 250, 450.
- **`space-evenly`**: the four gaps, before, between and after, are all equal: 300 / 4 = 75. The books at 75, 250, 425.

`space-between` is the one for a header with a logo at the left and a menu at the right. `center` is half of centring something, section 11. The difference between `space-around` and `space-evenly` is the one people mix up, and the numbers settle it: around gives every item the same margin, evenly gives every gap the same width.

## The space is only there if nothing grows

All six of these assume the items keep their own size. If any item has a `flex-grow`, section 07, it takes the free space for itself, and there is nothing left for `justify-content` to distribute. That is the usual reason a `justify-content` seems to do nothing.
