---
title: What a form sends
version: 1
---

A form is a set of controls inside a `<form>` element, and **its whole job is to build one HTTP request**. `web-fundamentals` lesson 6 explained requests: a method, an address, and sometimes a body. The form decides all three, from its own attributes and from the fields inside it. Here is the bookshop's search:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Search · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Search the shelves</h1>
      <form action="search" method="get">
        <label for="q">Title or author</label>
        <input id="q" name="q" type="search">
        <label for="lang">Language</label>
        <input id="lang">
        <button>Search</button>
      </form>
    </main>
  </body>
</html>
```

Two attributes on `<form>` say where the request goes and how. **`action`** is the address, here `search`, relative to the page like any other link. **`method`** is `get` or `post`; section 09 is about the difference. Ana types a name in each field and presses the button:

```
ana@laptop:~/site$ probe search.html fill '#q' 'Clarice Lispector' fill '#lang' Portuguese send button
GET /search?q=Clarice+Lispector
```

That line is the request the browser built: the method, the address from `action`, and after the `?` the **query string**, the form's data. `Clarice Lispector` became `Clarice+Lispector`, because a URL cannot contain a space and the form encoding writes one as `+`.

## The field that was not sent

Ana typed *Portuguese* in the second field, and it is not in the request. The reason is one attribute: the first input has `name="q"` and the second has no `name` at all. **A field without a `name` is never sent.** The browser builds the request from pairs of `name=value`, and a field with no name has nothing to put before the `=`.

So three different attributes are easy to confuse, and they do three different jobs:

- **`name`** is what the server receives: `q=Clarice+Lispector`.
- **`id`** is how the page refers to the element: the label in the next section uses it, and so does CSS.
- **`value`** is the data, typed by the reader or written in the HTML as a starting value.

The server is written against the `name`. Rename the field in the HTML, `q` to `query`, and the page still looks the same while the server stops finding what it looks for. That is a change to treat as a change to an interface, because it is one.
