---
title: Every field has a label
version: 1
---

A field with no label is a box and a guess. **`<label>`** is the element that says what a field is for, and the browser does two things with it: it makes the label's text the field's **accessible name**, and it makes clicking the text put the cursor in the field, which matters to anybody whose aim is unsteady and to anybody on a phone.

There are two ways to join a label to its field, and one way people think they have joined them and have not. Here are all three:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Newsletter · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Newsletter</h1>
      <form action="subscribe" method="post">
        <label for="name">Your name</label>
        <input id="name" name="name">

        <label>Email <input name="email" type="email"></label>

        <input name="city" placeholder="City">

        <button>Subscribe</button>
      </form>
    </main>
  </body>
</html>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A label element with for=&quot;name&quot; above an input element with id=&quot;name&quot; and name=&quot;name&quot;. An arrow joins the label&#x27;s for to the input&#x27;s id. Three results: the field&#x27;s accessible name becomes Your name, clicking the words puts the cursor in the field, and the two are joined by the id wherever they sit. The name attribute is separate: it is what the server receives.\"><defs><marker id=\"ah4\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;label for=&quot;name&quot;&gt;Your name&lt;/label&gt;</text><rect x=\"20\" y=\"100\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;input id=&quot;name&quot; name=&quot;name&quot;&gt;</text><path d=\"M148 60 C 148 80, 108 82, 108 98\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah4)\"></path><text x=\"170\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">for names the id of the field</text><text x=\"430\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">name is what the server receives</text><path d=\"M212 98 C 212 84, 330 80, 424 80\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">The field&#x27;s accessible name becomes Your name.</text><text x=\"34\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Clicking the words puts the cursor in the field.</text><text x=\"34\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">The two are joined by the id, wherever they sit.</text></svg>", "caption": "id joins the label to the field; name is a different attribute, for the request."}
```

**With `for` and `id`**, the first field: the label's `for` names the `id` of the field. They can then sit anywhere on the page, which is what lets CSS lay them out freely.

**By wrapping**, the second: the field is inside the label, and nothing needs an `id`. It is shorter, and some layouts are harder to build this way.

**With only a `placeholder`**, the third: the grey text inside the box. Here is what the browser made of the three:

```
ana@laptop:~/site$ probe labels.html tree axe
- main:
  - heading "Newsletter" [level=1]
  - text: Your name
  - textbox "Your name"
  - text: Email
  - textbox "Email"
  - textbox "City"
  - button "Subscribe"
axe: no violations
```

All three fields have a name, including *City*, and axe found nothing. That deserves a careful reading, because it is a case of a check passing on a field that is still badly labelled. When nothing else names a field, the browser falls back to the placeholder, so a screen reader can say *City*. But **the placeholder disappears as soon as somebody types**, so whoever is halfway through the form, or comes back to correct it, sees a filled box and no indication of what it was for. Designs tend to style it in a pale grey that is hard to read. And clicking it does nothing a click on the box would not, where a label is a second, larger target. The label is required; a placeholder can add an example, *05422-000*, alongside it, never replace it.

## The label is the thing you click

A test that takes two seconds: click on the words next to a field. If the cursor lands in the field, they are joined. If nothing happens, they are two unrelated elements that happen to sit next to each other, and a screen reader user hears a box with no name. DevTools' accessibility pane shows the computed name too; `probe describe`, in section 08, prints it.
