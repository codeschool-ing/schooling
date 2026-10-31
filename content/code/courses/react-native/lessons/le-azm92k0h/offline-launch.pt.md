---
title: Abrindo sem servidor
version: 1
---

**Na web, o AsyncStorage é o `localStorage` do navegador**, então o caminho inteiro pode rodar num
navegador: carregar o plano uma vez, cortar o servidor, abrir o app de novo. O Playwright consegue cortar
uma página de um endereço e deixar o resto em paz, o que se parece mais com um celular que perdeu o
servidor do que desligar a rede: o próprio build web continua carregando. Salve isto como `offline.mjs`:

```javascript
// offline.mjs: open the planner three times and say what each visit shows: once with the server, once
// more in the same browser with the server cut off, and once in a fresh browser with it cut off.
//
//   node offline.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const cutOff = (target) => target.route("http://localhost:8008/**", (route) => route.abort());

async function visit(context, label) {
  const page = await context.newPage();
  await page.goto(url);
  const shown = page.getByText(/^This week: |^The plan could not be loaded/);
  await shown.waitFor();
  console.log(`${label}: ${await shown.innerText()}`);
  return page;
}

const mine = await browser.newContext();
const first = await visit(mine, "with the server");
await first.waitForTimeout(1500); // the persister writes at most once a second
const stored = await first.evaluate(() => localStorage.getItem("planner-cache")?.length ?? 0);
console.log(`stored: ${stored} characters under planner-cache`);
await first.close(); // one tab at a time: SQLite on the web holds its file for the tab that opened it
await cutOff(mine);
await visit(mine, "same browser, server cut off");
const fresh = await browser.newContext();
await cutOff(fresh);
await visit(fresh, "new browser, server cut off");
await browser.close();
```

Um *context* do Playwright é um perfil de navegador: as páginas dele dividem o armazenamento, e um context
novo começa sem nada, como um celular em que o app acabou de ser instalado. Com o servidor rodando e o
build web exportado e servido como na aula 10:

```
ana@dev:~/planner$ node offline.mjs 'http://localhost:8082/?today=2026-10-21'
with the server: This week: 75 of 125 minutes done
stored: 1006 characters under planner-cache
same browser, server cut off: This week: 75 of 125 minutes done
new browser, server cut off: The plan could not be loaded: Failed to fetch
```

**Leia as três visitas como três celulares.** O primeiro tinha o servidor e guardou o plano, uns mil
caracteres de JSON. O segundo é o mesmo celular sem servidor: o plano está lá na hora, vindo do
armazenamento, e o pedido que falha por trás não muda nada na tela. O terceiro nunca viu o plano e não
alcança o servidor, então diz isso, com a frase da aula 10.

A segunda visita também é onde o cache mentiria se fosse deixado sozinho: um plano de um dia atrás parece
exatamente um buscado há um segundo. **A resposta do planner é o `maxAge` de um dia.** Uma tela que
mostrasse quando o plano foi buscado, com o `dataUpdatedAt` da consulta, seria uma resposta melhor, e é
uma mudança pequena que você pode fazer na tela do curso.
