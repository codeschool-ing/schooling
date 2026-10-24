---
title: O planner pergunta ao servidor
version: 1
---

**O planner continua funcionando como site estático, e quando recebe o endereço de um servidor GraphQL
lê as sessões dali e grava o *Mark done* ali também.** As aulas 1 a 4 puseram o planner em quatro hosts
que servem arquivos e não rodam nada, e esse build não pode quebrar; então o endereço é uma variável de
build, definida em desenvolvimento e ausente no build estático.

## O endereço, como variável

A aula 2 disse onde uma variável nova entra primeiro. Acrescente-a aos tipos:

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

Depois dê a ela um valor só para desenvolvimento, num arquivo que vai para o commit, já que um endereço
neste computador não é segredo:

```
ana@dev:~/planner$ echo 'VITE_GRAPHQL_URL=/graphql' > .env.development
```

O valor é um caminho, e não `http://127.0.0.1:4000/graphql`. A página é servida pelo Vite na porta 5173 e
o servidor escuta na 4000, e um navegador trata duas portas como duas origens: o servidor teria de mandar
cabeçalhos CORS para poder ser chamado da página. Em vez disso, o servidor de desenvolvimento do Vite
repassa `/graphql` para a API, e a página só conversa com a própria origem. O planner não tinha
`vite.config.ts` até agora; este é ele inteiro:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    proxy: { "/graphql": "http://127.0.0.1:4000" },
  },
});
```

Um host que serve o planner ao lado de uma API de verdade faz o mesmo com uma regra de rewrite, do tipo que
a aula 4 escreveu, ou a API responde no mesmo domínio.

## O cliente, em três arquivos

**`graphql.ts` manda um pedido e recusa uma resposta com erros**, como a seção sobre erros decidiu:

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

Ele confere o status também, porque um proxy sem servidor atrás responde com um status de erro e nenhum
GraphQL.

**`queries.ts` guarda as operações**, escritas uma vez, com o fragment que as duas espalham:

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

**`api.ts` é o que o resto do planner chama.** Ele transforma a resposta nos tipos `Course` e `Session` do
próprio planner, cujo `course` é um id e não um objeto, e volta ao `courses.json` quando não há servidor:

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

## `main.ts`, usando-os

Dois lugares mudam: `start` carrega pelo `api.ts`, e `done` grava depois de desenhar. Este é o arquivo
inteiro de novo:

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

**A tela muda primeiro e o servidor depois.** Apertar o botão desenha a sessão como feita na hora, e então
avisa o servidor; se o servidor recusar, o erro vai para o console e a tela fica errada até o próximo
carregamento. Essa troca, chamada atualização otimista, é a que a maioria dos apps faz para uma mudança
deste tamanho. O cliente da aula 10 consegue desfazer a tela quando o servidor diz não, e a aula 11 manda
esse erro do console para um lugar onde uma pessoa vai vê-lo. `add` ainda só muda a tela: ligá-lo ao
`addSession` são os mesmos três passos, e o exercício final pede por eles.

## Experimentando

Pare o servidor GraphQL com Ctrl-C e inicie-o de novo, para que comece das seis sessões depois das
mudanças das seções anteriores. Inicie o servidor de desenvolvimento do planner num terceiro terminal com
`npm run dev`. No navegador, abra o curso de JavaScript e aperte **Mark done** na sessão de 15 de outubro.
O terminal do servidor GraphQL agora guarda tudo o que esta aula perguntou a ele, depois o reinício,
depois o que o planner mandou:

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

`Planner` quando a página carregou, e `MarkDone` quando o botão foi apertado. Recarregue a página e a
sessão continua feita, porque desta vez foi lida de volta do servidor.

O build estático não tem `VITE_GRAPHQL_URL`, porque o `.env.development` só é lido em desenvolvimento,
então continua lendo o `courses.json`:

```
ana@dev:~/planner$ npm run build > /dev/null && grep -c 'courses.json' dist/assets/*.js
1
ana@dev:~/planner$ grep -c 'MarkDone' dist/assets/*.js
0
```

A segunda contagem é a interessante. A metade GraphQL do `api.ts` nem está no build: o Vite trocou
`import.meta.env.VITE_GRAPHQL_URL` por `undefined` durante o build, então o ramo que pergunta ao servidor
nunca poderia rodar, e o bundler deixou de fora esse ramo e tudo o que só ele usava.
