---
title: Asking for data
version: 1
---

**A GraphQL request is an HTTP `POST` whose JSON body carries the query as a string.** The body has
up to three keys: `query`, the text of the query; `variables`, an object of values for it; and
`operationName`, which picks one operation when the text holds several. The query itself is not
JSON. It is GraphQL's own language, written inside a JSON string, which is why every request below
has quotes inside quotes.

A query that starts with a bare `{` is a read with no name, the shortest form there is.

## Fields and arguments

You name the fields you want, and arguments go in brackets after a field:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books(authorId: 2) { title year } }"}' | jq -c .
{"data":{"books":[{"title":"A Hora da Estrela","year":1977},{"title":"Perto do Coração Selvagem","year":1943}]},"extensions":{"sqlQueries":1}}
```

Every field you ask for must be in the schema, and the check happens before anything runs. A typing
mistake is refused with **400**, the place in the query where it happened, and a suggestion:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ books { titel } }"}' -w '%{http_code}\n'
{"errors": [{"message": "Cannot query field 'titel' on type 'Book'. Did you mean 'title'?", "locations": [{"line": 1, "column": 11}]}]}
400
```

**A query must go all the way down to scalars.** `author` is an object, and asking for it without
saying which of its fields you want is refused the same way. There is no "give me everything":
a client that wants a field has to name it, and that is what keeps an answer the size of the
screen.

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ book(id: 1) { author } }"}' -w '%{http_code}\n'
{"errors": [{"message": "Field 'author' of type 'Author!' must have a selection of subfields. Did you mean 'author { ... }'?", "locations": [{"line": 1, "column": 17}]}]}
400
```

## Aliases

The keys of the answer are the names of the fields, so asking for `book` twice would give two
answers under one key. An **alias** renames a field in the answer, `first:` and `fifth:` here, and
lets one request ask the same field with different arguments:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ first: book(id: 1) { title } fifth: book(id: 5) { title } }"}' | jq -c .
{"data":{"first":{"title":"Dom Casmurro"},"fifth":{"title":"Ensaio sobre a Cegueira"}},"extensions":{"sqlQueries":2}}
```

## Fragments

A **fragment** is a named set of fields that a query can reuse with `...name`. A screen that draws
the same card for a book wherever it appears writes the card's fields once, and every place that
spreads it gets the same fields:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "{ book(id: 6) { ...card } books(authorId: 3) { ...card } } fragment card on Book { title year priceCents }"}' | jq -c .data
{"book":{"title":"Americanah","year":2013,"priceCents":6490},"books":[{"title":"Ensaio sobre a Cegueira","year":1995,"priceCents":5990}]}
```

`on Book` says which type the fragment fits. The schema checks that too: spreading `card` inside an
author would be refused.

## Variables

A value that changes from request to request does not belong inside the query text. The query
declares a **variable** with its type, uses it where a value goes, and the values travel separately
in `variables`. Laid out on several lines, which GraphQL allows anywhere, the query is:

```
query Page($id: ID!) {
  book(id: $id) {
    title
    author { name }
  }
}
```

and the request sends it with `{"id": "4"}`:

```
ana@api:~/shelf$ curl -s localhost:8000/graphql -H 'Content-Type: application/json' -d '{"query": "query Page($id: ID!) { book(id: $id) { title author { name } } }", "variables": {"id": "4"}}' | jq -c .
{"data":{"book":{"title":"Perto do Coração Selvagem","author":{"name":"Clarice Lispector"}}},"extensions":{"sqlQueries":2}}
```

**Build queries with variables, never by pasting values into the text.** The reasons are the ones
you know from SQL: a value pasted into the query can change its meaning, and a query whose text
changes with every request can neither be cached nor recognised. With variables, the text of
`Page` is the same for every book in the shop, which the section on protecting the server makes use
of. `Page` is the operation's name; it is optional, and worth giving, because it is what a
server's logs and a client's tools can call the operation by.
