---
title: Growing and shrinking: flex-grow, flex-shrink and flex-basis
version: 1
---

Every flex item has three numbers that decide its size on the main axis:

- **`flex-basis`**: the size it starts from, before any growing or shrinking. The default, `auto`, means its `width` if it has one, and its content's size if not.
- **`flex-grow`**: how many shares of the **free space** it takes when there is room left over. The default is 0: it does not grow.
- **`flex-shrink`**: how many shares of the **shortfall** it gives up when the items do not fit. The default is 1: everything shrinks equally.

## Growing

Three books with `flex-basis: 100px` on a 600 shelf, with `flex-grow` 1, 2 and 1:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Grow and shrink · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .book { flex-basis: 100px; background: #2f6f4e; color: white; }
      #grow .a, #grow .c { flex-grow: 1; }
      #grow .b { flex-grow: 2; }
      #shrink .book { flex-basis: 300px; }
      #shrink .b { flex-shrink: 2; }
    </style>
  </head>
  <body>
    <div class="shelf" id="grow">
      <div class="book a">A</div>
      <div class="book b">B</div>
      <div class="book c">C</div>
    </div>
    <div class="shelf" id="shrink">
      <div class="book a">A</div>
      <div class="book b">B</div>
      <div class="book c">C</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe grow.html box '#grow .book'
div.book.a  x 0      y 0      width 175    height 24
div.book.b  x 175    y 0      width 250    height 24
div.book.c  x 425    y 0      width 175    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 168\" role=\"img\" aria-label=\"A worked example of flex-grow. A container 600 wide holds three items with flex-basis 100, which leaves 300 pixels of free space. With flex-grow 1, 2 and 1, the free space is split into four shares of 75: A gets one share and is 175 wide, B gets two and is 250, C gets one and is 175.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">container 600, three items with flex-basis 100: 300 left over</text><rect x=\"20\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A 100</text><rect x=\"120\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">B 100</text><rect x=\"220\" y=\"34\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C 100</text><rect x=\"320\" y=\"34\" width=\"300\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"470\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">free space 300</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">flex-grow 1, 2, 1: the 300 is split in 4 shares of 75</text><rect x=\"20\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"120\" y=\"106\" width=\"75\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"107.5\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A = 100 + 75 = 175</text><rect x=\"195\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"295\" y=\"106\" width=\"150\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">B = 100 + 150 = 250</text><rect x=\"445\" y=\"106\" width=\"100\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"545\" y=\"106\" width=\"75\" height=\"30\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532.5\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C = 100 + 75 = 175</text></svg>", "caption": "flex-grow shares out the space left over, not the whole width: B is not twice as wide as A."}
```

The books start at 100 each, so the free space is 600 − 300 = **300**. The grow values add up to 4, so each share is 300 / 4 = 75. A gets one share, **175**; B gets two, **250**; C gets one, **175**. The important part is what did not happen: **B is not twice as wide as A**. `flex-grow` shares out the space that is left, not the whole width. To make B twice as wide, the bases have to be zero as well, which the shorthand in section 09 does.

## Shrinking

The second shelf on the same page gives each book `flex-basis: 300px`, 900 in all on a 600 shelf, and `flex-shrink: 2` to B:

```
ana@laptop:~/site$ probe grow.html box '#shrink .book'
div.book.a  x 0      y 32     width 225    height 24
div.book.b  x 225    y 32     width 150    height 24
div.book.c  x 375    y 32     width 225    height 24
```

The shortfall is 300. Shrinking is weighted by the shrink value **times the basis**, so a large item gives up more than a small one: here the bases are equal, the weights are 1, 2 and 1, and the 300 is taken away as 75, 150 and 75. A is **225**, B **150**, C **225**. The weighting by basis exists so that a small item does not shrink to nothing while a large one hardly moves.

Shrinking has a floor, and it is the subject of the next section, because it is the most common Flexbox bug there is.
