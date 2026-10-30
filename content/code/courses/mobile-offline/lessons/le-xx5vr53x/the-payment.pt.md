---
title: O pagamento enviado duas vezes
version: 1
---

**Uma pessoa toca em Comprar num trem. A requisição chega ao servidor, o cartão é cobrado e a
resposta se perde num túnel. O app faz o que a aula 9 ensinou e tenta de novo, e o cartão é cobrado
uma segunda vez.** Ninguém cometeu um erro que alguma linha de código isolada mostraria. O cliente
repetiu uma requisição que falhou, como devia; o servidor cobrou um cartão por uma requisição válida,
como devia. O defeito está no espaço entre os dois, e custa dinheiro à pessoa e um estorno e uma
conversa de suporte à empresa.

É o mesmo formato da sessão duplicada da aula 9, com um número junto. Uma segunda sessão de estudo
custa à pessoa uma semana confusa; uma segunda cobrança de R$ 49,00 custa a ela uma ligação para o
banco. Empresas de pagamento encontraram isso primeiro e em escala, e é por isso que a correção
carrega o vocabulário delas.

## Vendo acontecer

A pasta desta aula é `~/planner/idempotency`. O servidor é o da aula 9, crescido: ele vende cursos
em `/purchases` e consegue lembrar respostas, que é o assunto da próxima seção. Por ora, leia a
parte que cobra: uma compra é acrescentada a `purchases`, e isso é o cartão sendo cobrado. Salve
isto como `server.ts`:

```typescript
// server.ts: lesson 9's server, grown for this lesson. It sells courses, and it remembers the
// answer it gave to each Idempotency-Key, per user, for 24 hours. `node server.ts drop slow`
// misbehaves on the first two requests that change something, as in lesson 9.
import { createServer, type ServerResponse } from "node:http";
import { createHash } from "node:crypto";

type Saved = { fingerprint: string; status: number; body: unknown; at: number } | "in progress";
const purchases: { id: string; user: string; course: string; cents: number }[] = [];
const sessions = new Map<string, unknown>();
const answers = new Map<string, Saved>(); // "<user> <key>" -> the answer given
const DAY = 24 * 60 * 60 * 1000;
const faults = process.argv.slice(2);

function reply(res: ServerResponse, status: number, body: unknown, headers = {}) {
  res.writeHead(status, { "content-type": "application/json", ...headers }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const user = String(req.headers["x-user"]); // stands in for the signed-in account
  if (req.method === "GET" && req.url === "/purchases") return reply(res, 200, purchases);
  if (req.method === "GET") return reply(res, 200, [...sessions.values()]);
  const fault = faults.shift();
  console.log(req.method, req.url, user, fault ?? "ok");

  // PUT /sessions/<id>: the client chose the id, so doing it twice is doing it once.
  if (req.method === "PUT") {
    sessions.set(req.url!, JSON.parse(text));
    return reply(res, 200, JSON.parse(text));
  }

  // POST /purchases: charging money, so a retry must not charge again.
  const key = req.headers["idempotency-key"];
  const slot = `${user} ${key}`;
  const fingerprint = createHash("sha256").update(text).digest("hex");
  const saved = key ? answers.get(slot) : undefined;
  if (saved === "in progress") return reply(res, 409, { error: "a request with this key is still running" });
  if (saved && Date.now() - saved.at < DAY) {
    if (saved.fingerprint !== fingerprint) return reply(res, 422, { error: "this key was used with a different body" });
    return reply(res, saved.status, saved.body, { "idempotent-replayed": "true" });
  }
  if (key) answers.set(slot, "in progress");
  if (fault === "slow") await new Promise((resolve) => setTimeout(resolve, 1000));
  const purchase = { id: `p${purchases.length + 1}`, user, ...JSON.parse(text) };
  purchases.push(purchase); // the card is charged here
  if (key) answers.set(slot, { fingerprint, status: 201, body: purchase, at: Date.now() });
  if (fault === "drop") return req.socket.destroy();
  reply(res, 201, purchase);
}).listen(8010, "127.0.0.1", () => console.log("listening on 8010"));
```

O cliente é o botão Comprar: uma compra do curso de Estatística, 4900 centavos, repetida numa
resposta perdida exatamente como o laço da aula 9 repete. Sem argumento, ele não manda chave. Salve
isto como `buy.ts`:

```typescript
// buy.ts: buy a course from the planner, retrying a lost answer as lesson 9 does.
// `node buy.ts` sends no key; `node buy.ts key` makes one when the person taps Buy.
import { randomUUID } from "node:crypto";

const withKey = process.argv[2] === "key";
const key = randomUUID(); // made once, before the first try, and sent with every retry
const body = JSON.stringify({ course: "statistics", cents: 4900 });

for (let attempt = 1; attempt <= 3; attempt++) {
  try {
    const res = await fetch("http://127.0.0.1:8010/purchases", {
      method: "POST",
      body,
      headers: { "content-type": "application/json", "x-user": "ana", ...(withKey ? { "idempotency-key": key } : {}) },
      signal: AbortSignal.timeout(2000),
    });
    const replayed = res.headers.get("idempotent-replayed") ? ", replayed" : "";
    console.log(`attempt ${attempt}: ${res.status}${replayed}`, await res.json());
    break;
  } catch {
    console.log(`attempt ${attempt}: no answer, trying again`);
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
}
```

Suba o servidor como `node server.ts drop`, para ele cobrar e depois perder a resposta, e toque em
Comprar:

```
ana@dev:~/planner/idempotency$ node buy.ts
attempt 1: no answer, trying again
attempt 2: 201 { id: 'p2', user: 'ana', course: 'statistics', cents: 4900 }
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/purchases
[{"id":"p1","user":"ana","course":"statistics","cents":4900},{"id":"p2","user":"ana","course":"statistics","cents":4900}]
```

**Um toque, duas cobranças.** `p1` foi a primeira tentativa, cobrada, com a resposta perdida; `p2`
foi a nova tentativa, cobrada de novo. O cliente imprimiu um sucesso, então a tela disse "comprado"
uma vez. A fatura da pessoa vai dizer duas.

## A correção, numa frase

O cliente dá um nome à operação antes da primeira tentativa e manda o nome em toda nova tentativa; o
servidor lembra a resposta que deu a cada nome e, ao ver um nome de novo, dá a mesma resposta sem
refazer o trabalho. **O nome é uma chave de idempotência.** Uma operação é *idempotente* quando
fazê-la duas vezes tem o mesmo efeito que fazê-la uma, e a chave é o que faz um `POST`, que não é,
se comportar como se fosse.

A API da Stripe a recebe num cabeçalho, `Idempotency-Key`, e a maioria das APIs de pagamento copiou
o formato. O grupo de trabalho de APIs HTTP do IETF tem um rascunho padronizando-o, *The
Idempotency-Key HTTP Header Field*; ele ainda é um rascunho, não uma RFC, e o curso o cita como tal.
