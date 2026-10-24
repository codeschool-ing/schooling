---
title: A correção, e os testes verdes
version: 1
---

**Três mudanças no `server/api.mjs`, uma para cada teste**: o cookie ganha o prefixo e os dois
atributos, um login registra quando termina, e o logout apaga o login no servidor.

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index a6bbc41..855a6cd 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -42,17 +42,21 @@ function send(res, status, body, headers = {}) {
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
-    const user = logins.get(cookie(req, "sid"));
+    const login = logins.get(cookie(req, "__Host-sid"));
+    const user = login && Date.now() < login.until ? login.name : undefined;
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
       if (!passwordIsRight(name, password)) return send(res, 401, { error: "wrong name or password" });
       const sid = randomBytes(32).toString("base64url");
-      logins.set(sid, name);
-      return send(res, 200, { name }, { "set-cookie": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });
+      logins.set(sid, { name, until: Date.now() + 8 * 60 * 60 * 1000 });
+      return send(res, 200, { name }, {
+        "set-cookie": `__Host-sid=${sid}; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=28800`,
+      });
     }
     if (req.method === "POST" && path === "/api/logout") {
-      return send(res, 200, {}, { "set-cookie": "sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0" });
+      logins.delete(cookie(req, "__Host-sid"));
+      return send(res, 200, {}, { "set-cookie": "__Host-sid=; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0" });
     }
     if (req.method === "GET" && path === "/api/plan") {
       if (!user) return send(res, 401, { error: "sign in first" });
```

- O `logins` agora liga um id a **um nome e um horário**, o `until`, oito horas depois do login, e um
  login depois do `until` dele é tratado como login nenhum. As mesmas oito horas vão no `Max-Age` do
  cookie, para o navegador esquecê-lo no momento em que o servidor o recusaria.
- **O logout apaga a entrada**, então o id para de querer dizer alguma coisa onde quer que haja uma cópia
  dele.
- O cookie é `__Host-sid`, com `Secure`, e o servidor lê esse nome.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  20:13:26
   Duration  405ms (tests 61%, import 27%, transform 10%, worker 1%)
```

Os três verdes, e as duas suítes inteiras continuam passando, inclusive o teste de navegador da seção
anterior, já que ele perguntava sobre o `httpOnly` e não sobre um nome:

```
ana@dev:~/planner$ npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"
 Test Files  5 passed (5)
      Tests  30 passed (30)
  6 passed (3.0s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "End a login on sign-out and after eight hours, and mark its cookie __Host-"
```
