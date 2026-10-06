---
title: Choices: radio buttons, checkboxes, select and textarea
version: 1
---

Not every answer is typed. When the possible answers are known in advance, the form offers them, and HTML has an element for each shape of choice.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Order · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Order a book</h1>
      <form action="order" method="get">
        <fieldset>
          <legend>Format</legend>
          <label><input type="radio" name="format" value="paperback" checked> Paperback</label>
          <label><input type="radio" name="format" value="hardback"> Hardback</label>
        </fieldset>
        <fieldset>
          <legend>Extras</legend>
          <label><input type="checkbox" name="extra" value="wrap"> Gift wrap</label>
          <label><input type="checkbox" name="extra" value="card"> A card</label>
          <label><input type="checkbox" name="extra" value="bag"> A cloth bag</label>
        </fieldset>
        <label for="shop">Collect from</label>
        <select id="shop" name="shop">
          <option value="pinheiros">Pinheiros</option>
          <option value="centro" selected>Centro</option>
        </select>
        <label for="notes">Notes</label>
        <textarea id="notes" name="notes" rows="3"></textarea>
        <button>Order</button>
      </form>
    </main>
  </body>
</html>
```

**Radio buttons are one choice from several.** What makes them a group is the shared `name`: both are `name="format"`, so checking one unchecks the other. Each carries the `value` that is sent when it is the one checked. `checked` marks the starting choice; without it, a group can be sent with nothing chosen at all.

**Checkboxes are any number of independent yes-or-no answers.** These three share `name="extra"` too, but sharing a name does not tie them together: each is checked on its own.

**`<select>` is one choice from a list**, drawn as a drop-down. Each `<option>` has the `value` sent and the text shown, and `selected` picks the starting one. **`<textarea>` is free text over several lines**, and it is one of the elements from lesson 1 that read their content as text, so it always needs its closing tag.

**`<fieldset>` and `<legend>` group related controls under a caption.** Without them, a screen reader on the radio button hears *Paperback, radio button* and has to guess the question. With them:

```
ana@laptop:~/site$ probe choices.html tree
- main:
  - heading "Order a book" [level=1]
  - group "Format":
    - text: Format
    - radio "Paperback" [checked]
    - text: Paperback
    - radio "Hardback"
    - text: Hardback
  - group "Extras":
    - text: Extras
    - checkbox "Gift wrap"
    - text: Gift wrap
    - checkbox "A card"
    - text: A card
    - checkbox "A cloth bag"
    - text: A cloth bag
  - text: Collect from
  - combobox "Collect from":
    - option "Pinheiros"
    - option "Centro" [selected]
  - text: Notes
  - textbox "Notes"
  - button "Order"
```

Each group is a **group** named by its legend, so the reader hears *Format, group* before the options, and the select is a **combobox** named by its label.

## What the choices send

Sent untouched, and then with a format, two extras and a note chosen:

```
ana@laptop:~/site$ probe choices.html send button
GET /order?format=paperback&shop=centro&notes=
ana@laptop:~/site$ probe choices.html check 'input[value=hardback]' check 'input[value=wrap]' check 'input[value=bag]' fill '#notes' 'Gift for Ana, 8 Oct' send button
GET /order?format=hardback&extra=wrap&extra=bag&shop=centro&notes=Gift+for+Ana%2C+8+Oct
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The order form&#x27;s seven controls on the left, and the request the browser builds from them on the right. The checked radio format=hardback, the checked boxes extra=wrap and extra=bag, the selected shop=centro and the empty notes= are sent. The unchecked radio and the unchecked box are not. The request reads GET /order?format=hardback&amp;extra=wrap&amp;extra=bag&amp;shop=centro&amp;notes=.\"><defs><marker id=\"ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">what is in the form</text><rect x=\"20\" y=\"34\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">format=hardback</text><text x=\"340\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">radio, checked</text><rect x=\"20\" y=\"68\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">format=paperback</text><text x=\"340\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">radio, not checked</text><rect x=\"20\" y=\"102\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">extra=wrap</text><text x=\"340\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, checked</text><rect x=\"20\" y=\"136\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">extra=card</text><text x=\"340\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, not checked</text><rect x=\"20\" y=\"170\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">extra=bag</text><text x=\"340\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checkbox, checked</text><rect x=\"20\" y=\"204\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shop=centro</text><text x=\"340\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">select, chosen option</text><rect x=\"20\" y=\"238\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">notes=</text><text x=\"340\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">textarea, empty</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">what the browser sends</text><rect x=\"380\" y=\"34\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">GET /order?</text><text x=\"394\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">format=hardback</text><text x=\"394\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&amp;extra=wrap&amp;extra=bag</text><text x=\"394\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&amp;shop=centro&amp;notes=</text><path d=\"M352 120 C 366 120, 366 90, 378 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah3)\"></path><text x=\"380\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Every field with a name and a value</text><text x=\"380\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">goes, in the order of the page.</text><text x=\"380\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A box nobody ticked does not</text><text x=\"380\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">go at all; an empty text field</text><text x=\"380\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">goes with nothing after the =.</text></svg>", "caption": "A form is a list of name=value pairs. The dashed rows are controls that exist on the page and send nothing."}
```

The first request has no `extra` in it at all. **An unchecked checkbox sends nothing**, not `extra=` and not `extra=off`. The server learns that nobody wanted gift wrap only from its absence, so it has to treat a missing name as *no*. The second request has `extra` twice, once per checked box, and the server reads the name as a list. And `notes=` is sent even when empty, because a text field always has a value, even an empty one.
