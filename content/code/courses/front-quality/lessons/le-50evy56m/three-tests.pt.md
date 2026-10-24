---
title: Três testes em que o servidor falha
version: 1
---

**O servidor pode ser testado sem navegador nenhum: suba-o numa porta livre dentro do teste, mande
requisições com `fetch`, e leia o que volta.** É por isso que o `api.mjs` exporta o `createApi()` e só
escuta na 3000 quando é rodado diretamente. Salve isto como `server/api.test.mjs`:

```javascript
// server/api.test.mjs
import { afterAll, beforeAll, expect, test, vi } from "vitest";
import { createApi } from "./api.mjs";

let server;
let base;

beforeAll(async () => {
  server = createApi();
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

afterAll(() => {
  server.close();
});

async function signIn() {
  const response = await fetch(`${base}/api/login`, {
    method: "POST",
    body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }),
  });
  return response.headers.get("set-cookie");
}

const cookieOf = (setCookie) => setCookie.split(";")[0];

test("the session cookie is kept from scripts, from plain HTTP and from other hosts", async () => {
  const setCookie = await signIn();
  expect(setCookie).toMatch(/^__Host-sid=/);
  for (const part of ["HttpOnly", "Secure", "SameSite=Lax", "Path=/", "Max-Age=28800"]) {
    expect(setCookie).toContain(part);
  }
});

test("signing out ends the login on the server, not only in the browser", async () => {
  const cookie = cookieOf(await signIn());
  await fetch(`${base}/api/logout`, { method: "POST", headers: { cookie } });
  const response = await fetch(`${base}/api/plan`, { headers: { cookie } });
  expect(response.status).toBe(401);
});

test("a login ends after eight hours, whatever the browser keeps", async () => {
  vi.useFakeTimers({ toFake: ["Date"] });
  try {
    const cookie = cookieOf(await signIn());
    vi.setSystemTime(Date.now() + 8 * 60 * 60 * 1000);
    const response = await fetch(`${base}/api/plan`, { headers: { cookie } });
    expect(response.status).toBe(401);
  } finally {
    vi.useRealTimers();
  }
});
```

O `listen(0)` pede ao sistema operacional qualquer porta livre, então o teste nunca colide com o
servidor que você tem rodando na 3000. O segundo teste é o que mais importa, e a testemunha dele é a mais
simples que existe: **o cookie que uma pessoa tinha antes de fazer logout**, mandado de novo. Se o
servidor ainda responde com o plano, o logout só escondeu o cookie do navegador que clicou no botão, e
qualquer cópia dele, no log de um proxy ou no navegador de outro aparelho, continua funcionando. O
terceiro para o relógio com `toFake: ["Date"]`, então só o `Date` é trocado e a rede mantém os
temporizadores reais.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError|Error:|- Expected|\+ Received|- |\+ | Test Files|      Tests)"
 FAIL  server/api.test.mjs > the session cookie is kept from scripts, from plain HTTP and from other hosts
AssertionError: expected 'sid=M5auRETffnbVctH6wJEPVflGClyD1nnMu…' to match /^__Host-sid=/
- Expected:
+ Received:
 FAIL  server/api.test.mjs > signing out ends the login on the server, not only in the browser
AssertionError: expected 200 to be 401 // Object.is equality
- Expected
+ Received
- 401
+ 200
 FAIL  server/api.test.mjs > a login ends after eight hours, whatever the browser keeps
AssertionError: expected 200 to be 401 // Object.is equality
- Expected
+ Received
- 401
+ 200
 Test Files  1 failed (1)
      Tests  3 failed (3)
```

**Os três falham, e cada um diz o que está errado.** O cookie se chama `sid` e não tem nem `Secure` nem
prazo. O cookie antigo ainda buscou o plano depois do logout: 200 onde o teste queria 401. E oito horas
depois o login continuava vivo, porque o servidor nunca anotou quando ele começou.
