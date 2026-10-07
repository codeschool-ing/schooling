---
title: Native validation
version: 1
---

Before sending a request, the browser can check the values against rules written as attributes. This is **native validation**: no script, nothing to install, and messages in the reader's own language. Here is the bookshop's order form with five rules on it:

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
      <form action="order" method="post">
        <label for="name">Name</label>
        <input id="name" name="name" required>

        <label for="email">Email</label>
        <input id="email" name="email" type="email" required>

        <label for="cep">CEP (postcode)</label>
        <input id="cep" name="cep" pattern="[0-9]{5}-[0-9]{3}">

        <label for="copies">Copies</label>
        <input id="copies" name="copies" type="number" min="1" max="5" value="1">

        <label for="title">Title</label>
        <input id="title" name="title" required minlength="2">

        <button>Send the order</button>
      </form>
    </main>
  </body>
</html>
```

Pressing the button with everything empty:

```
ana@laptop:~/site$ probe order.html send button
nothing was sent
  invalid name: Please fill out this field.
  invalid email: Please fill out this field.
  invalid title: Please fill out this field.
```

**Nothing was sent.** The three `required` fields are empty, and the browser refused to build the request. The other two pass: the CEP is optional, and the number of copies starts at 1. Now with a value in every field, each one wrong in its own way, and `validity` printing what the browser concluded about each:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' 'ana@' fill '#cep' 05422000 fill '#copies' 9 fill '#title' V validity input
input#name  value "Ana Souza"  valid
input#email  value "ana@"  typeMismatch
  message: Please enter a part following '@'. 'ana@' is incomplete.
input#cep  value "05422000"  patternMismatch
  message: Please match the requested format.
input#copies  value "9"  rangeOverflow
  message: Value must be less than or equal to 5.
input#title  value "V"  tooShort
  message: Please lengthen this text to 2 characters or more (you are currently using 1 character).
```

Each attribute produced its own result:

| attribute | the rule | what was wrong | the flag |
| --- | --- | --- | --- |
| `required` | must not be empty | (passes now) | `valueMissing` |
| `type="email"` | shaped like an address | nothing after `@` | `typeMismatch` |
| `pattern` | matches a regular expression, whole | no hyphen | `patternMismatch` |
| `min`, `max` | a number within the range | 9 against a maximum of 5 | `rangeOverflow` |
| `minlength` | at least that many characters | 1 against 2 | `tooShort` |

The messages are written by the browser, and each one names the specific fault. These were printed by a Chromium running in English; a browser set to Portuguese words them in Portuguese, with no change to the page. And with everything right:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' ana@example.com fill '#cep' 05422-000 fill '#copies' 2 fill '#title' 'Vidas Secas' send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=Ana+Souza&email=ana%40example.com&cep=05422-000&copies=2&title=Vidas+Secas
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The sequence when a form is submitted. The reader presses the button or Enter. The browser checks every field. If all are valid, the request is built and sent to the action. If any is invalid, nothing is sent, the first invalid field gets the focus and its message is shown.\"><defs><marker id=\"ah5\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the reader presses</text><text x=\"85\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the button or Enter</text><rect x=\"190\" y=\"70\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the browser checks</text><text x=\"265\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every field</text><rect x=\"390\" y=\"10\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all valid: the request is built</text><text x=\"540\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and sent to the action</text><rect x=\"390\" y=\"130\" width=\"300\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">any invalid: nothing is sent,</text><text x=\"540\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the first invalid field gets focus</text><text x=\"540\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and its message is shown</text><line x1=\"150\" y1=\"95\" x2=\"186\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><path d=\"M340 88 C 365 88, 365 35, 386 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></path><path d=\"M340 102 C 365 102, 365 162, 386 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></path></svg>", "caption": "Native validation runs at the moment of sending, and it can only stop the request; it never changes a value."}
```

## Write rules that are true

A rule written into a form is a claim about the world, and a wrong one stops people who did nothing wrong. A `pattern` for names that allows only letters refuses *D'Ávila* and *Ana-Luísa*; a `maxlength` of 20 on a street refuses real streets. Check names and addresses as little as possible: `required`, and perhaps a maximum length the database actually has. Patterns belong to things with a format somebody defined, like a CEP.

`pattern` is matched against the **whole** value, as if it were written between `^` and `$`, so `[0-9]{5}-[0-9]{3}` accepts `05422-000` and refuses `05422-0001`. Regular expressions have a lesson of their own in the `javascript` course; the patterns in a form are usually short enough to read.
