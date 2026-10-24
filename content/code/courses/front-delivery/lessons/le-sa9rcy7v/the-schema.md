---
title: The schema
version: 1
---

**The schema is the contract between the server and every client: a typed list of what may be asked and
what may be changed.** It is written in GraphQL's own schema language, and this lesson's server reads it
from a file. The planner's whole API is this:

```
# api/schema.graphql
"A course the planner tracks."
type Course {
  id: ID!
  title: String!
  sessions: [Session!]!
  minutesPlanned: Int!
}

"One study session, planned or done."
type Session {
  id: Int!
  course: Course!
  date: String!
  minutes: Int!
  done: Boolean!
}

input NewSession {
  course: ID!
  date: String!
  minutes: Int!
}

type Query {
  courses: [Course!]!
  course(id: ID!): Course
}

type Mutation {
  markDone(id: Int!): Session
  addSession(input: NewSession!): Session!
}
```

Put it at `~/planner/api/schema.graphql`. The `api` folder is the server's, inside the planner's
repository for this course; in a real team it would be another team's repository, and the schema is the
one file both sides read.

## Reading it

- **`type`** declares an object with fields. Each field has a type, and a field can be another object:
  a `Session` has a `course`, and a `Course` has `sessions`, so a query can walk from one to the other.
- **Scalars** are the leaves: `ID`, `String`, `Int`, `Float` and `Boolean`. `ID` is a string that
  identifies something and is not meant to be read; the course ids, `git` and `javascript`, are `ID`s. The
  session ids are numbers in the planner already, so they stay `Int`.
- **`!`** means never null. A `title` of type `String!` is always there. `course(id: ID!): Course` has no `!` on
  its result, because asking for a course that does not exist answers `null`.
- **`[Session!]!`** is a list that is never null, of sessions that are never null: an empty course has
  `[]`, never `null`, and never a `null` inside the list.
- **`Query`** and **`Mutation`** are the two entry points. Every query starts at a field of `Query`, and
  every change at a field of `Mutation`.
- **`input`** declares a type that can only be passed in. `addSession` takes one, so a new session is one
  argument rather than three.
- **The strings in quotes** are descriptions. They are part of the schema, and tools show them beside
  the fields.

`minutesPlanned` is worth noticing: it is not stored anywhere. The server computes it when asked. A
schema describes what can be asked, not how the data is kept, which is what lets a server change its
database without any client noticing.

## Introspection

A GraphQL server can answer questions about its own schema, through fields such as `__schema` and
`__type`, and editors and clients use that to autocomplete queries. It is convenient in development and a
map of the whole API for anybody in production, so many public servers turn it off there; the schema file
in the repository is what the planner's tools read instead.
