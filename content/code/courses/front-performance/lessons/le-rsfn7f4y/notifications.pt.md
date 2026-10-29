---
title: Notificações
version: 1
---

**Uma notificação é uma mensagem que o sistema mostra fora da página**: no canto da tela, na tela de bloqueio de um
celular. Uma página mostra uma pelo service worker, com `registration.showNotification(title, options)`, e só com a
permissão da pessoa, que pertence ao site e é pedida uma vez.

O `Notification.permission` é uma de três palavras: `default`, ninguém perguntou; `granted`; e `denied`, sobre o que
uma página não pode perguntar de novo: só a pessoa pode mudar, nas configurações do navegador para o site.

## Vendo as duas respostas

O `tools/notify.ts` abre uma página e faz o worker dela mostrar uma notificação, uma vez como um visitante a quem
nunca perguntaram, e uma vez como um que permitiu, o que o Playwright consegue conceder antes. Salve-o em `tools/`:

```typescript
// tools/notify.ts: open a page as a visitor who has, or has not, allowed notifications,
// and have the page's service worker show one: what Notification.permission says, and
// what the worker reports it is showing.
//
//   node tools/notify.ts URL [--allow]
import { chromium } from "playwright";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const [url, ...rest] = process.argv.slice(2);
const profile = await mkdtemp(join(tmpdir(), "notify-"));
const context = await chromium.launchPersistentContext(profile, { channel: "chromium" });
// Allowing is the visitor's answer to the browser's question, given here in advance.
if (rest.includes("--allow")) await context.grantPermissions(["notifications"], { origin: new URL(url).origin });
const page = await context.newPage();
await page.goto(url, { waitUntil: "networkidle" });
console.log(await page.evaluate(async () => {
  const worker = await navigator.serviceWorker.ready;
  const lines = [`permission: ${Notification.permission}`];
  try {
    await worker.showNotification("Study planner", { body: "Git, 30 minutes, today", tag: "reminder" });
    const shown = await worker.getNotifications();
    lines.push(...shown.map((n) => `showing: ${n.title}, "${n.body}"`));
  } catch (e) {
    lines.push(`refused: ${(e as Error).message}`);
  }
  return lines.join("\n");
}));
await context.close();
await rm(profile, { recursive: true });
```

```
ana@dev:~/planner$ node tools/notify.ts http://localhost:3000/
permission: default
refused: Failed to execute 'showNotification' on 'ServiceWorkerRegistration': No notification permission has been granted for this origin.
ana@dev:~/planner$ node tools/notify.ts http://localhost:3000/ --allow
permission: granted
showing: Study planner, "Git, 30 minutes, today"
```

**Sem permissão o navegador recusa, com um erro que diz isso**; com ela, o worker informa a notificação como
mostrada. Uma página que não confere a permissão antes recebe exatamente esse erro, e por isso a chamada está num
`try`.

## Perguntando

A pergunta em si é o `Notification.requestPermission()`, que mostra a caixa do navegador e se resolve com a
resposta. Duas regras decidem se ela algum dia recebe um sim:

- **Pergunte depois de a pessoa fazer algo que dê sentido à pergunta**, como um clique em *Remind me before each
  session*. O Firefox e o Safari ignoram um pedido que não vem de um clique, e o Chromium mostra uma versão discreta
  da pergunta, um ícone pequeno na barra de endereço, para sites cujos pedidos costumam ser recusados.
- **Nunca pergunte na chegada.** Uma página que pergunta antes de mostrar qualquer coisa recebe *não* da maioria das
  pessoas, e um *não* é permanente para aquele site. O planner não pergunta nada nesta aula; a seção "Pedindo
  atenção" diz quando deveria.
