---
title: The schema is the contract
version: 1
---

**A GraphQL API is described by its schema, and nothing reaches a resolver without being checked
against it first.** The schema lists every type the API has, every field of each type and the
type of each field. A query that asks for something the schema does not declare is refused before
any code runs.

The name misleads people in one particular way. **GraphQL is not a query language for your
database**, the way SQL is. It queries the API's types, and the schema says nothing about where
their values come from. In `graph.py` a book has a `priceCents` where the table has
`price_cents`, and no `author_id` at all: the schema is what a client sees, and the server decides
how to produce it.

This is the schema of `graph.py`, written in the **schema definition language**, SDL:

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

## Types, scalars and fields

`Book` and `Author` are **object types**: each has fields, and a field's type is either another
object type or a **scalar**, a single value with no fields under it. GraphQL has five scalars
built in: `Int`, `Float`, `String`, `Boolean` and `ID`. `ID` is an identifier, and it always
travels as a string, even when the database's ids are numbers; the answers in this lesson show
`"id": "1"` where `rest.py` showed `"id": 1`.

A field can take **arguments**, like a function: `book(id: ID!)` has one, and `books(authorId: ID)`
has an optional one that filters the list.

## The `!` and the brackets

`!` means **never null**. It is a promise from the server, and a client may write code that relies
on it. Brackets mean a list, and the two combine, which is where people misread them:

| written | may the field be null? | may an item of the list be null? |
|---|---|---|
| `Book` | yes | not a list |
| `Book!` | no | not a list |
| `[Book]` | yes | yes |
| `[Book!]` | yes | no |
| `[Book!]!` | no | no |

So `books` always returns a list, possibly empty, and never a list with holes in it, while `book`
returns `null` when the id matches nothing. Mark a field non-null only when it truly cannot be
missing. Turning a nullable field into a non-null one is safe for clients, but the opposite breaks
every client that trusted the promise.

## The two roots

`Query` and `Mutation` are ordinary object types with one special job: they are where a request
starts. A request that reads begins at `Query`, and one that changes something begins at
`Mutation`. A third root, `Subscription`, exists for events a server pushes to a client; `graph.py`
has none.

## The contract, and how it changes

The schema is the whole of what a client may ask, so it is the contract lesson 1 described for
REST, in a form a program can read. It changes under the same rule: **adding is safe, and removing
or changing a type is not.** GraphQL's habit is not to put versions in the address but to keep one
schema and let it grow, marking what is on its way out with the built-in `@deprecated(reason: "…")`
directive, which tools show to anybody still asking for that field.
