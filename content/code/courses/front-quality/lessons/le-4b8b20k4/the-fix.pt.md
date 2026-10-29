---
title: Uma lista de permissão, uma resposta ao preflight, e dois testes
version: 1
---

**A correção é uma lista das origens em que a API confia, que para o planner é uma, e os cabeçalhos que
dizem isso em toda resposta a uma delas.** Primeiro os testes. Acrescente estes dois ao fim do
`server/api.test.mjs`:

```javascript
// server/api.test.mjs, below what is there
test("a preflight from the planner's page is allowed, with credentials", async () => {
  const response = await fetch(`${base}/api/login`, {
    method: "OPTIONS",
    headers: {
      origin: "http://localhost:5173",
      "access-control-request-method": "POST",
      "access-control-request-headers": "content-type",
    },
  });
  expect(response.status).toBe(204);
  expect(response.headers.get("access-control-allow-origin")).toBe("http://localhost:5173");
  expect(response.headers.get("access-control-allow-credentials")).toBe("true");
  expect(response.headers.get("access-control-allow-headers")).toBe("content-type");
});

test("any other origin is given no permission to read", async () => {
  const response = await fetch(`${base}/api/plan`, { headers: { origin: "https://elsewhere.example" } });
  expect(response.headers.get("access-control-allow-origin")).toBeNull();
});
```

O `fetch` do Node deixa um teste definir o `Origin` à mão, o que um navegador nunca faria; é exatamente
isso que o torna a ferramenta para perguntar ao servidor o que ele faz para uma origem que deveria
recusar.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"
 FAIL  server/api.test.mjs > a preflight from the planner's page is allowed, with credentials
AssertionError: expected 404 to be 204 // Object.is equality
 Test Files  1 failed (1)
      Tests  1 failed | 4 passed (5)
```

**O primeiro teste falha com um 404**, já que o servidor não sabe nada de `OPTIONS`, e o segundo passa,
porque um servidor que não concede nada também não concede nada a estranhos. Ele está lá para continuar
assim: o curinga da seção anterior o teria deixado vermelho.

A mudança no servidor:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 855a6cd..5dc126a 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -39,11 +39,28 @@ function send(res, status, body, headers = {}) {
   res.end(JSON.stringify(body) + "\n");
 }
 
+const allowed = new Set(["http://localhost:5173"]);
+
+function corsHeaders(req) {
+  if (!allowed.has(req.headers.origin)) return {};
+  return { "access-control-allow-origin": req.headers.origin, "access-control-allow-credentials": "true", vary: "Origin" };
+}
+
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
     const login = logins.get(cookie(req, "__Host-sid"));
     const user = login && Date.now() < login.until ? login.name : undefined;
+    for (const [name, value] of Object.entries(corsHeaders(req))) res.setHeader(name, value);
+
+    if (req.method === "OPTIONS") {
+      res.writeHead(204, {
+        "access-control-allow-methods": "GET, POST",
+        "access-control-allow-headers": "content-type",
+        "access-control-max-age": "600",
+      });
+      return res.end();
+    }
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
```

- **O `allowed` é a lista**, e o `corsHeaders` devolve permissão só para uma origem que está nela. Todo o
  resto não recebe cabeçalho de CORS nenhum, o que o navegador lê como não.
- **O `Vary: Origin`** avisa qualquer cache entre o navegador e o servidor que a resposta depende do
  cabeçalho `Origin`, então uma resposta permitida a uma origem nunca é servida do cache a outra.
- **O `OPTIONS` é respondido com 204** e os métodos e cabeçalhos que a API aceita. O `Max-Age: 600` deixa o
  navegador lembrar a resposta por dez minutos em vez de perguntar antes de cada requisição.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  20:21:02
   Duration  505ms (tests 51%, import 24%, transform 24%, worker 1%)
```

E da página, com o servidor reiniciado: o login, com preflight e credenciais, e depois o plano, com o
cookie que esse login definiu. Os dois são lidos:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ '(async () => { const login = await fetch("http://localhost:3000/api/login", { method: "POST", credentials: "include", headers: { "content-type": "application/json" }, body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }) }); const plan = await fetch("http://localhost:3000/api/plan", { credentials: "include" }); return `sign-in ${login.status}, plan ${plan.status}`; })()'
request:  POST http://localhost:3000/api/login
request:  GET http://localhost:3000/api/plan
result:   sign-in 200, plan 200
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Allow the planner's own origin, and no other, to read the API"
```
