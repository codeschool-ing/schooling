---
title: O que vale tentar de novo, e o que é uma resposta
version: 1
---

**Vale tentar de novo uma requisição que falhou quando a falha não diz nada sobre a requisição em
si: a rede a perdeu, o servidor estava ocupado, ou a resposta nunca veio.** Quando o servidor leu a
requisição e disse não, a falha é uma resposta, e mandar os mesmos bytes de novo recebe o mesmo não.
A aula 8 traçou essa linha entre um erro de rede e um 4xx; esta aula decide quanto esperar antes de
cada nova tentativa, e quantas tentativas fazer.

| o que voltou | tentar de novo? | por quê |
|---|---|---|
| nenhuma resposta: a conexão falhou, ou o tempo limite acabou | sim | nada chegou ao cliente; se algo chegou ao servidor é o problema da última seção |
| 500, 502, 503, 504 | sim | o servidor, ou algo na frente dele, está com problema, e pode não estar daqui a pouco |
| 429 Too Many Requests | sim, e mais devagar | o servidor está pedindo ao cliente que recue, e muitas vezes diz por quanto tempo |
| 408 Request Timeout | sim | o servidor desistiu de esperar a requisição |
| 400, 401, 403, 404, 409, 422 | não | o servidor a leu; a mesma requisição recebe a mesma resposta |

O 401 é a exceção que vale citar: um token de acesso vencido se resolve renovando-o e enviando de
novo, que é o assunto da aula 20. Mesmo assim não é uma nova tentativa simples, porque algo precisa
mudar antes.

## Um servidor que se comporta mal sob encomenda

A pasta desta aula é `~/planner/retry`, e o servidor dela é o da aula 8, crescido de dois jeitos.
**Ele dá a cada sessão nova um id próprio**, `n1`, `n2`, como muitos servidores reais fazem, e dá
para mandá-lo falhar: cada palavra depois de `node server.ts` é como responder à próxima requisição
que muda alguma coisa. Salve isto como `server.ts`:

```typescript
// server.ts: lesson 8's server, grown for this lesson. It gives each new session an id of its
// own, and it can be told to misbehave: `node server.ts 503 429 drop` answers the first three
// requests that change something that way, and every later one normally.
import { createServer, type ServerResponse } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number };
const sessions: Session[] = [];
const faults = process.argv.slice(2);

function reply(res: ServerResponse, status: number, body: unknown, headers = {}) {
  res.writeHead(status, { "content-type": "application/json", ...headers }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  if (req.method === "GET") return reply(res, 200, sessions);
  const fault = faults.shift();
  console.log(req.method, req.url, fault ?? "ok");
  if (fault === "503") return reply(res, 503, { error: "busy, try again" });
  if (fault === "429") return reply(res, 429, { error: "too many requests" }, { "retry-after": "2" });
  if (fault === "400") return reply(res, 400, { error: "minutes must be a number" });
  if (req.method !== "POST") return reply(res, 405, { error: "method not allowed" });
  const session = { ...JSON.parse(text), id: `n${sessions.length + 1}` };
  sessions.push(session);
  if (fault === "drop") return req.socket.destroy(); // saved, and the answer never leaves
  reply(res, 201, session);
}).listen(8009, "127.0.0.1", () => console.log("listening on 8009"));
```

O `drop` é o mais traiçoeiro deles: o servidor salva a sessão e fecha a conexão antes de a resposta
sair. A última seção da aula é sobre ele.

As esperas vêm de um módulo pequeno que a próxima seção explica. Salve-o agora como `backoff.ts`:

```typescript
// backoff.ts: how long to wait before the next try, with a seeded generator so it repeats.

// mulberry32: a tiny generator of numbers in [0, 1). The same seed gives the same sequence.
export function seeded(seed: number): () => number {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Exponential: double the ceiling on every attempt, up to a cap.
export function ceiling(attempt: number, base: number, cap: number): number {
  return Math.min(cap, base * 2 ** (attempt - 1));
}

// Full jitter: wait a random time between zero and the ceiling.
export function fullJitter(attempt: number, base: number, cap: number, random: () => number): number {
  return Math.floor(random() * ceiling(attempt, base, cap));
}
```

## O laço de novas tentativas

O programa envia uma sessão nova, do jeito que uma drenagem envia uma operação, e decide depois de
cada resposta se tenta de novo:

```schooling-example
{"language": "typescript", "file": "retry.ts", "parts": [{"code": "// retry.ts: send one new session to the server, retrying what is worth retrying.\nimport { seeded, fullJitter } from \"./backoff.ts\";\n\nconst SERVER = \"http://127.0.0.1:8009/sessions\";\nconst BASE = 200, CAP = 5000, TRIES = 5, TIMEOUT = 2000; // milliseconds, and attempts in all\nconst random = seeded(7);\nconst body = JSON.stringify({ course: \"guitar\", date: \"2026-10-23\", minutes: 25 });\n", "note": "Quatro números decidem a política: o teto da primeira espera, a espera mais longa, quantas tentativas ao todo e quanto uma tentativa pode durar. A semente faz as esperas se repetirem."}, {"code": "function worthRetrying(status: number): boolean {\n  return status >= 500 || status === 429 || status === 408;\n}\n", "note": "A classificação. Um 5xx é problema do servidor, 429 pede ao cliente que vá mais devagar e 408 diz que a requisição demorou demais; todo outro status é uma resposta a guardar."}, {"code": "for (let attempt = 1; attempt <= TRIES; attempt++) {\n  let wait = fullJitter(attempt, BASE, CAP, random);\n  try {\n    const res = await fetch(SERVER, {\n      method: \"POST\", body, headers: { \"content-type\": \"application/json\" }, signal: AbortSignal.timeout(TIMEOUT),\n    });", "note": "Cada tentativa tem o próprio prazo. Sem o `AbortSignal.timeout`, uma requisição a um servidor que aceitou a conexão e nunca responde esperaria para sempre."}, {"code": "    if (res.ok) {\n      console.log(`attempt ${attempt}: ${res.status}, saved as ${(await res.json()).id}`);\n      break;\n    }\n    if (!worthRetrying(res.status)) {\n      console.log(`attempt ${attempt}: ${res.status}, not retrying: ${(await res.json()).error}`);\n      break;\n    }", "note": "Um sucesso encerra o laço, e um status que não vale repetir também: o motivo do servidor é impresso e a operação fica para a pessoa, como faz a tabela dead da aula 8."}, {"code": "    const after = Number(res.headers.get(\"retry-after\"));\n    if (after > 0) wait = Math.min(after * 1000, CAP);\n    console.log(`attempt ${attempt}: ${res.status}` + (attempt < TRIES ? `, waiting ${wait} ms${after > 0 ? \" as Retry-After asks\" : \"\"}` : \"\"));", "note": "Se o servidor indicou uma espera em `Retry-After`, ela substitui a calculada, ainda limitada pelo teto."}, {"code": "  } catch (e) {\n    const why = (e as Error).name === \"TimeoutError\" ? \"timed out\" : \"no answer\";\n    console.log(`attempt ${attempt}: ${why}` + (attempt < TRIES ? `, waiting ${wait} ms` : \"\"));\n  }", "note": "Nenhuma resposta, ou nenhuma resposta a tempo. As duas valem uma nova tentativa, e as duas deixam o cliente sem saber se o servidor fez o trabalho."}, {"code": "  if (attempt === TRIES) console.log(\"giving up for now; the operation stays in the outbox\");\n  else await new Promise((resolve) => setTimeout(resolve, wait));\n}", "note": "Depois da última tentativa o laço para em vez de esperar. A operação continua na caixa de saída, e a próxima drenagem recomeça da tentativa 1."}]}
```

Suba o servidor para responder 503 duas vezes e depois funcionar, `node server.ts 503 503` num
segundo terminal, e envie. Depois pare o servidor com Ctrl+C, suba-o como `node server.ts 400` e
envie de novo:

```
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 503, waiting 2 ms
attempt 2: 503, waiting 24 ms
attempt 3: 201, saved as n1
ana@dev:~/planner/retry$ node retry.ts
attempt 1: 400, not retrying: minutes must be a number
```

Os 503 foram repetidos e a terceira tentativa salvou a sessão. O 400 não foi repetido nenhuma vez,
e o motivo do servidor foi impresso no lugar, porque nenhum número de tentativas transforma uma
requisição malformada numa boa.
