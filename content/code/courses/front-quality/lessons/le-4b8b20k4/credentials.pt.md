---
title: O curinga, e por que ele não é a correção
version: 1
---

**A primeira resposta que a maioria das pessoas acha é um cabeçalho, `Access-Control-Allow-Origin: *`, e
ela está errada de um jeito que o próprio navegador recusa.** Experimente, para ver por quê. Acrescente
esta linha no topo do tratador de requisições do `server/api.mjs`, como experimento:

```
ana@dev:~/planner$ git diff server/api.mjs
diff --git a/server/api.mjs b/server/api.mjs
index 855a6cd..95e9548 100644
--- a/server/api.mjs
+++ b/server/api.mjs
@@ -42,6 +42,7 @@ function send(res, status, body, headers = {}) {
 export function createApi() {
   return http.createServer(async (req, res) => {
     const path = new URL(req.url, "http://localhost").pathname;
+    res.setHeader("access-control-allow-origin", "*");
     const login = logins.get(cookie(req, "__Host-sid"));
     const user = login && Date.now() < login.until ? login.name : undefined;
 
```

O `GET` simples de duas seções atrás agora é legível, e a página vê o 401:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan").then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Failed to load resource: the server responded with a status of 401 (Unauthorized)
result:   401
```

Mas a API do planner só vale a pena ser chamada com um cookie, e um `fetch` entre origens só manda cookies
quando pedem, com `credentials: "include"`. Peça:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan", { credentials: "include" }).then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Access to fetch at 'http://localhost:3000/api/plan' from origin 'http://localhost:5173' has been blocked by CORS policy: The value of the 'Access-Control-Allow-Origin' header in the response must not be the wildcard '*' when the request's credentials mode is 'include'.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

**O navegador recusa o curinga quando há credenciais envolvidas**, e a mensagem diz isso por inteiro. Essa
regra é o motivo de o `*` ser só desarrumado e não perigoso: uma resposta que qualquer site pode ler é
lida sem os cookies da pessoa, então ela não carrega nada que fosse só dela. No momento em que há cookies
no jogo, o servidor precisa nomear a única origem em que confia, toda vez, e dizer também
`Allow-Credentials: true`.

Tire o experimento antes de continuar:

```
ana@dev:~/planner$ git checkout server/api.mjs
Updated 1 path from the index
```

## A outra resposta errada

Há um segundo atalho, pior que o primeiro porque o navegador não consegue vê-lo: **ler o cabeçalho
`Origin` da requisição e devolvê-lo direto**, diga ele o que disser, com credenciais permitidas. Isso
passa em toda checagem que um navegador faz e deixa todo site da internet ler toda resposta com os
cookies da pessoa junto. É a política de mesma origem desligada, escrita em três linhas. Uma lista de
permissão é a única resposta: uma lista fixa das origens para as quais esta API foi feita, e nada para
mais ninguém.
