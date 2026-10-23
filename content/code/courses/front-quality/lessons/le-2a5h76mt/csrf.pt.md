---
title: Cross-site request forgery, e a checagem do Origin
version: 1
---

**Um cookie é mandado pelo navegador em toda requisição ao site dele, quem quer que tenha começado a
requisição.** Então uma página de outro site consegue fazer o navegador da pessoa mandar uma requisição à
API do planner, com o cookie do planner junto, e a API vê uma requisição logada a que tem todo motivo
para obedecer. A página não consegue ler a resposta, como a aula 7 mostrou; nem precisa, se a própria
requisição faz o estrago. Isso é o cross-site request forgery.

O planner já está bem defendido, e vale ver por quê antes de acrescentar algo:

- **O cookie é `SameSite=Lax`**, desde a aula 5, então o navegador o deixa fora de requisições que outro
  site começa com `fetch` ou com um `POST` de formulário. Só um link simples que a pessoa segue o leva, e
  um link é um `GET`, que no planner não muda nada.
- **A API recebe JSON**, e um `POST` JSON de outra origem passa por preflight, que a lista de permissão da
  aula 7 recusa antes de a requisição ser mandada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l09-csrf\" aria-label=\"Uma página de outro site, aberta no navegador da pessoa, faz o navegador mandar um POST para a API do planner. Três checagens ficam no caminho. Primeira, o SameSite=Lax: o navegador deixa o cookie do planner fora de uma requisição que outro site começou. Segunda, o preflight: um POST JSON de outra origem é anunciado com OPTIONS, e a lista de permissão da API o recusa. Terceira, no servidor, o cabeçalho Origin nomeia o outro site, que não está na lista, e a API responde 403. Só uma requisição que passa pelas três chega ao código que desloga uma pessoa.\"><defs><marker id=\"l09-csrf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-csrf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma página de outro site</text><rect x=\"10\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o navegador da pessoa</text><rect x=\"580\" y=\"75\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a API do planner</text><path d=\"M85 60 L85 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-amber)\"></path><text x=\"92\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">POST /api/logout</text><rect x=\"200\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"256.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">1  SameSite=Lax</text><text x=\"256.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">cookie fica de fora</text><rect x=\"325\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"381.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">2  preflight, lista</text><text x=\"381.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">POST JSON recusado</text><rect x=\"450\" y=\"120\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"506.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">3  checagem do Origin</text><text x=\"506.0\" y=\"151.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">403 no servidor</text><path d=\"M160 150 L200 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M312 146 L325 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M437 146 L450 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path><path d=\"M562 146 L645 146 L645 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-csrf-ah-paper-dim)\"></path></svg>", "caption": "Três defesas em fila, duas do navegador e uma do próprio servidor. A terceira é a que segura quando as outras duas não se aplicam.", "same": ["1 SameSite=Lax"]}
```

**Duas defesas que vêm ambas de outro lugar** são o motivo para acrescentar uma terceira que pertence ao
servidor: toda requisição que muda algo diz de onde veio, no cabeçalho `Origin` que o navegador define e
que nenhuma página consegue forjar, e o servidor recusa uma de um site que não conhece. Essa checagem
sobrevive a um cookie definido sem `SameSite`, a um navegador que não o aplica, e a um endereço que um dia
aceite um formulário. Acrescente o teste ao fim do `server/api.test.mjs`:

```javascript
// server/api.test.mjs, below what is there
test("a request that changes something, sent from another site, is refused", async () => {
  const cookie = cookieOf(await signIn());
  const response = await fetch(`${base}/api/logout`, {
    method: "POST",
    headers: { cookie, origin: "https://elsewhere.example" },
  });
  expect(response.status).toBe(403);
  const plan = await fetch(`${base}/api/plan`, { headers: { cookie } });
  expect(plan.status).toBe(200);
});
```

**A testemunha é um logout**, a requisição mais inofensiva que a API tem: se outro site consegue deslogar
uma pessoa, consegue fazer o que mais a API permitir. O teste a manda com o cookie e um `Origin` de fora,
e depois confere que o login sobreviveu.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"
 FAIL  server/api.test.mjs > a request that changes something, sent from another site, is refused
AssertionError: expected 200 to be 403 // Object.is equality
 Test Files  1 failed (1)
      Tests  1 failed | 5 passed (6)
```

**200**: a API deslogou a ana com base numa requisição de um site de que nunca ouviu falar. A correção é
uma checagem antes de qualquer `POST`, e a origem do próprio site empacotado entra na lista, já que o
preview da aula 8 serve o planner na porta 4173:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 5dc126a..ac162c1 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -39,7 +39,7 @@ function send(res, status, body, headers = {}) {
   res.end(JSON.stringify(body) + "\n");
 }
 
-const allowed = new Set(["http://localhost:5173"]);
+const allowed = new Set(["http://localhost:5173", "http://localhost:4173"]);
 
 function corsHeaders(req) {
   if (!allowed.has(req.headers.origin)) return {};
@@ -61,6 +61,10 @@ export function createApi() {
       });
       return res.end();
     }
+    const origin = req.headers.origin;
+    if (req.method === "POST" && origin !== undefined && !allowed.has(origin)) {
+      return send(res, 403, { error: "cross-site request refused" });
+    }
 
     if (req.method === "POST" && path === "/api/login") {
       const { name, password } = await readJson(req);
```

Uma requisição sem `Origin` nenhum, que é o que o `curl` e o `signIn()` dos testes mandam, passa, porque
os navegadores sempre mandam um num `POST`, e uma requisição sem ele não veio de uma página. Toda
requisição que um navegador manda de outro site o leva, e é recusada.

```
ana@dev:~/planner$ npx vitest run server/api.test.mjs

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  6 passed (6)
   Start at  20:42:12
   Duration  487ms (tests 62%, import 30%, transform 7%, worker 1%)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Refuse a POST whose Origin is not the planner's"
```

## Tokens, e quando usá-los

A defesa clássica é um **token CSRF**: um valor aleatório que o servidor põe em cada formulário e confere
a cada envio, que outro site não consegue ler e, portanto, não consegue mandar. É a ferramenta certa para
uma aplicação feita de formulários renderizados no servidor, e a maioria dos frameworks o gera. Para uma
API chamada com `fetch` e um cookie `SameSite`, a checagem do Origin acima faz o mesmo trabalho sem estado
para guardar, e a cheat sheet de CSRF do OWASP descreve essa checagem como uma defesa a acrescentar ao
lado das outras.
