---
title: Os métodos, e o que cada um promete
version: 1
---

O HTTP tem uma lista curta de métodos, e cada um vem com duas promessas em que os clientes confiam sem
perguntar. Um método é **seguro** se não muda nada no servidor, e **idempotente** se enviá-lo duas
vezes deixa o servidor exatamente como enviá-lo uma vez deixou.

| método | o que faz com um recurso | seguro | idempotente |
|---|---|---|---|
| `GET` | lê | sim | sim |
| `POST` | cria um dentro de uma coleção, ou faz algo que não cabe em nenhum outro método | não | **não** |
| `PUT` | substitui pelo corpo, inteiro | não | sim |
| `PATCH` | muda os campos que o corpo cita e deixa o resto | não | não prometido |
| `DELETE` | remove | não | sim |

**Essas promessas são o que permite que a rede ajude você.** Um navegador busca links de antemão porque
o `GET` é seguro. Um cliente cuja conexão caiu no meio de um `PUT` o envia de novo, porque ele é
idempotente e uma segunda cópia não faz mal. Ninguém pode repetir um `POST` às cegas, porque duas cópias
podem criar dois pedidos; a aula 2 mostra o cabeçalho que torna um `POST` seguro de repetir. Quebre uma
promessa, um `GET /books/7/delete` por exemplo, e a rede vai agir conforme a promessa mesmo assim: um
robô que seguisse links esvaziaria o catálogo.

## POST cria

Um livro novo vai para a coleção, e o servidor decide o id dele. A resposta é **201 Created**, e o
cabeçalho `Location` diz onde o item novo mora:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 124
Location: /v1/books/7

{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990, "stock": 0}
```

A mesma requisição uma segunda vez não é uma segunda cópia do livro. Ela é recusada com **409
Conflict**, porque o ISBN é único no banco, e o corpo diz qual regra foi quebrada. O
`-w '%{http_code}\n'` pede ao curl que imprima o status depois do corpo:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 3990}'
{"error": "conflict: UNIQUE constraint failed: books.isbn"}
409
```

Essa recusa são os dados se protegendo, e é sorte, não o método. Uma tabela sem coluna única teria
guardado o mesmo livro duas vezes, com os ids 7 e 8.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Enviar o mesmo PUT duas vezes deixa o shelf no mesmo estado que enviá-lo uma vez: o livro 7 custa 4190 depois do primeiro e depois do segundo. Enviar o mesmo POST duas vezes tenta criar dois livros; aqui o segundo é recusado com 409 porque o ISBN já existe, e sem essa regra teria criado o livro 8.\"><defs><marker id=\"idem-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">PUT /v1/books/7, duas vezes</text><rect x=\"20\" y=\"40\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text><text x=\"115.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">livro 7 custa 4190</text><rect x=\"250\" y=\"40\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text><text x=\"345.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">livro 7 custa 4190</text><line x1=\"210\" y1=\"65\" x2=\"248\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#idem-ah)\"></line><text x=\"470\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mesmo estado: idempotente</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">POST /v1/books, duas vezes</text><rect x=\"20\" y=\"155\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">201</text><text x=\"115.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">livro 7 criado</text><rect x=\"250\" y=\"155\" width=\"190\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">409</text><text x=\"345.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ISBN já existe</text><line x1=\"210\" y1=\"180\" x2=\"248\" y2=\"180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#idem-ah)\"></line><text x=\"470\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um segundo livro, a não ser que</text><text x=\"470\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma regra nos dados o recuse</text><text x=\"250\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem o ISBN UNIQUE: 201, livro 8</text></svg>", "caption": "Idempotente quer dizer que a segunda requisição idêntica não muda nada que a primeira não tenha mudado."}
```

## PUT substitui, PATCH muda

O `PUT` envia o livro inteiro, e o livro passa a ser exatamente aquilo. Enviar o mesmo `PUT` duas vezes
dá a mesma resposta duas vezes, e o mesmo estado, que é o que idempotente quer dizer:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 2}
200
```

Como ele substitui, um `PUT` que deixa campos de fora não é uma mudança menor; é um livro com campos
faltando, e o shelf o recusa. O `PATCH` é o método para "mude só isto":

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PUT localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"stock": 5}'
{"error": "missing fields: author_id, isbn, price_cents, title, year"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/7 -H 'Content-Type: application/json' -d '{"stock": 5}'
{"id": 7, "isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price_cents": 4190, "stock": 5}
200
```

O `PATCH` não é prometido idempotente porque não precisa ser. `{"stock": 5}` é, enviado dez vezes, mas
um patch que dissesse "some um ao estoque" não seria, e o método permite os dois. Os patches do shelf
só definem valores, o que os torna idempotentes na prática; um cliente não tem como saber disso sem que
alguém conte, então também não deve repetir um às cegas.

## DELETE remove

O primeiro `DELETE` responde **204 No Content**: deu certo, e não há nada para devolver. O segundo
responde **404**, porque não sobrou nada para apagar.

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books/7
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X DELETE localhost:8000/v1/books/7
{"error": "no book 7"}
404
```

Um 404 no segundo `DELETE` é uma promessa quebrada? Não. Idempotência é sobre o **estado do
servidor**, não sobre a resposta: depois de um `DELETE` ou de dois, o livro 7 não existe mais. Um
cliente que repete um `DELETE` deve ler um 404 como "já estava feito".

Um método enviado a um endereço que não o aceita responde **405 Method Not Allowed**, e o cabeçalho
`Allow` lista os métodos que aquele endereço aceita. Apagar a coleção inteira não é algo que o shelf
oferece:

```
ana@api:~/shelf$ curl -si -X DELETE localhost:8000/v1/books
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Type: application/json
Content-Length: 43
Allow: GET, POST

{"error": "DELETE needs a book's address"}
```
