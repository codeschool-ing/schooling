---
title: Um servidor em vinte linhas
version: 1
---

**O servidor do planner responde a duas requisições.** O `GET /plan` devolve o plano inteiro, e o `POST
/sessions/<id>/done` marca uma sessão como feita. Ele guarda o plano na memória, então esquece toda mudança
quando para, o que está exatamente certo para um servidor cujo trabalho é conversar numa aula. Salve-o no
projeto como `server.mjs`:

```javascript
// server.mjs: the planner's server: the plan, and one way to change it.
// It keeps the plan in memory, so it starts from src/courses.json every time it starts.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";

const plan = JSON.parse(readFileSync("src/courses.json", "utf8"));
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*", // the web build is served from another port
  "access-control-allow-methods": "GET, POST",
};

createServer((req, res) => {
  console.log(req.method, req.url);
  const done = req.url?.match(/^\/sessions\/([\w-]+)\/done$/);
  if (req.method === "OPTIONS") return res.writeHead(204, headers).end();
  if (req.method === "GET" && req.url === "/plan") return res.writeHead(200, headers).end(JSON.stringify(plan));
  if (req.method === "POST" && done) {
    const session = plan.sessions.find((s) => s.id === done[1]);
    if (!session) return res.writeHead(404, headers).end(JSON.stringify({ error: `no session ${done[1]}` }));
    session.done = true;
    return res.writeHead(200, headers).end(JSON.stringify(session));
  }
  res.writeHead(404, headers).end(JSON.stringify({ error: "not found" }));
}).listen(8008, () => console.log("listening on 8008"));
```

Os cabeçalhos `access-control-allow-*` deixam o build web, servido de outra porta, chamá-lo: um navegador
recusa uma resposta de outra origem a não ser que o servidor diga que ela pode ser lida. Um celular não aplica
essa regra, e os cabeçalhos não fazem mal ali. Suba-o num terceiro terminal e deixe-o rodando:

```sh
node server.mjs
```

Depois converse com ele pelo `curl`, antes que o app o faça:

```
ana@dev:~/planner$ curl -s localhost:8008/plan | head -c 150; echo
{"courses":[{"id":"spanish","name":"Spanish A2"},{"id":"statistics","name":"Statistics"},{"id":"guitar","name":"Guitar"}],"sessions":[{"id":"s1","cour
ana@dev:~/planner$ curl -s -i -X POST localhost:8008/sessions/s9/done | head -1
HTTP/1.1 404 Not Found
ana@dev:~/planner$ curl -s -i -X POST localhost:8008/sessions/s9/done | tail -1; echo
{"error":"no session s9"}
```

O plano volta como o JSON da aula 3. O `s9` não existe, e o servidor diz isso com um 404 e uma frase, que é do
que o app vai precisar quando pedir algo errado.

## O lado do app

As duas requisições, como funções, num arquivo que não sabe nada de telas. Salve-o como `src/api.ts`:

```typescript
// src/api.ts: the two requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) throw new Error(`${init?.method ?? "GET"} ${path} answered ${res.status}`);
  return (await res.json()) as T;
}

export const fetchPlan = () => json<Plan>("/plan");
export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
```

**O `fetch` resolve mesmo para um 404 ou um 500**; só uma falha de rede o rejeita. O `json` transforma toda
resposta que não é `ok` num erro com o método, o caminho e o status dentro, para que um servidor que recusa
pareça ao resto do app exatamente como um servidor que não pôde ser alcançado.

O `EXPO_PUBLIC_API_URL` é lido quando o Metro **empacota** o app: o Expo troca `process.env.EXPO_PUBLIC_…` pelo
valor que ele tinha naquele momento, então um build é feito para um servidor. Num celular, `localhost` é o
próprio celular; para alcançar o servidor no seu computador pelo Expo Go, o bundle precisa citar o endereço do
computador na Wi-Fi, como `EXPO_PUBLIC_API_URL=http://192.168.1.20:8008 npx expo start`. *Isso não foi rodado
para este curso*, que não tinha celular; o build web da última seção cita `localhost`, o que está certo para um
navegador no mesmo computador.
