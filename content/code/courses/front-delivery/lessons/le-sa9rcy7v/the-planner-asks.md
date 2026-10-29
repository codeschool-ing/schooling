---
title: The planner asks the server
version: 1
---

**The planner keeps working as a static site, and when it is given the address of a GraphQL server it
reads its sessions from there and saves *Mark done* there too.** Lessons 1 to 4 put the planner on four
hosts that serve files and run nothing, and that build must not break; so the address is a build
variable, set in development, and absent in the static build.

## The address, as a variable

Lesson 2 said where a new variable goes first. Add it to the types:

```typescript
// src/vite-env.d.ts
interface ViteTypeOptions {
  strictImportMetaEnv: unknown;
}

interface ImportMetaEnv {
  readonly VITE_TITLE?: string;
  readonly VITE_GRAPHQL_URL?: string;
}
```

Then give it a value for development only, in a file that is committed, since an address on this
computer is no secret:

```
ana@dev:~/planner$ echo 'VITE_GRAPHQL_URL=/graphql' > .env.development
```

The value is a path, not `http://127.0.0.1:4000/graphql`. The page is served by Vite from port 5173 and
the server listens on 4000, and a browser treats two ports as two origins: the server would have to
send CORS headers to be asked from the page at all. Instead Vite's dev server passes `/graphql` on to the
API, so the page only ever talks to its own origin. The planner had no `vite.config.ts` until now; this
is all of it:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    proxy: { "/graphql": "http://127.0.0.1:4000" },
  },
});
```

A host that serves the planner next to a real API does the same with a rewrite rule, the kind lesson 4
wrote, or the API answers on the same domain.

## The client, in three files

**`graphql.ts` sends one request and refuses an answer with errors**, as the section on errors decided:

```typescript
// src/graphql.ts
export async function request<T>(operationName: string, query: string, variables = {}): Promise<T> {
  const response = await fetch(import.meta.env.VITE_GRAPHQL_URL!, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ operationName, query, variables }),
  });
  if (!response.ok) throw new Error(`${operationName}: HTTP ${response.status}`);
  const { data, errors } = (await response.json()) as { data: T; errors?: { message: string }[] };
  if (errors) throw new Error(`${operationName}: ${errors.map((e) => e.message).join("; ")}`);
  return data;
}
```

It checks the status as well, because a proxy with no server behind it answers with an error status and
no GraphQL at all.

**`queries.ts` holds the operations**, written once, with the fragment both of them spread:

```typescript
// src/queries.ts
const SESSION_FIELDS = `
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

export const PLANNER = `
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

export const MARK_DONE = `
  mutation MarkDone($id: Int!) {
    markDone(id: $id) {
      ...SessionFields
    }
  }
  ${SESSION_FIELDS}
`;
```

**`api.ts` is what the rest of the planner calls.** It turns the answer into the planner's own `Course`
and `Session` types, whose `course` is an id rather than an object, and it falls back to `courses.json`
when there is no server:

```typescript
// src/api.ts
import { request } from "./graphql";
import type { Course, Session } from "./planner";
import { MARK_DONE, PLANNER } from "./queries";

interface RemoteSession extends Omit<Session, "course"> {
  course: { id: string };
}

const toSession = (s: RemoteSession): Session => ({ ...s, course: s.course.id });

export async function load(base: string): Promise<{ courses: Course[]; sessions: Session[] }> {
  if (!import.meta.env.VITE_GRAPHQL_URL) return (await fetch(`${base}courses.json`)).json();
  const data = await request<{ courses: (Course & { sessions: RemoteSession[] })[] }>("Planner", PLANNER);
  return {
    courses: data.courses.map(({ id, title }) => ({ id, title })),
    sessions: data.courses.flatMap((c) => c.sessions.map(toSession)),
  };
}

export async function saveDone(id: number): Promise<void> {
  if (import.meta.env.VITE_GRAPHQL_URL) await request("MarkDone", MARK_DONE, { id });
}
```

## `main.ts`, using them

Two places change: `start` loads through `api.ts`, and `done` saves after it draws. This is the whole
file again:

```typescript
// src/main.ts
import "./style.css";
import { load, saveDone } from "./api";
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

async function start(): Promise<void> {
  ({ courses, sessions } = await load(base));
  render();
}

start();
```

**The screen changes first and the server second.** Pressing the button draws the session as done at
once, then tells the server; if the server refuses, the error goes to the console and the screen is
wrong until the next load. That trade, called an optimistic update, is what most apps make for a change
this small. Lesson 10's client can undo the screen when the server says no, and lesson 11 sends that
console error somewhere a person will see it. `add` still only changes the screen: wiring it to
`addSession` is the same three steps, and the drill asks for them.

## Trying it

Stop the GraphQL server with Ctrl-C and start it again, so it begins from the six sessions after the
earlier sections' changes. Start the planner's dev server in a third terminal with `npm run dev`. In the
browser, open the JavaScript course and press **Mark done** on the session of 15 October. The GraphQL
server's terminal now holds everything this lesson asked it, then the restart, then what the planner
sent:

```
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
(anonymous)
(anonymous)
(anonymous)
(anonymous)
(anonymous)
(anonymous)
(anonymous) with errors
(anonymous) with errors
(anonymous) with errors
(anonymous)
(anonymous)
(anonymous)
(anonymous)
(anonymous)
^C
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
Planner
MarkDone
```

`Planner` when the page loaded, and `MarkDone` when the button was pressed. Reload the page and the
session is still done, because it was read back from the server this time.

The static build has no `VITE_GRAPHQL_URL`, because `.env.development` is read only in development, so it
still reads `courses.json`:

```
ana@dev:~/planner$ npm run build > /dev/null && grep -c 'courses.json' dist/assets/*.js
1
ana@dev:~/planner$ grep -c 'MarkDone' dist/assets/*.js
0
```

The second count is the interesting one. The GraphQL half of `api.ts` is not in the build at all: Vite
replaced `import.meta.env.VITE_GRAPHQL_URL` with `undefined` while building, so the branch that asks the
server could never run, and the bundler left it and everything only it used out of the file.
