---
title: The planner on Apollo
version: 1
---

**The planner keeps its two functions, one to load and one to save, and Apollo goes behind them.** What
changes is how the screen hears about data: instead of loading once, it **watches** a query, and draws
again every time the cache changes what that query would answer.

## The operations, parsed

`queries.ts` keeps the same three documents, now written with `gql`, so each is parsed once into the
tree Apollo and `graphql` both work with. The fragment is exported too, because the code that saves a
session reads it from the cache:

```typescript
// src/queries.ts
import { gql } from "@apollo/client";

export const SESSION_FIELDS = gql`
  fragment SessionFields on Session {
    id
    date
    minutes
    done
    course {
      id
    }
  }
`;

export const PLANNER = gql`
  query Planner {
    courses {
      id
      title
      sessions {
        ...SessionFields
      }
    }
  }
  ${SESSION_FIELDS}
`;

export const MARK_DONE = gql`
  mutation MarkDone($id: Int!) {
    markDone(id: $id) {
      ...SessionFields
    }
  }
  ${SESSION_FIELDS}
`;
```

## Apollo, in a file of its own

Everything that touches Apollo goes in `apollo.ts`: the client, the conversion from the server's shape
to the planner's, and the two operations.

```typescript
// src/apollo.ts
import { ApolloClient, HttpLink, InMemoryCache } from "@apollo/client";
import type { Planner } from "./api";
import type { Course, Session } from "./planner";
import { MARK_DONE, PLANNER, SESSION_FIELDS } from "./queries";

interface RemoteSession extends Omit<Session, "course"> {
  course: { id: string };
}

const client = new ApolloClient({
  link: new HttpLink({ uri: import.meta.env.VITE_GRAPHQL_URL }),
  cache: new InMemoryCache(),
});

const toSession = ({ id, date, minutes, done, course }: RemoteSession): Session => ({
  id,
  date,
  minutes,
  done,
  course: course.id,
});

export function watchPlanner(show: (planner: Planner) => void): void {
  const query = client.watchQuery<{ courses: (Course & { sessions: RemoteSession[] })[] }>({ query: PLANNER });
  query.subscribe((result) => {
    if (result.error) console.error("Could not load", result.error);
    if (result.dataState !== "complete") return;
    show({
      courses: result.data.courses.map(({ id, title }) => ({ id, title })),
      sessions: result.data.courses.flatMap((c) => c.sessions.map(toSession)),
    });
  });
}

export async function markDoneRemote(id: number): Promise<void> {
  const session = client.cache.readFragment<RemoteSession>({
    id: client.cache.identify({ __typename: "Session", id }),
    fragment: SESSION_FIELDS,
  });
  await client.mutate({
    mutation: MARK_DONE,
    variables: { id },
    optimisticResponse: session ? { markDone: { ...session, done: true } } : undefined,
  });
}
```

- **`watchPlanner`** subscribes to the query. The callback runs when the first answer arrives and again
  each time the cache changes anything the query reads. Apollo also calls it while the result is still
  loading, or when it is partial, so it draws only when `dataState` is `"complete"`.
- **`markDoneRemote`** reads session 6, or whichever, out of the cache with the fragment, and sends the
  mutation with an **optimistic response**: the answer it expects the server to give. The next section is
  about what that does.
- **`toSession`** picks the planner's fields by name. Apollo adds `__typename` to every object, and
  spreading the answer would carry it into the planner's own sessions.

## The switch

`api.ts` is what `main.ts` imports, and it decides between the static file and Apollo:

```typescript
// src/api.ts
import type { Course, Session } from "./planner";

export interface Planner {
  courses: Course[];
  sessions: Session[];
}

export async function watch(base: string, show: (planner: Planner) => void): Promise<void> {
  if (!import.meta.env.VITE_GRAPHQL_URL) {
    show(await (await fetch(`${base}courses.json`)).json());
    return;
  }
  const { watchPlanner } = await import("./apollo");
  watchPlanner(show);
}

export async function saveDone(id: number): Promise<void> {
  if (!import.meta.env.VITE_GRAPHQL_URL) return;
  const { markDoneRemote } = await import("./apollo");
  await markDoneRemote(id);
}
```

**`apollo.ts` is imported with `await import()`, inside the branch**, and never at the top of the file.
The section on cost measures why. In `main.ts` the import line changes, and `start` becomes a call to
`watch` whose callback draws; this is the whole file:

```typescript
// src/main.ts
import "./style.css";
import { saveDone, watch } from "./api";
import { addSession, markDone, mondayOf, weekTotal, type Course, type Session } from "./planner";
import { courseList, coursePage, notFound } from "./view";

const base = import.meta.env.BASE_URL;
const app = document.querySelector<HTMLDivElement>("#app")!;
let courses: Course[] = [];
let sessions: Session[] = [];

function render(): void {
  const path = location.pathname.slice(base.length);
  if (path === "") {
    const latest = sessions.map((s) => s.date).sort().at(-1) ?? "2026-10-01";
    app.replaceChildren(courseList(courses, weekTotal(sessions, mondayOf(latest))));
    return;
  }
  const course = courses.find((c) => path === `course/${c.id}`);
  if (!course) {
    app.replaceChildren(notFound());
    return;
  }
  const own = sessions.filter((s) => s.course === course.id);
  app.replaceChildren(
    coursePage(course, own, {
      add(date, minutes) {
        sessions = addSession(sessions, course.id, date, minutes);
        render();
      },
      done(id) {
        sessions = markDone(sessions, id);
        render();
        saveDone(id).catch((error) => console.error("Could not save", error));
      },
    }),
  );
}

document.addEventListener("click", (event) => {
  const link = (event.target as Element).closest("a");
  if (link && link.origin === location.origin && link.pathname.startsWith(base)) {
    event.preventDefault();
    history.pushState(null, "", link.pathname);
    render();
  }
});
window.addEventListener("popstate", render);

watch(base, (planner) => {
  ({ courses, sessions } = planner);
  render();
}).catch((error) => console.error("Could not load", error));
```

`done` still changes the planner's own list and draws before it saves, so the static build behaves as it
did. With Apollo, the cache then answers too, and the screen is drawn again from it.

## The test, and the old client

The test from lesson 9 checked query strings, which it parsed first. The documents are parsed already, so
`validate` takes them directly:

```typescript
// src/queries.test.ts
import { buildSchema, validate } from "graphql";
import { expect, test } from "vitest";
import schemaSource from "../api/schema.graphql?raw";
import { MARK_DONE, PLANNER } from "./queries";

const schema = buildSchema(schemaSource);

test.each([
  ["Planner", PLANNER],
  ["MarkDone", MARK_DONE],
])("%s is valid against the schema", (_name, query) => {
  expect(validate(schema, query).map((error) => error.message)).toEqual([]);
});
```

Lesson 9's `graphql.ts` has nothing left to do. Remove it, and check everything:

```
ana@dev:~/planner$ git rm -q src/graphql.ts
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'
 Test Files  2 passed (2)
      Tests  7 passed (7)
ana@dev:~/planner$ git add -A && git commit -qm "Move the planner's GraphQL to Apollo Client"
```
