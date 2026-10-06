---
title: O que um formulário envia
version: 1
---

Um formulário é um conjunto de controles dentro de um elemento `<form>`, e **todo o trabalho dele é montar uma requisição HTTP**. A aula 6 de `web-fundamentals` explicou requisições: um método, um endereço e às vezes um corpo. O formulário decide os três, a partir dos próprios atributos e dos campos dentro dele. Aqui está a busca do sebo:

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

Dois atributos em `<form>` dizem para onde a requisição vai e como. **`action`** é o endereço, aqui `search`, relativo à página como qualquer outro link. **`method`** é `get` ou `post`; a seção 09 trata da diferença. Ana digita um nome em cada campo e aperta o botão:

```
ana@laptop:~/site$ probe search.html fill '#q' 'Clarice Lispector' fill '#lang' Portuguese send button
GET /search?q=Clarice+Lispector
```

Essa linha é a requisição que o navegador montou: o método, o endereço vindo do `action` e, depois do `?`, a **query string**, os dados do formulário. `Clarice Lispector` virou `Clarice+Lispector`, porque uma URL não pode conter espaço e a codificação de formulário escreve um como `+`.

## O campo que não foi enviado

Ana digitou *Portuguese* no segundo campo, e ele não está na requisição. O motivo é um atributo: o primeiro input tem `name="q"` e o segundo não tem `name` nenhum. **Um campo sem `name` nunca é enviado.** O navegador monta a requisição com pares `nome=valor`, e um campo sem nome não tem o que pôr antes do `=`.

Então três atributos diferentes se confundem fácil, e fazem três trabalhos diferentes:

- **`name`** é o que o servidor recebe: `q=Clarice+Lispector`.
- **`id`** é como a página se refere ao elemento: o rótulo da próxima seção o usa, e o CSS também.
- **`value`** é o dado, digitado pelo leitor ou escrito no HTML como valor inicial.

O servidor é escrito contra o `name`. Renomeie o campo no HTML, de `q` para `query`, e a página continua igual enquanto o servidor deixa de encontrar o que procura. É uma mudança para tratar como mudança numa interface, porque é uma.
