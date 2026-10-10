---
title: Why your tests never meet it
version: 1
---

FRESH_PROSE_1

Save it as `tests/cache.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a new offer reaches the page', async ({ page, request }) => {
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
%%CAP cache-v1%%
```

FRESH_PROSE_2

```javascript
test('a returning customer sees the new offer', async ({ page, request }) => {
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
%%CAP cache-v2%%
```

FRESH_PROSE_3 Save it as `visitors.mjs`:

```javascript
// The offer changes once; five visitors come back, and each says what it
// was shown.
import { chromium } from '@playwright/test';
import { rm } from 'node:fs/promises';

const shop = 'http://localhost:3000';
const post = (path, body) => fetch(shop + path, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});
async function visit(who, page) {
  await page.goto(shop + '/offer.html');
  const text = await page.locator('#offer', { hasNotText: '…' }).textContent();
  console.log(who.padEnd(28), text);
}

await post('/api/reset', {});
await rm('profile', { recursive: true, force: true });
const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();
await visit('before the change', page);
let kept = await chromium.launchPersistentContext('profile');
await visit('before, in a kept profile', await kept.newPage());
await kept.close();

await post('/api/offer', { id: 'banana', price: 290 });

await visit('the same page', page);
await visit('a new page, same context', await context.newPage());
const saved = await browser.newContext({ storageState: await context.storageState() });
await visit('a new context, saved state', await saved.newPage());
await visit('a new context', await (await browser.newContext()).newPage());
kept = await chromium.launchPersistentContext('profile');
await visit('the kept profile, reopened', await kept.newPage());

await kept.close();
await browser.close();
```

```
%%CAP visitors%%
```

FRESH_PROSE_4
