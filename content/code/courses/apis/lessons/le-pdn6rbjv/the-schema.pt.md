---
title: O esquema é o contrato
version: 1
---

**Uma API GraphQL é descrita pelo seu esquema, e nada chega a um resolver sem antes ser conferido
contra ele.** O esquema lista cada tipo que a API tem, cada campo de cada tipo e o tipo de cada
campo. Uma consulta que pede algo que o esquema não declara é recusada antes de qualquer código
rodar.

O nome engana as pessoas de um jeito específico. **GraphQL não é uma linguagem de consulta para o
seu banco de dados**, como o SQL é. Ele consulta os tipos da API, e o esquema não diz nada sobre de
onde vêm os valores deles. No `graph.py` um livro tem `priceCents` onde a tabela tem `price_cents`,
e não tem `author_id` nenhum: o esquema é o que o cliente vê, e o servidor decide como produzir isso.

Este é o esquema do `graph.py`, escrito na **linguagem de definição de esquema**, a SDL:

```
type Query {
  books(authorId: ID): [Book!]!
  book(id: ID!): Book
  author(id: ID!): Author
}

type Mutation {
  setStock(bookId: ID!, stock: Int!): Book
}

type Book {
  id: ID!
  isbn: String!
  title: String!
  year: Int!
  priceCents: Int!
  stock: Int!
  author: Author!
}

type Author {
  id: ID!
  name: String!
  country: String!
  books: [Book!]!
}
```

## Tipos, escalares e campos

`Book` e `Author` são **tipos objeto**: cada um tem campos, e o tipo de um campo é outro tipo objeto
ou um **escalar**, um valor único sem campos embaixo. O GraphQL tem cinco escalares embutidos: `Int`,
`Float`, `String`, `Boolean` e `ID`. `ID` é um identificador, e viaja sempre como texto, mesmo quando
os ids do banco são números; as respostas desta aula mostram `"id": "1"` onde o `rest.py` mostrava
`"id": 1`.

Um campo pode receber **argumentos**, como uma função: `book(id: ID!)` tem um, e
`books(authorId: ID)` tem um opcional que filtra a lista.

## O `!` e os colchetes

`!` quer dizer **nunca nulo**. É uma promessa do servidor, e o cliente pode escrever código que
confia nela. Colchetes indicam uma lista, e os dois se combinam, que é onde as pessoas se confundem:

| escrito | o campo pode ser nulo? | um item da lista pode ser nulo? |
|---|---|---|
| `Book` | sim | não é lista |
| `Book!` | não | não é lista |
| `[Book]` | sim | sim |
| `[Book!]` | sim | não |
| `[Book!]!` | não | não |

Então `books` sempre devolve uma lista, talvez vazia, e nunca uma lista com buracos, enquanto `book`
devolve `null` quando o id não bate com nada. Marque um campo como não nulo só quando ele realmente
não pode faltar. Transformar um campo anulável em não nulo é seguro para os clientes, mas o contrário
quebra todo cliente que confiou na promessa.

## As duas raízes

`Query` e `Mutation` são tipos objeto comuns com uma função especial: são onde a requisição começa.
Uma requisição que lê começa em `Query`, e uma que muda algo começa em `Mutation`. Uma terceira raiz,
`Subscription`, existe para eventos que o servidor empurra para o cliente; o `graph.py` não tem
nenhuma.

## O contrato, e como ele muda

O esquema é tudo o que um cliente pode pedir, então é o contrato que a aula 1 descreveu para o REST,
numa forma que um programa consegue ler. Ele muda sob a mesma regra: **acrescentar é seguro, e
remover ou mudar um tipo não é.** O costume do GraphQL não é pôr versões no endereço, e sim manter um
esquema só e deixá-lo crescer, marcando o que está de saída com a diretiva embutida
`@deprecated(reason: "…")`, que as ferramentas mostram a quem ainda pede aquele campo.
