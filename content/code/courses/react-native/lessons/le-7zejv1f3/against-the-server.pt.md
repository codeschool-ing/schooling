---
title: O servidor confere tudo de novo
version: 1
---

**A validação do app é para a pessoa; a do servidor é para os dados.** Uma requisição a `POST /sessions` pode vir
do planner, de uma versão antiga do planner, do `curl` ou de qualquer coisa, e o servidor não tem como saber de
qual. Então ele confere cada campo sozinho, e recusa com uma frase. Troque o `server.mjs`:

```javascript
// server.mjs: the planner's server: the plan, a session marked done, and a session added.
// It keeps the plan in memory, so it starts from src/courses.json every time it starts.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";

const plan = JSON.parse(readFileSync("src/courses.json", "utf8"));
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*", // the web build is served from another port
  "access-control-allow-methods": "GET, POST",
  "access-control-allow-headers": "content-type",
};
const send = (res, status, body) => res.writeHead(status, headers).end(JSON.stringify(body));

// The server checks everything itself: a request may come from anything, not only from the app.
function invalid(s) {
  if (!plan.courses.some((c) => c.id === s.course)) return `no course ${s.course}`;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s.date ?? "")) return "date must be YYYY-MM-DD";
  if (!Number.isInteger(s.minutes) || s.minutes < 5 || s.minutes > 240) return "minutes must be 5 to 240";
  return null;
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  console.log(req.method, req.url, text);
  const done = req.url?.match(/^\/sessions\/([\w-]+)\/done$/);
  if (req.method === "OPTIONS") return res.writeHead(204, headers).end();
  if (req.method === "GET" && req.url === "/plan") return send(res, 200, plan);
  if (req.method === "POST" && done) {
    const session = plan.sessions.find((s) => s.id === done[1]);
    if (!session) return send(res, 404, { error: `no session ${done[1]}` });
    session.done = true;
    return send(res, 200, session);
  }
  if (req.method === "POST" && req.url === "/sessions") {
    const body = JSON.parse(text || "{}");
    const problem = invalid(body);
    if (problem) return send(res, 422, { error: problem });
    const session = { id: `s${plan.sessions.length + 1}`, course: body.course, date: body.date, minutes: body.minutes, done: false };
    plan.sessions.push(session);
    return send(res, 201, session);
  }
  send(res, 404, { error: "not found" });
}).listen(8008, () => console.log("listening on 8008"));
```

O `content-type` entra nos cabeçalhos permitidos, porque o app agora envia JSON: um navegador pergunta antes de
enviar um `POST` de outra origem com corpo JSON, e o servidor precisa dizer que sim. A regra do servidor e a do
app concordam, de 5 a 240 minutos; se algum dia discordarem, vale a do servidor, e o formulário mostra a frase
dele.

As requisições do app ganham uma, e uma requisição que falhou agora traz a frase do próprio servidor quando ele
mandou uma. Troque o `src/api.ts`:

```typescript
// src/api.ts: the requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => null); // a refusal may explain itself
    throw new Error(body?.error ?? `${init?.method ?? "GET"} ${path} answered ${res.status}`);
  }
  return (await res.json()) as T;
}

export type NewSession = { course: string; date: string; minutes: number };

export const fetchPlan = () => json<Plan>("/plan");
export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
export const createSession = (s: NewSession) =>
  json<Session>("/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(s) });
```

E o `src/planState.tsx` ganha o `useAddSession`. Acrescentar não é otimista: o servidor dá à sessão nova o id
dela, então a tela espera a resposta e depois busca o plano de novo. Troque-o:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import NetInfo from "@react-native-community/netinfo";
import { createSession, fetchPlan, sendDone, type NewSession } from "./api";
import { addSession, markDone, type Plan } from "./planner";

export type Action =
  | { type: "done"; id: string }
  | { type: "add"; course: string; date: string; minutes: number };

export function planReducer(plan: Plan, action: Action): Plan {
  switch (action.type) {
    case "done":
      return markDone(plan, action.id);
    case "add":
      return addSession(plan, action.course, action.date, action.minutes);
  }
}

// TanStack Query pauses requests while offline; on a phone, NetInfo is what knows.
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));

export function usePlanQuery() {
  return useQuery({ queryKey: ["plan"], queryFn: fetchPlan, staleTime: 30_000 });
}

function useMarkDone() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: sendDone,
    onMutate: async (id: string) => {
      await client.cancelQueries({ queryKey: ["plan"] });
      const before = client.getQueryData<Plan>(["plan"]);
      client.setQueryData<Plan>(["plan"], (p) => p && planReducer(p, { type: "done", id }));
      return { before };
    },
    onError: (_error, _id, context) => client.setQueryData(["plan"], context?.before),
    onSettled: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// Adding waits for the server, which gives the session its id; then the plan is fetched again.
export function useAddSession() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (s: NewSession) => createSession(s),
    onSuccess: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// The screens' view of all this is the same as in lesson 9.
export function usePlan() {
  const { data } = usePlanQuery();
  const markDone = useMarkDone();
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  const dispatch = (action: Action) => {
    if (action.type === "done") markDone.mutate(action.id);
  };
  return { plan: data, dispatch, error: markDone.error };
}
```

## Perguntado diretamente

Suba o servidor e peça a ele uma sessão de 999 minutos, que o formulário nunca enviaria:

```
ana@dev:~/planner$ curl -s -X POST localhost:8008/sessions -H 'content-type: application/json' -d '{"course":"guitar","date":"2026-10-23","minutes":999}'; echo
{"error":"minutes must be 5 to 240"}
```

## Pelo navegador

Exporte o build web com o endereço do servidor e abra o curso de violão. O primeiro comando digita uma data do
jeito errado; o segundo a digita corretamente:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/guitar' --click 'Add a session' --fill Date=23/10/2026 --fill Minutes=25 --click 'Save session'
- link "Guitar, back":
  - /url: /course/guitar
- heading "New session" [level=1]
- text: Date
- textbox "Date":
  - /placeholder: 2026-10-23
  - text: 23/10/2026
- alert: Write the date as YYYY-MM-DD, for example 2026-10-23.
- text: Minutes
- textbox "Minutes":
  - /placeholder: "30"
  - text: "25"
- button "Save session"
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/guitar' --click 'Add a session' --fill Date=2026-10-23 --fill Minutes=25 --click 'Save session' --wait 500
- heading "Guitar" [level=1]
- button "Add a session"
- heading "2026-10-21" [level=2]
- text: 20 min
- button "Mark 20 min on 2026-10-21 done": Mark done
- heading "2026-10-23" [level=2]
- text: 25 min
- button "Mark 25 min on 2026-10-23 done": Mark done
- heading "2026-10-28" [level=2]
- text: 20 min
- button "Mark 20 min on 2026-10-28 done": Mark done
```

**O primeiro salvamento nunca chegou ao servidor**: o formulário o recusou e anunciou por quê, como um `alert`.
O segundo foi enviado, o formulário fechou, e a lista do curso agora tem uma sessão no dia 23. O terminal do
servidor mostra as requisições que chegaram, inclusive a do `curl`, recusada, com o corpo:

```
listening on 8008
GET / 
POST /sessions {"course":"guitar","date":"2026-10-23","minutes":999}
GET /plan 
GET /plan 
OPTIONS /sessions 
POST /sessions {"course":"guitar","date":"2026-10-23","minutes":25}
GET /plan 
```

Leia em ordem: o `GET /` é a máquina de gravação conferindo que o servidor tinha subido; depois o `POST` recusado
do `curl`, com o corpo; depois um `GET /plan` para cada visita do navegador. O salvamento da segunda visita mandou
antes o `OPTIONS /sessions`, o navegador perguntando se um `POST` de outra origem com corpo JSON é permitido, de
que o `POST` sem corpo da aula 10 nunca precisou; depois o próprio `POST`, com os minutos como número; depois um
`GET /plan`, a nova busca que pôs a sessão nova na tela do curso.
