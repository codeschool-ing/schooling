---
title: fetch: pedindo a um servidor
version: 1
---

**`fetch(url)` manda uma requisição HTTP e devolve uma promessa de um `Response`.** O corpo da
resposta chega separado, e `response.json()` é uma segunda promessa que o lê e o interpreta como
JSON. O servidor do laboratório responde `/api/books` com três livros:

```html
<!doctype html>
<ul id="books"></ul>
<script type="module">
  const response = await fetch("/api/books");
  console.log(response.status, response.ok, response.headers.get("content-type"));

  const books = await response.json();
  console.log(Array.isArray(books), books.length);

  document.querySelector("#books").replaceChildren(
    ...books.map((b) => {
      const li = document.createElement("li");
      li.textContent = `${b.title} (${b.year})`;
      return li;
    }),
  );
</script>
```

```
ana@dev:~/js$ page list.html --network --dom '#books'
net  GET /list.html  200  document  495 B
200 true application/json; charset=utf-8
true 3
net  GET /api/books  200  fetch  239 B
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

O `--network` faz o `page` listar toda requisição que a página fez, como o painel de rede do navegador
faria (a aula 22 abre o de verdade). Duas requisições: **a própria página, e o `fetch`, respondido com
`200` e 239 bytes de JSON**.

## Lendo o `Response`

- `response.status` é o código de status HTTP, `200`, e **`response.ok` é `true` para qualquer status
  de 200 a 299**. A aula 6 de `web-fundamentals` cobre o que os códigos significam;
- `response.headers.get("content-type")` é como o servidor rotulou o corpo,
  `application/json; charset=utf-8` aqui. As próximas seções o conferem antes de confiar no corpo;
- **`response.json()` lê o corpo inteiro e o interpreta**, e o resultado foi um array de três livros,
  transformados em itens de lista com `textContent` como a aula 11 fez.

A página usou `<script type="module">` para poder escrever `await` no nível de cima (aula 9). A
requisição foi para `/api/books` na própria origem da página, então nenhuma regra de origem cruzada
se aplicou; pedir a outro servidor a partir de uma página traz o CORS, que a aula 7 de `front-quality`
explica.
