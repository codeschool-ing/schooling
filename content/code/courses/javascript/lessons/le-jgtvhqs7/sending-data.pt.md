---
title: Enviando dados
version: 1
---

Para mandar dados, o `fetch` recebe um segundo argumento: **o método, os cabeçalhos e um corpo**. Um
formulário que acrescenta um livro lê os campos (aula 12), monta um objeto e o manda como JSON:

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

- **`method: "POST"`** diz que esta requisição cria algo, enquanto um `fetch` simples é um `GET`;
- **`body: JSON.stringify(book)`** são os dados como texto. O `fetch` não converte um objeto por você;
- **o cabeçalho `content-type` diz ao servidor que o corpo é JSON.** Sem ele o servidor precisa
  adivinhar, e muitos recusam;
- o ano foi convertido com `Number` antes do envio, porque campos de formulário são strings (aula 2),
  e o servidor guarda o que recebe.

O servidor respondeu **`201 Created`** com o livro salvo e o seu id novo. A segunda execução apagou o
título, e o servidor recusou com **`422`** e o motivo, que o `getJSON` transformou na mensagem
`not saved: /api/books: 422 a book needs a title`. **A conferência `required` do próprio navegador
(aula 12) é uma comodidade; a do servidor é a que conta**, porque uma requisição pode ser feita sem a
página.

O próprio `FormData` pode ser o corpo, `body: new FormData(form)`, e o `fetch` então o manda no
formato que um formulário HTML mandaria, com o cabeçalho certo acrescentado sozinho. Qual usar é
decidido pelo que o servidor espera, e uma API feita para JavaScript em geral espera JSON.
