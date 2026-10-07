---
title: rem and em: units that follow the text
version: 1
---

Two units measure in multiples of a font size, and the difference between them is which font size.

**`rem` is a multiple of the root element's font size**, the font size of `<html>`. The root's default is **16 pixels** in every major browser, so `1rem` is 16px and `1.1rem`, lesson 5's first rule, was 17.6px. And here is what pixels cannot do: **a reader who sets their browser's default text size to 20 makes every `rem` on every page 25 per cent larger**, layout and all. That setting exists in every browser, and it is used by people with low vision, people reading on a television, and people who are simply tired. A font size in `rem` honours it; a font size in `px` ignores it.

**`em` is a multiple of the element's own font size**, which it inherits from its parent unless set. Inside a paragraph with 20-pixel text, `1em` is 20px. Used for padding on a button, `padding: 0.5em 1em` grows and shrinks with the button's text, which is exactly right.

## Where em compounds

Used for `font-size` itself, `em` is a multiple of the **parent's** font size, and it multiplies down the tree. Here is a list three levels deep, once with `0.8em` on each item and once with `0.8rem`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sections · Andorinha Books</title>
    <style>
      .em li { font-size: 0.8em; }
      .rem li { font-size: 0.8rem; }
      .em li, .rem li { padding-left: 1em; }
    </style>
  </head>
  <body>
    <ul class="em">
      <li>Fiction
        <ul>
          <li>Brazilian
            <ul><li>Modernists</li></ul>
          </li>
        </ul>
      </li>
    </ul>
    <ul class="rem">
      <li>Fiction
        <ul>
          <li>Brazilian
            <ul><li>Modernists</li></ul>
          </li>
        </ul>
      </li>
    </ul>
  </body>
</html>
```

```
ana@laptop:~/site$ probe em.html style li font-size
li  font-size: 12.8px
li  font-size: 10.24px
li  font-size: 8.192px
li  font-size: 12.8px
li  font-size: 12.8px
li  font-size: 12.8px
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Font sizes measured in a list three levels deep. With 0.8em on each list item, the sizes compound: 12.8, then 10.24, then 8.192 pixels, because each em is a share of the parent&#x27;s size. With 0.8rem, every level is 12.8 pixels, because rem is a share of the root&#x27;s size.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a list three levels deep, font-size on each li</text><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">0.8em</text><rect x=\"120\" y=\"50\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Fiction</text><text x=\"268.8\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"120\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 1</text><rect x=\"310\" y=\"50\" width=\"112.64\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.8\" fill=\"var(--paper)\">Brazilian</text><text x=\"430.64\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">10.24px</text><text x=\"310\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 2</text><rect x=\"500\" y=\"50\" width=\"90.11\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.2\" fill=\"var(--paper)\">Modernists</text><text x=\"598.11\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">8.192px</text><text x=\"500\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 3</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">0.8rem</text><rect x=\"120\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Fiction</text><text x=\"268.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"120\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 1</text><rect x=\"310\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Brazilian</text><text x=\"458.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"310\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 2</text><rect x=\"500\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Modernists</text><text x=\"648.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"500\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">level 3</text></svg>", "caption": "em multiplies down the tree; rem always starts from the root."}
```

The first list shrinks at every level: **12.8, 10.24, 8.192** pixels, because each `0.8em` is 80 per cent of a parent that was already 80 per cent of its own. Three levels down, the text is barely half the size, and a fourth level would be unreadable. The second list stays at **12.8** at every level, because every `rem` is measured from the same root.

## Which to use

**Font sizes in `rem`.** They follow the reader's setting and do not compound.

**Spacing that belongs to the text in `em`**: the padding inside a button, the gap after a heading. It keeps proportions when the text changes size.

**Spacing in the layout in `rem`**: the gap between cards, the margins of the page. It scales with the reader's setting and is the same everywhere.

**Lines and small details in `px`**: borders, outlines, shadows.
