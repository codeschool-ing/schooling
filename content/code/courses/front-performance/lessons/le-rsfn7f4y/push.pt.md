---
title: Push
version: 1
---

**Uma notificação mostrada por uma página precisa da página. O push alcança uma pessoa cuja página está fechada.** O
servidor do planner poderia lembrar alguém de uma sessão às nove da manhã, sem aba nenhuma do planner aberta, porque
a mensagem vai para o navegador, que acorda o service worker do planner para mostrá-la.

## Como uma mensagem viaja

1. **A página se inscreve.** Com a permissão concedida, o `registration.pushManager.subscribe(...)` pede ao **serviço
   de push** do navegador, mantido por quem faz o navegador, um endereço. A resposta, uma *inscrição*, é uma URL de
   endpoint nesse serviço e duas chaves. A página a manda ao servidor do planner, que a guarda.
2. **O servidor manda.** Para alcançar aquela pessoa, o servidor faz uma requisição ao endpoint, com a mensagem
   cifrada para as chaves da inscrição e assinada com o par de chaves **VAPID** do próprio servidor, que prova ao
   serviço de push que a mensagem vem do servidor para o qual a inscrição foi feita. Bibliotecas fazem a cifra; para
   o Node é o pacote `web-push`.
3. **O serviço de push entrega** ao navegador, na próxima vez que esse navegador estiver online.
4. **O worker acorda**, recebe um evento `push`, e mostra a notificação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O caminho de uma mensagem push, da esquerda para a direita. A página se inscreve no serviço de push do navegador e entrega a inscrição ao servidor do planner. Depois o servidor manda uma mensagem ao serviço de push, assinada com a sua chave VAPID. O serviço de push a entrega ao navegador, que acorda o service worker, e o worker mostra a notificação. A página não precisa estar aberta.\"><rect x=\"20\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor do planner</text><rect x=\"200\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">serviço de push</text><rect x=\"380\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o navegador</text><rect x=\"560\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">service worker</text><line x1=\"162\" y1=\"96\" x2=\"198\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,96.0 190.6,99.1 190.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2. manda, assinada</text><line x1=\"342\" y1=\"96\" x2=\"378\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,96.0 370.6,99.1 370.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3. entrega</text><line x1=\"522\" y1=\"96\" x2=\"558\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,96.0 550.6,99.1 550.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4. acorda</text><path d=\"M450 132 V 170 H 90 V 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"270\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. a página se inscreve, e o servidor guarda a inscrição</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">notificação</text></svg>", "caption": "Só a última caixa roda, no navegador do visitante, código que você escreveu.", "same": ["service worker"]}
```

## A metade do worker

A parte do worker é a única que roda no navegador do visitante, e é curta. Dois tratadores, um para a mensagem e um
para um clique na notificação que ele mostra; acrescente-os no fim do `public/sw.js`:

```javascript

// A push message from the planner's server, delivered by the browser's push service, is
// shown as a notification. The server decides what it says; the worker only shows it.
self.addEventListener("push", (event) => {
  const { title, body } = event.data.json();
  event.waitUntil(self.registration.showNotification(title, { body, tag: "reminder" }));
});

// A click on a notification brings forward a window already open on the planner, or opens one.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(clients.matchAll({ type: "window" }).then((open) =>
    open.length > 0 ? open[0].focus() : clients.openWindow("/")));
});
```

**O worker mudou, então o nome do cache muda também**, como a aula 10 disse: troque a linha que define o `CACHE`
por:

```javascript
const CACHE = "planner-v2";
```

## Testando o tratador sem serviço de push

**O protocolo das ferramentas de desenvolvedor consegue entregar uma mensagem push direto a um worker**, como o
serviço de push faria, e essa é a parte que uma aula consegue rodar num computador. O `tools/push.ts` faz isso, e
depois lista as notificações que o worker está mostrando. Salve-o em `tools/`:

```typescript
// tools/push.ts: deliver a push message to a page's service worker the way the browser's
// push service would, through the DevTools protocol, and say what notification it showed.
// No push service is involved, so this tests the worker's handler, not the delivery.
//
//   node tools/push.ts URL '{"title": "...", "body": "..."}'
import { chromium } from "playwright";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const [url, data] = process.argv.slice(2);
const profile = await mkdtemp(join(tmpdir(), "push-"));
const context = await chromium.launchPersistentContext(profile, { channel: "chromium" });
await context.grantPermissions(["notifications"], { origin: new URL(url).origin });
const page = await context.newPage();
const cdp = await context.newCDPSession(page);
const registered = new Promise<string>((resolve) => cdp.on("ServiceWorker.workerRegistrationUpdated", (e) => {
  const mine = e.registrations.find((r) => r.scopeURL.startsWith(new URL(url).origin));
  if (mine) resolve(mine.registrationId);
}));
await cdp.send("ServiceWorker.enable");
await page.goto(url, { waitUntil: "networkidle" });
await page.evaluate(() => navigator.serviceWorker.ready);
await cdp.send("ServiceWorker.deliverPushMessage", { origin: new URL(url).origin, registrationId: await registered, data });
await page.waitForTimeout(500);
for (const line of await page.evaluate(async () =>
  (await (await navigator.serviceWorker.ready).getNotifications()).map((n) => `showing: ${n.title}, "${n.body}"`))) {
  console.log(line);
}
await context.close();
await rm(profile, { recursive: true });
```

Faça o build, reinicie e mande uma:

```
ana@dev:~/planner$ node tools/push.ts http://localhost:3000/ '{"title": "Study planner", "body": "Git, 30 minutes, today"}'
showing: Study planner, "Git, 30 minutes, today"
```

**O tratador `push` do worker leu a mensagem e a mostrou.** O que isto não testou, e o que este curso não roda, é o
resto do caminho: inscrever-se num serviço de push de verdade, guardar inscrições no servidor e mandar com o
`web-push`. Isso precisa do planner num endereço público com HTTPS, e de um servidor que se lembre das pessoas, que é
trabalho de backend que o planner não tem. O tratador de clique também não é exercitado por ferramenta nenhuma,
porque clicar numa notificação é algo que só uma pessoa, ou o sistema, faz.
