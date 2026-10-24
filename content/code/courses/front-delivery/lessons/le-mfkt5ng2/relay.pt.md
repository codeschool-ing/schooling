---
title: Relay
version: 1
---

**O Relay é o cliente GraphQL da Meta para React, e é construído sobre uma regra: um componente declara
os campos que lê, como um fragment, e recebe só esses.** O Apollo deixa você organizar as consultas como
quiser; o Relay decide por você, e faz valer a decisão com um compilador. **Nada nesta seção foi executado
para este curso**: o Relay precisa de React, e o planner não tem framework. O que segue é a forma que a
documentação do Relay 21 dava em outubro de 2026.

## Um componente e o seu fragment

A linha de sessão, escrita para o Relay, diz do que precisa ao lado do código que usa:

```tsx
// SessionRow.tsx
import { graphql, useFragment } from "react-relay";
import type { SessionRow_session$key } from "./__generated__/SessionRow_session.graphql";

export function SessionRow(props: { session: SessionRow_session$key }) {
  const session = useFragment(
    graphql`
      fragment SessionRow_session on Session {
        date
        minutes
        done
      }
    `,
    props.session,
  );
  return <li>{session.date} · {session.minutes} min{session.done ? " · done" : ""}</li>;
}
```

A consulta da página espalha esse fragment, e nada mais sobre a linha:

```tsx
// CoursePage.tsx
const data = useLazyLoadQuery<CoursePageQuery>(
  graphql`
    query CoursePageQuery($id: ID!) {
      course(id: $id) {
        title
        sessions {
          id
          ...SessionRow_session
        }
      }
    }
  `,
  { id },
);
```

- **O compilador.** O `relay-compiler` lê cada tag `graphql` do código, confere contra o schema, que é o
  teste da aula 9 feito pelo build para toda consulta, e escreve um arquivo de tipos TypeScript para cada
  uma, em `__generated__`. Um campo escrito errado num fragment é uma falha de build.
- **Data masking.** O `CoursePage` não consegue ler `session.date`, mesmo a consulta tendo buscado esse
  campo. A página só enxerga os campos que ela mesma pediu; os campos da linha são visíveis para a linha.
  Então tirar `date` do fragment da linha não pode quebrar a página em silêncio, e ninguém passa a
  depender de um campo que outro componente por acaso buscou.
- **Nomes.** O nome de um fragment é o nome do módulo, um sublinhado, e a prop em que ele chega:
  `SessionRow_session`. O compilador recusa qualquer outro.

## O que ele pede do schema

O Relay funciona melhor contra um servidor que segue duas convenções dele, e o schema do planner não segue
nenhuma:

- **Identificação global de objetos.** Todo objeto que pode ser buscado de novo implementa uma interface
  `Node` com um `id: ID!` único entre todos os tipos, e `Query` tem `node(id: ID!): Node`. A sessão 6 do
  planner e um futuro curso com id 6 colidiriam; um servidor Relay lhes daria ids como `U2Vzc2lvbjo2`,
  que codificam o tipo e o número juntos.
- **Connections.** Uma lista que pode ser paginada é uma `Connection` com `edges`, cada um contendo um
  `node`, e um `pageInfo` dizendo se há mais. Os hooks de paginação do Relay esperam exatamente isso.

## E do build

Três pacotes, `react-relay`, `relay-runtime` e `relay-compiler`, um `relay.config.json` dizendo a pasta do
código e o arquivo do schema, um passo que roda o compilador antes do Vite ou junto com ele, e um plugin
que troca cada tag `graphql` por um import do que o compilador gerou. É uma configuração mais pesada que a
do Apollo, feita uma vez; equipes que escolhem o Relay o fazem pelo que a regra compra numa base de código
grande, com muita gente editando.
