---
title: box-sizing: what width means
version: 2
---

Section 02 measured a card with `width: 300px` drawn 348 pixels wide. That is the default, and it is called **`content-box`**: `width` sets the content area, and padding and border are added outside it. It makes arithmetic of every layout: a column meant to be a third of the page, with padding, is wider than a third, and three of them no longer fit in a row.

**`box-sizing: border-box`** changes what `width` means. Here is the same card, `box.html` saved as `border-box.html`, with that one declaration added to the `.card` rule, after `margin: 30px;`:

```
ana@laptop:~/site$ probe border-box.html box .card box '.card p'
article.card  x 30     y 30     width 300    height 84
p  x 54     y 54     width 252    height 36
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"The same card twice, both with width 300px, padding 20 and a 4-pixel border. With box-sizing content-box, the default, the content is 300 wide and the card is drawn 348 wide. With border-box, the card is drawn 300 wide and the content gets the 252 that is left.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">content-box</text><rect x=\"20\" y=\"34\" width=\"313.2\" height=\"76\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4\"></rect><rect x=\"41.6\" y=\"54\" width=\"270\" height=\"36\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"176.6\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">content 300</text><line x1=\"20\" y1=\"124\" x2=\"333.2\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"20\" y1=\"119\" x2=\"20\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"333.2\" y1=\"119\" x2=\"333.2\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"176.6\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">drawn 348 wide</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">border-box</text><rect x=\"380\" y=\"34\" width=\"270\" height=\"76\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4\"></rect><rect x=\"401.6\" y=\"54\" width=\"226.8\" height=\"36\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"515\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">content 252</text><line x1=\"380\" y1=\"124\" x2=\"650\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"119\" x2=\"380\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"650\" y1=\"119\" x2=\"650\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"515\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">drawn 300 wide</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Both say width: 300px. content-box adds padding and border outside it;</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">border-box fits them inside it, and the content gets what is left.</text></svg>", "caption": "border-box makes width mean the width you see."}
```

Now the card is **300 wide**, as written, and the padding and border are fitted inside it: the content area gets what is left, **252**. The height did not change, 84, because the height was never set; it comes from the content, and padding and border are still added around it.

## The rule almost every stylesheet starts with

Because `border-box` is so much easier to reason about, nearly every modern stylesheet switches it on for everything, at the very top:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

The selector is the universal selector and the two pseudo-elements from lesson 5, which the universal selector does not reach on its own. From then on, a `width` is the width you will see, and a column of a third with padding is a third.

The default is `content-box` for a historical reason and not because it is useful: CSS was specified that way in 1996, a browser of the time did the opposite, and when standards mode arrived the standard won. `box-sizing` was added later so that authors could choose.
