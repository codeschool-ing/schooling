---
title: Recursos e os seus endereços
version: 1
---

**No REST, o endereço nomeia uma coisa e o método diz o que fazer com ela.** A coisa é um **recurso**:
um livro, um autor, a lista dos livros de um autor. Recursos têm duas formas, a **coleção**, que
guarda muitos, e o **item**, que é um deles, e o endereço diz qual é a forma pelo fato de terminar ou
não num id.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Os endereços que o shelf responde, como uma árvore. Debaixo de /v1 há duas coleções, /books e /authors. /books/3 é um item da primeira. /authors/2 é um item da segunda, e /authors/2/books é uma coleção dentro dele. Uma query string, ?author_id=3, filtra /books sem virar um endereço novo.\"><defs><marker id=\"tree-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"80\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/v1</text><rect x=\"160\" y=\"45\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books</text><rect x=\"160\" y=\"165\" width=\"130\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors</text><rect x=\"350\" y=\"20\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books/3</text><rect x=\"350\" y=\"75\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/books?author_id=3</text><rect x=\"350\" y=\"165\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors/2</text><rect x=\"530\" y=\"165\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/authors/2/books</text><line x1=\"100\" y1=\"125\" x2=\"130\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"65\" x2=\"130\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"65\" x2=\"158\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"130\" y1=\"185\" x2=\"158\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"290\" y1=\"58\" x2=\"348\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><line x1=\"290\" y1=\"72\" x2=\"348\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#tree-ah)\"></line><line x1=\"290\" y1=\"185\" x2=\"348\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><line x1=\"490\" y1=\"185\" x2=\"528\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#tree-ah)\"></line><text x=\"225\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">coleção</text><text x=\"225\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">coleção</text><text x=\"420\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a mesma coleção, filtrada</text><text x=\"420\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">item</text><text x=\"605\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma coleção num item</text><text x=\"498\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">item</text></svg>", "caption": "Todo endereço é um substantivo. Os métodos são os verbos, e a próxima seção é sobre eles.", "same": ["item"]}
```

Primeiro a coleção. Todos os livros, reduzidos pelo `jq` a três campos para cada um caber numa linha:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books | jq -c '.[] | {id, title, author_id}'
{"id":1,"title":"Dom Casmurro","author_id":1}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","author_id":1}
{"id":3,"title":"A Hora da Estrela","author_id":2}
{"id":4,"title":"Perto do Coração Selvagem","author_id":2}
{"id":5,"title":"Ensaio sobre a Cegueira","author_id":3}
{"id":6,"title":"Americanah","author_id":4}
```

Um item, desta vez com `-i`, que faz o curl imprimir a linha de status e os cabeçalhos antes do corpo:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/3
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 128

{"id": 3, "isbn": "9786500000030", "title": "A Hora da Estrela", "author_id": 2, "year": 1977, "price_cents": 3490, "stock": 0}
```

Um item que não existe responde **404**, com um corpo que diz isso. Um cliente deveria conseguir
distinguir "não há esse livro" de "não há esse endereço" sem ler texto. A aula 2 dá aos erros uma
forma que um programa consegue ler; por enquanto, quem carrega a informação é o código de status:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:52 GMT
Content-Type: application/json
Content-Length: 24

{"error": "no book 99"}
```

## Uma coleção dentro de um item

Um autor é um item de `/v1/authors`, e os livros do autor são uma coleção que pertence a esse item. O
endereço diz isso aninhando:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/2
{"id": 2, "name": "Clarice Lispector", "country": "BR"}
ana@api:~/shelf$ curl -s localhost:8000/v1/authors/2/books | jq -c '.[] | {id, title}'
{"id":3,"title":"A Hora da Estrela"}
{"id":4,"title":"Perto do Coração Selvagem"}
```

Os mesmos livros podem ser obtidos de outro jeito, **filtrando** a coleção de todos os livros com uma
query string. Filtrar não cria um recurso novo; é a mesma coleção, com menos itens à mostra:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?author_id=3' | jq -c '.[] | {id, title}'
{"id":5,"title":"Ensaio sobre a Cegueira"}
```

Então, qual dos dois? Os dois são comuns, e o shelf responde aos dois de propósito. Aninhe quando a
coisa de dentro só faz sentido dentro da de fora, os itens de um pedido, as respostas a um comentário,
e filtre quando for um entre vários jeitos de recortar uma coleção que existe por conta própria. Livros
existem por conta própria; hoje você os quer por autor, amanhã por ano ou por preço, e uma query string
aceita quantos desses quiser sem um endereço para cada um. **Um nível de aninhamento é o limite
prático.** `/authors/2/books/4/reviews` se lê bem e obriga todo cliente a montar caminhos de quatro
partes para chegar a uma resenha que já tem um id só dela.

## O que não cabe num endereço

**Um verbo.** O desenho errado mais comum coloca a ação no caminho, `/getBooks`, `/createBook`,
`/deleteBook?id=7`, e usa `GET` ou `POST` para todos eles. O shelf não tem endereço assim:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/v1/getBooks
404
```

O método é o verbo, e eles são poucos. É esse o ponto: todo cliente HTTP, proxy e cache do mundo já
sabe o que `GET` e `DELETE` prometem. Ninguém sabe o que `/deleteBook` faz sem ler a sua
documentação.

**Algo que pode mudar.** O shelf endereça um livro pelo `id`, um número que o banco deu a ele, e não
pelo ISBN, embora o ISBN também seja único. Um endereço é algo que outras pessoas guardam: num
favorito, em outro banco, num log. Um identificador que vem do mundo, um título, um ISBN que uma editora
corrige, um endereço de e-mail, pode mudar, e toda cópia guardada do endereço passa a apontar para nada
ou para outra coisa. Um id que o sistema inventa e nunca reaproveita para outra coisa não muda.

Algumas convenções valem a pena sem motivo mais profundo do que o fato de todo mundo segui-las:
coleções são **substantivos no plural** (`/books`, não `/book`), endereços ficam em minúsculas com
hífens entre as palavras, e uma barra no final não significa nada. A única expressão regular do shelf
aceita `/v1/books/` e `/v1/books` do mesmo jeito, que é a escolha tolerante.
