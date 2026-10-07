---
title: Inheritance
version: 1
---

Some values are never set on an element by any rule; they come down from its parent. That is **inheritance**, and it is why setting a font on `<body>` changes the font of every paragraph on the page without a rule for paragraphs. Here is `inherit.css`:

```css
main {
  color: #2f6f4e;
  font-family: Georgia, serif;
  border: 2px solid #2f6f4e;
}
.more { color: inherit; }
.cancelled { color: #8a1c1c; }
.cancelled h2 { color: initial; }
```

The colour, the font and the border are all set on `<main>`. Here is what reached the note, two levels down inside an article:

```
ana@laptop:~/site$ probe inherit.html style .note color,font-family,border-top-width rules .note color
p.note  color: rgb(47, 111, 78)
p.note  font-family: Georgia, serif
p.note  border-top-width: 0px
.note  no rule sets color
```

The note is green and in Georgia, **and no rule sets its colour**: `probe rules` found nothing to list, because nothing matched. The value was inherited from `<main>`, through the `<article>`. The border did not come down: the note's border is 0 pixels.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"Inheritance from main, which sets color #2f6f4e and a 2px border. The paragraph .note inherits the colour and has no border. The link .more sets color: inherit, which takes the parent&#x27;s green over the browser&#x27;s link blue. .cancelled h2 sets color: initial and goes back to black. Colour and font flow down the tree; border does not.\"><line x1=\"360\" y1=\"70\" x2=\"140\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"70\" x2=\"360\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"70\" x2=\"580\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"270\" y=\"18\" width=\"180\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">main</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: #2f6f4e</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">border: 2px</text><rect x=\"65\" y=\"132\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">p.note</text><text x=\"140\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: inherited</text><text x=\"140\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">border: none</text><rect x=\"265\" y=\"132\" width=\"190\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">a.more</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: inherit</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(beats the link blue)</text><rect x=\"495\" y=\"132\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">.cancelled h2</text><text x=\"580\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color: initial</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">back to black</text><text x=\"20\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">color and font-family flow down the tree; border does not.</text><text x=\"20\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">inherit takes the parent’s value on purpose; initial takes the property’s own default.</text></svg>", "caption": "Inherited properties are the ones about text; the box properties stay with the box that set them."}
```

**Inherited properties are, roughly, the ones about text**: `color`, `font-family`, `font-size`, `font-weight`, `line-height`, `text-align`, `letter-spacing`, `visibility`, and the list properties. **Properties about the box are not inherited**: `border`, `margin`, `padding`, `width`, `height`, `background`, `display`. That split is what you would want: a border on an article that also appeared on every paragraph inside it would be useless.

A value set by any rule, even the browser's default, beats an inherited one, because inheritance only fills in where nothing matched. That is why a link inside a green paragraph is still blue:

```
ana@laptop:~/site$ probe events.html rules .more color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
computed color: rgb(0, 0, 238)
```

The browser's own stylesheet has a rule for links, `a:-webkit-any-link`, that sets `color: -webkit-link`, its internal name for the link blue, and a matched rule beats inheritance.

## Four keywords

Any property accepts four keywords that ask for a value from somewhere else:

- **`inherit`**: take the parent's value, even for a property that does not inherit by default, or even when a rule would otherwise apply. `.more { color: inherit; }` beat the browser's blue.
- **`initial`**: take the property's own initial value, as the specification defines it. For `color` that is black.
- **`unset`**: `inherit` if the property inherits, `initial` if it does not.
- **`revert`**: go back to what the browser's default stylesheet would have given.

```
ana@laptop:~/site$ probe inherit.html style .more color style '.cancelled h2' color
a.more  color: rgb(47, 111, 78)
h2  color: rgb(0, 0, 0)
```

The link took the green of its parent. The cancelled event's heading took `color: initial`, which is black, `rgb(0, 0, 0)`, even though its article sets red. `initial` is the specification's default, not the browser's default style and not the parent's colour, which surprises people; `revert` is the one that means "as if I had not styled this".
