---
title: Styling through the boundary
version: 1
---

**The page cannot reach into a shadow tree with selectors, but three things cross the boundary on purpose:
inherited properties, custom properties, and parts the element names.** That is enough for a design
system, and it is the reason the tokens from lesson 5 are custom properties rather than values written
into each component.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"What crosses the shadow boundary. From the page, four things are tried against the row&#x27;s button. The selector main button with a red background is stopped at the boundary. Inherited properties such as color and font cross it. Custom properties such as --accent cross it, which is how the tokens reach the button. A rule on planner-session::part(button) crosses it, because the element named that part.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the page</text><text x=\"560\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the shadow tree</text><line x1=\"470\" y1=\"36\" x2=\"470\" y2=\"224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></line><text x=\"470\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the boundary</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main button { background: red }</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a selector: stopped</text><line x1=\"260\" y1=\"60\" x2=\"462\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"458\" y1=\"54\" x2=\"466\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><line x1=\"458\" y1=\"66\" x2=\"466\" y2=\"54\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">color, font-family, line-height</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inherited: crosses</text><line x1=\"260\" y1=\"104\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 548.4,132.5 548.9,126.3\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">--accent: #2f6f4e</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a custom property: crosses</text><line x1=\"260\" y1=\"148\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 548.8,133.6 548.5,127.3\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">planner-session::part(button)</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a named part: crosses</text><line x1=\"260\" y1=\"192\" x2=\"556\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,130.0 549.4,134.6 548.1,128.5\" fill=\"var(--phosphor)\"></polygon><rect x=\"560\" y=\"110\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;button part=\"button\"&gt;</text></svg>", "caption": "Selectors stop at a shadow root; inherited values, custom properties and named parts are the ways in."}
```

## Inherited properties, and custom properties

The shadow tree inherits from its host the way any child inherits from its parent. `color`,
`font-family`, `line-height` and every other inherited property flow in, so a row in a page set in a
serif face is set in that face too. **Custom properties inherit as well**, and every token in
`tokens.css` is one. That is why the element's button can say `background: var(--accent, ButtonFace)`
and get the planner's green: the page sets `--accent` on `:root`, the value inherits down to the host, and
from the host into the shadow tree. A theme switch that changes `--accent` changes the button with it, and
the element needs no code for it.

The second value in each `var()` is a **fallback**, used when the property is not set at all, which is
the case in a page that never loaded `tokens.css`. `ButtonFace`, `ButtonText` and `GrayText` are system
colours: whatever the browser and the user's settings use for a plain button and for dimmed text. An
element with a fallback like that still looks like a button in somebody else's page.

`button` does not inherit its font by default, which is why the style sheet says `font: inherit`; without
it the button would be set in the browser's own small face whatever the page chose.

## `:host`, from the inside

Inside the shadow tree, `:host` is the element itself. The style sheet uses it to make the row a flex
container with a gap between its parts. **A rule in the page wins over `:host`**: if the page writes
`planner-session { display: block }`, the row is a block. That ordering is deliberate, so a page can
always place and size the element it put there, while the element decides what it looks like inside.

## `::part`, for what the element offers

The button carries `part="button"`. A part is a named piece the element lets the page style directly:

```css
planner-session::part(button) {
  border-radius: 0;
}
```

The page's `main button { background: red }` does not reach that button, and this rule does, because the
element named it. A part is a promise like an exported function: rename or remove it and a page that
styled it breaks. Name only the pieces you mean to support, and say which ones in the library's
documentation.

## The light content stays the page's

*JavaScript*, the text between the tags, is in the light DOM and is only shown at the slot. So the page's
own rules style it, exactly as if it were anywhere else in the page; the element's style sheet can reach
it only through `::slotted()`, and only the top-level elements that were slotted, not what is inside
them. The next section is about slots.
