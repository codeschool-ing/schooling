---
title: Pedindo dados
version: 1
---

**Uma requisição GraphQL é um `POST` HTTP cujo corpo JSON leva a consulta como texto.** O corpo tem
até três chaves: `query`, o texto da consulta; `variables`, um objeto com valores para ela; e
`operationName`, que escolhe uma operação quando o texto tem várias. A consulta em si não é JSON. É
a linguagem própria do GraphQL, escrita dentro de uma string JSON, e é por isso que toda requisição
abaixo tem aspas dentro de aspas.

Uma consulta que começa com um `{` solto é uma leitura sem nome, a forma mais curta que existe.

## Campos e argumentos

Você nomeia os campos que quer, e os argumentos vão entre parênteses depois do campo:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books(authorId: 2) { title year } }"}' | jq -c .
{"data":{"books":[{"title":"A Hora da Estrela","year":1977},{"title":"Perto do Coração Selvagem","year":1943}]},"extensions":{"sqlQueries":1}}
```

Todo campo pedido precisa estar no esquema, e a conferência acontece antes de qualquer coisa rodar.
Um erro de digitação é recusado com **400**, o lugar da consulta onde aconteceu e uma sugestão:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { titel } }"}' -w '%{http_code}\n'
{"errors": [{"message": "Cannot query field 'titel' on type 'Book'. Did you mean 'title'?", "locations": [{"line": 1, "column": 11}]}]}
400
```

**Uma consulta precisa descer até os escalares.** `author` é um objeto, e pedi-lo sem dizer quais
campos dele você quer é recusado do mesmo jeito. Não existe "me dê tudo": um cliente que quer um
campo tem de nomeá-lo, e é isso que mantém a resposta do tamanho da tela.

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ book(id: 1) { author } }"}' -w '%{http_code}\n'
{"errors": [{"message": "Field 'author' of type 'Author!' must have a selection of subfields. Did you mean 'author { ... }'?", "locations": [{"line": 1, "column": 17}]}]}
400
```

## Aliases

As chaves da resposta são os nomes dos campos, então pedir `book` duas vezes daria duas respostas
sob uma chave só. Um **alias** renomeia um campo na resposta, `first:` e `fifth:` aqui, e deixa uma
requisição pedir o mesmo campo com argumentos diferentes:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ first: book(id: 1) { title } fifth: book(id: 5) { title } }"}' | jq -c .
{"data":{"first":{"title":"Dom Casmurro"},"fifth":{"title":"Ensaio sobre a Cegueira"}},"extensions":{"sqlQueries":2}}
```

## Fragments

Um **fragment** é um conjunto de campos com nome que a consulta reaproveita com `...nome`. Uma tela
que desenha o mesmo cartão de livro onde quer que ele apareça escreve os campos do cartão uma vez, e
todo lugar que o espalha recebe os mesmos campos:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ book(id: 6) { ...card } books(authorId: 3) { ...card } } fragment card on Book { title year priceCents }"}' | jq -c .data
{"book":{"title":"Americanah","year":2013,"priceCents":6490},"books":[{"title":"Ensaio sobre a Cegueira","year":1995,"priceCents":5990}]}
```

`on Book` diz em que tipo o fragment se encaixa. O esquema confere isso também: espalhar `card`
dentro de um autor seria recusado.

## Variáveis

Um valor que muda de uma requisição para outra não pertence ao texto da consulta. A consulta declara
uma **variável** com seu tipo, usa a variável onde vai um valor, e os valores viajam à parte, em
`variables`. Distribuída em várias linhas, o que o GraphQL permite em qualquer lugar, a consulta é:

```
query Page($id: ID!) {
  book(id: $id) {
    title
    author { name }
  }
}
```

e a requisição a envia com `{"id": "4"}`:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "query Page($id: ID!) { book(id: $id) { title author { name } } }", "variables": {"id": "4"}}' | jq -c .
{"data":{"book":{"title":"Perto do Coração Selvagem","author":{"name":"Clarice Lispector"}}},"extensions":{"sqlQueries":2}}
```

**Monte consultas com variáveis, nunca colando valores no texto.** Os motivos são os que você conhece
do SQL: um valor colado na consulta pode mudar o sentido dela, e uma consulta cujo texto muda a cada
requisição não pode ser posta em cache nem reconhecida. Com variáveis, o texto de `Page` é o mesmo
para todo livro da loja, e a seção sobre proteger o servidor tira proveito disso. `Page` é o nome da
operação; é opcional, e vale a pena dar, porque é por esse nome que os logs do servidor e as
ferramentas do cliente podem chamar a operação.
