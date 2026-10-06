---
title: Sending data
version: 1
---

To send data, `fetch` takes a second argument: **the method, the headers, and a body**. A form that
adds a book reads its fields (lesson 12), builds an object, and sends it as JSON:

```html
<!doctype html>
<form id="add">
  <input name="title" value="Macunaíma">
  <input name="year" value="1928">
  <button>Add</button>
</form>
<script type="module">
  import { getJSON } from "./get-json.js";
  const form = document.querySelector("#add");

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const fields = Object.fromEntries(new FormData(form));
    const book = { title: fields.title, year: Number(fields.year) };
    try {
      const saved = await getJSON("/api/books", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(book),
      });
      console.log("saved as id", saved.id, JSON.stringify(saved));
    } catch (err) {
      console.log("not saved:", err.message);
    }
  });
</script>
```

```
ana@dev:~/js$ page post.html --network --do 'click button' --wait 500
net  GET /post.html  200  document  805 B
-- click button
net  GET /get-json.js  200  script  449 B
saved as id 4 {"id":4,"title":"Macunaíma","year":1928}
net  POST /api/books  201  fetch  41 B
ana@dev:~/js$ page post.html --do 'fill [name=title] ' --do 'click button' --wait 500
-- fill [name=title] 
-- click button
[error] Failed to load resource: the server responded with a status of 422 (Unprocessable Entity)
not saved: /api/books: 422 a book needs a title
```

- **`method: "POST"`** says this request creates something, where a plain `fetch` is a `GET`;
- **`body: JSON.stringify(book)`** is the data as text. `fetch` does not convert an object for you;
- **the `content-type` header tells the server the body is JSON.** Without it the server has to
  guess, and many refuse;
- the year was converted with `Number` before sending, because form fields are strings (lesson 2),
  and the server stores what it is given.

The server answered **`201 Created`** with the saved book and its new id. The second run cleared the
title, and the server refused with **`422`** and its reason, which `getJSON` turned into the message
`not saved: /api/books: 422 a book needs a title`. **The browser's own `required` check (lesson 12) is
a convenience; the server's check is the one that counts**, because a request can be made without the
page.

`FormData` itself can be the body, `body: new FormData(form)`, and `fetch` then sends it in the
format an HTML form would, with the right header added automatically. Which one to use is decided by
what the server expects, and an API built for JavaScript usually expects JSON.
