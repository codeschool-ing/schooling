---
title: O erro, visto num navegador de verdade
version: 1
---

**O navegador relata uma falha de CORS no console e entrega à página nada além de um `TypeError`**, e é
por isso que o erro confunde da primeira vez: o código da página só fica sabendo que o fetch falhou, e o
motivo está em outro lugar. Um programa curto mostra as duas metades de uma vez. Ele abre uma página no
Chromium, roda uma expressão nela, e mostra as requisições que a página fez a outras origens, o que o
console disse, e o resultado. Salve como `server/look.mjs`:

```javascript
// server/look.mjs
import { chromium } from "@playwright/test";

const [address, code] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const origin = new URL(address).origin;
page.on("request", (request) => {
  if (new URL(request.url()).origin !== origin) console.log(`request:  ${request.method()} ${request.url()}`);
});
page.on("console", (message) => {
  if (!message.text().startsWith("[vite]")) console.log(`console:  ${message.text()}`);
});
await page.goto(address);
console.log("result:  ", await page.evaluate(code));
await browser.close();
```

Ele pula as linhas de console que o próprio cliente do Vite mostra, que só dizem que ele conectou. Com a
API e o servidor de desenvolvimento rodando, eis a página do planner pedindo à API direto, na porta dela,
em vez de pelo proxy:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ 'fetch("http://localhost:3000/api/plan").then((r) => r.status, (e) => String(e))'
request:  GET http://localhost:3000/api/plan
console:  Access to fetch at 'http://localhost:3000/api/plan' from origin 'http://localhost:5173' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
console:  Failed to load resource: net::ERR_FAILED
result:   TypeError: Failed to fetch
```

**Quatro linhas, e cada uma diz uma coisa diferente.** O navegador *mandou* a requisição: ela está na
lista. O console diz por que a página não pode ler a resposta, `No 'Access-Control-Allow-Origin' header`,
citando as duas origens. E a página recebeu `TypeError: Failed to fetch`, sem status, sem corpo e sem
motivo.

## A requisição chegou

Aquela primeira linha é a parte a lembrar. **O CORS não impediu a requisição de chegar ao servidor**; ele
impediu a página de ler a resposta. O servidor recebeu um GET, não achou cookie, e respondeu 401, a mesma
resposta que o `curl` recebe, e o `curl` não tem política de mesma origem nenhuma:

```
ana@dev:~/planner$ curl -s -i http://localhost:3000/api/plan
HTTP/1.1 401 Unauthorized
content-type: application/json
Date: Fri, 23 Oct 2026 23:20:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"error":"sign in first"}
```

Então o CORS não protege o servidor. Qualquer coisa que não seja um navegador o ignora, e uma requisição
com efeitos, um pagamento ou uma exclusão, pode acontecer mesmo quando a página que a mandou não consegue
ler o que voltou. Proteger um servidor de requisições sobre as quais ele não deveria agir é o assunto da
aula 9, e o CORS não faz parte da resposta.
