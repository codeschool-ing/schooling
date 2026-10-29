---
title: Notifications
version: 1
---

**A notification is a message the system shows outside the page**: in the corner of the screen, on the lock
screen of a phone. A page shows one through its service worker, with `registration.showNotification(title,
options)`, and only with the person's permission, which belongs to the site and is asked for once.

`Notification.permission` is one of three words: `default`, nobody has asked; `granted`; and `denied`, which a
page cannot ask about again: only the person can change it, in the browser's settings for the site.

## Seeing both answers

`tools/notify.ts` opens a page and has its worker show a notification, once as a visitor who was never asked,
and once as one who allowed it, which Playwright can grant in advance. Save it in `tools/`:

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

**Without permission the browser refuses, with an error that says so**; with it, the worker reports the
notification as showing. A page that does not check the permission first gets exactly that error, which is why
the call is in a `try`.

## Asking

The question itself is `Notification.requestPermission()`, which shows the browser's dialog and resolves to the
answer. Two rules decide whether it is ever answered yes:

- **Ask after the person did something that makes the question make sense**, such as a click on *Remind me
  before each session*. Firefox and Safari ignore a request that does not come from a click, and Chromium shows a quiet
  version of the question, a small icon in the address bar, to sites whose requests are usually refused.
- **Never ask on arrival.** A page that asks before it has shown anything gets *no* from most people, and a *no*
  is permanent for that site. The planner does not ask at all in this lesson; the section "Asking for attention"
  says when it should.
