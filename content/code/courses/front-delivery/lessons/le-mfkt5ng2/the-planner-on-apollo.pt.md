---
title: O planner no Apollo
version: 1
---

**O planner mantém as suas duas funções, uma para carregar e uma para gravar, e o Apollo fica atrás
delas.** O que muda é como a tela fica sabendo dos dados: em vez de carregar uma vez, ela **observa** uma
consulta, e desenha de novo sempre que o cache muda o que essa consulta responderia.

## As operações, já interpretadas

O `queries.ts` mantém os mesmos três documentos, agora escritos com `gql`, para que cada um seja
interpretado uma vez na árvore com que o Apollo e o `graphql` trabalham. O fragment também é exportado,
porque o código que grava uma sessão o lê do cache:

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

## O Apollo, num arquivo só dele

Tudo o que toca o Apollo vai no `apollo.ts`: o cliente, a conversão do formato do servidor para o do
planner e as duas operações.

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

- **`watchPlanner`** se inscreve na consulta. O callback roda quando chega a primeira resposta e de novo
  cada vez que o cache muda algo que a consulta lê. O Apollo também o chama enquanto o resultado ainda está
  carregando, ou quando está parcial, então ele só desenha quando `dataState` é `"complete"`.
- **`markDoneRemote`** lê a sessão 6, ou qualquer outra, do cache com o fragment, e manda a mutation com
  uma **resposta otimista**: a resposta que ele espera que o servidor dê. A próxima seção é sobre o que
  isso faz.
- **`toSession`** escolhe os campos do planner pelo nome. O Apollo acrescenta `__typename` a todo objeto,
  e espalhar a resposta levaria esse campo para as sessões do próprio planner.

## A chave

O `api.ts` é o que o `main.ts` importa, e ele decide entre o arquivo estático e o Apollo:

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

**O `apollo.ts` é importado com `await import()`, dentro do ramo**, e nunca no topo do arquivo. A seção
sobre custo mede por quê. No `main.ts`, a linha do import muda, e o `start` vira uma chamada a `watch`
cujo callback desenha; este é o arquivo inteiro:

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

O `done` continua mudando a lista do próprio planner e desenhando antes de gravar, então o build estático
se comporta como antes. Com o Apollo, o cache responde em seguida também, e a tela é desenhada de novo a
partir dele.

## O teste, e o cliente antigo

O teste da aula 9 conferia strings de consulta, que ele interpretava primeiro. Os documentos já vêm
interpretados, então o `validate` os recebe diretamente:

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

O `graphql.ts` da aula 9 não tem mais o que fazer. Remova-o e confira tudo:

```
ana@dev:~/planner$ git rm -q src/graphql.ts
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'
 Test Files  2 passed (2)
      Tests  7 passed (7)
ana@dev:~/planner$ git add -A && git commit -qm "Move the planner's GraphQL to Apollo Client"
```
