---
title: Push
version: 1
---

**A notification shown by a page needs the page. Push reaches a person whose page is closed.** The planner's
server could remind somebody of a session at nine in the morning, with no tab of the planner open, because the
message goes to the browser, which wakes the planner's service worker to show it.

## How a message travels

1. **The page subscribes.** With permission granted, `registration.pushManager.subscribe(...)` asks the browser's
   **push service**, run by the browser's maker, for an address. The answer, a *subscription*, is an endpoint URL
   at that service and two keys. The page sends it to the planner's server, which stores it.
2. **The server sends.** To reach that person, the server makes a request to the endpoint, with the message
   encrypted for the subscription's keys and signed with the server's own **VAPID** key pair, which proves to the
   push service that the message comes from the server the subscription was made for. Libraries do the
   encryption; for Node it is the `web-push` package.
3. **The push service delivers** to the browser, whenever that browser is next online.
4. **The worker wakes**, gets a `push` event, and shows the notification.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The journey of a push message, left to right. The page subscribes at the browser&#x27;s push service and gives the subscription to the planner&#x27;s server. Later the server sends a message to the push service, signed with its VAPID key. The push service delivers it to the browser, which wakes the service worker, and the worker shows the notification. The page does not need to be open.\"><rect x=\"20\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">planner's server</text><rect x=\"200\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">push service</text><rect x=\"380\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the browser</text><rect x=\"560\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">service worker</text><line x1=\"162\" y1=\"96\" x2=\"198\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,96.0 190.6,99.1 190.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2. send, signed</text><line x1=\"342\" y1=\"96\" x2=\"378\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,96.0 370.6,99.1 370.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3. deliver</text><line x1=\"522\" y1=\"96\" x2=\"558\" y2=\"96\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,96.0 550.6,99.1 550.6,92.9\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4. wake</text><path d=\"M450 132 V 170 H 90 V 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"270\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. the page subscribes, and the server keeps the subscription</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">notification</text></svg>", "caption": "Only the last box runs code you wrote in the visitor's browser."}
```

## The worker's half

The worker's part is the only part that runs in the visitor's browser, and it is short. Two handlers, one for the
message and one for a click on the notification it shows; add them at the end of `public/sw.js`:

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

**The worker changed, so its cache name changes too**, as lesson 10 said: replace the line that defines `CACHE`
with:

```javascript
const CACHE = "planner-v2";
```

## Testing the handler without a push service

**The developer tools' protocol can deliver a push message to a worker directly**, as the push service would,
and that is the part a lesson can run on one computer. `tools/push.ts` does it, then lists the notifications the
worker is showing. Save it in `tools/`:

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

Build, restart, and send one:

```
ana@dev:~/planner$ node tools/push.ts http://localhost:3000/ '{"title": "Study planner", "body": "Git, 30 minutes, today"}'
showing: Study planner, "Git, 30 minutes, today"
```

**The worker's `push` handler read the message and showed it.** What this did not test, and what this course
does not run, is the rest of the journey: subscribing at a real push service, keeping subscriptions on the server
and sending with `web-push`. Those need the planner on a public address with HTTPS, and a server that remembers
people, which is backend work the planner does not have. The click handler is not exercised by any tool either,
because clicking a notification is something only a person, or the system, does.
