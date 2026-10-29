---
title: O schema
version: 1
---

**O schema é o contrato entre o servidor e todo cliente: uma lista tipada do que pode ser perguntado e do
que pode ser mudado.** Ele é escrito na linguagem de schema do próprio GraphQL, e o servidor desta aula o
lê de um arquivo. A API inteira do planner é esta:

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

Ponha-o em `~/planner/api/schema.graphql`. A pasta `api` é do servidor, dentro do repositório do planner
neste curso; numa equipe de verdade seria o repositório de outra equipe, e o schema é o único arquivo que
os dois lados leem.

## Lendo o schema

- **`type`** declara um objeto com campos. Cada campo tem um tipo, e um campo pode ser outro objeto: uma
  `Session` tem um `course`, e um `Course` tem `sessions`, então uma consulta pode ir de um ao outro.
- **Escalares** são as folhas: `ID`, `String`, `Int`, `Float` e `Boolean`. `ID` é uma string que
  identifica algo e não é feita para ser lida; os ids dos cursos, `git` e `javascript`, são `ID`s. Os ids
  das sessões já são números no planner, então continuam `Int`.
- **`!`** quer dizer nunca nulo. Um `title` do tipo `String!` está sempre lá. `course(id: ID!): Course` não tem
  `!` no resultado, porque pedir um curso que não existe responde `null`.
- **`[Session!]!`** é uma lista que nunca é nula, de sessões que nunca são nulas: um curso vazio tem `[]`,
  nunca `null`, e nunca um `null` dentro da lista.
- **`Query`** e **`Mutation`** são as duas portas de entrada. Toda consulta começa num campo de `Query`, e
  toda mudança num campo de `Mutation`.
- **`input`** declara um tipo que só pode ser passado para dentro. `addSession` recebe um, então uma
  sessão nova é um argumento em vez de três.
- **As strings entre aspas** são descrições. Elas fazem parte do schema, e as ferramentas as mostram ao
  lado dos campos.

Vale reparar no `minutesPlanned`: ele não está guardado em lugar nenhum. O servidor o calcula quando é
pedido. Um schema descreve o que pode ser perguntado, não como os dados são guardados, e é isso que deixa
um servidor trocar de banco de dados sem nenhum cliente perceber.

## Introspecção

Um servidor GraphQL sabe responder perguntas sobre o próprio schema, por campos como `__schema` e
`__type`, e editores e clientes usam isso para completar consultas. É conveniente em desenvolvimento e,
em produção, um mapa da API inteira para qualquer pessoa, então muitos servidores públicos a desligam
ali; o arquivo do schema no repositório é o que as ferramentas do planner leem no lugar dela.
