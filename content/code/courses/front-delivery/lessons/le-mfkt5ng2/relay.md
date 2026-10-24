---
title: Relay
version: 1
---

**Relay is Meta's GraphQL client for React, and it is built on one rule: a component declares the
fields it reads, as a fragment, and receives only those.** Apollo lets you organise queries however you
like; Relay decides for you, and enforces the decision with a compiler. **Nothing in this section was run
for this course**: Relay needs React, and the planner has no framework. What follows is the shape Relay
21's documentation gave in October 2026.

## A component and its fragment

The session row, written for Relay, says what it needs beside the code that uses it:

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

The page's query spreads that fragment and nothing more about the row:

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

- **The compiler.** `relay-compiler` reads every `graphql` tag in the source, checks it against the
  schema, which is lesson 9's test done for every query by the build, and writes a file of TypeScript
  types for each, in `__generated__`. A field misspelt in a fragment is a build failure.
- **Data masking.** `CoursePage` cannot read `session.date`, even though the query fetched it. The page
  only sees the fields it asked for itself; the row's fields are visible to the row. So removing `date`
  from the row's fragment cannot silently break the page, and nobody can come to depend on a field
  another component happened to fetch.
- **Naming.** A fragment's name is the module's name, an underscore, and the prop it arrives in:
  `SessionRow_session`. The compiler refuses any other.

## What it asks of the schema

Relay works best against a server that follows two conventions of its own, and the planner's schema
follows neither:

- **Global object identification.** Every object that can be refetched implements a `Node` interface
  with an `id: ID!` unique across all types, and `Query` has `node(id: ID!): Node`. The planner's session
  6 and a future course with id 6 would collide; a Relay server would give them ids like `U2Vzc2lvbjo2`,
  which encode the type and the number together.
- **Connections.** A list that can be paged is a `Connection` with `edges`, each holding a `node`, and a
  `pageInfo` saying whether there is more. Relay's pagination hooks expect exactly that.

## And of the build

Three packages, `react-relay`, `relay-runtime` and `relay-compiler`, a `relay.config.json` naming the
source folder and the schema file, a step that runs the compiler before or alongside Vite, and a plugin
that replaces each `graphql` tag with an import of what the compiler generated. It is a heavier setup
than Apollo's, done once; teams that choose Relay do so for what the rule buys on a large codebase with
many people editing it.
