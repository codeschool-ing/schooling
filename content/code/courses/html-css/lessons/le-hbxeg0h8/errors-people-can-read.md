---
title: Errors a reader can find and fix
version: 1
---

The browser's own messages are a start. They appear in a bubble beside the first invalid field and disappear after a few seconds, one field at a time, worded by the browser rather than by you. Most real forms add their own **hints** and **error messages** in the page, written for the form's actual questions, and the work is in joining them to the field so that everyone gets them, not just people who can see where they appear.

The tool for that is **`aria-describedby`**, which names the `id` of one or more elements whose text describes the field. A screen reader reads the field's name, then its description:

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
        <label for="cep">CEP (postcode)</label>
        <input id="cep" name="cep" pattern="[0-9]{5}-[0-9]{3}"
               aria-describedby="cep-hint cep-error" aria-invalid="true"
               value="05422000">
        <p id="cep-hint">Eight digits with a hyphen, as in 05422-000.</p>
        <p id="cep-error">This CEP is missing its hyphen.</p>
        <button>Send the order</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html describe '#email'
role textbox, name "Email", required
ana@laptop:~/site$ probe errors.html describe '#cep'
role textbox, name "CEP (postcode)", description "Eight digits with a hyphen, as in 05422-000. This CEP is missing its hyphen.", invalid
```

The email field from the order form has a **name** and is **required**, and that is all the browser can say about it. The CEP field on the error page also has a **description**, made from the two paragraphs in the order `aria-describedby` lists them: the hint, then the error. And it is marked **invalid**, from `aria-invalid="true"`, which a page sets when its own check fails, so that the state is announced along with the message.

## What makes an error message useful

**Say what is wrong and how to fix it**, in the words of the question: *This CEP is missing its hyphen* beats *Invalid format*, which tells the reader nothing they can act on.

**Show it next to the field**, and keep it until the field is fixed. A message only at the top of the form makes the reader search for the field; a message only in a bubble vanishes before they have read it.

**Never rely on colour alone.** A red border means nothing to somebody who cannot tell red from grey; the words have to be there too. Lesson 5 shows how CSS can style a field the browser considers invalid, and the rule still applies: the style is an addition to the message.

**Do not clear what the reader typed.** A form that comes back from the server with every field empty, because one was wrong, is the commonest reason people give up on one.
