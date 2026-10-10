---
title: Testing the cache on purpose
version: 1
---

TEST_PROSE_1 Save it as `tests/cache.spec.js`:

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

test('a returning customer sees the new offer', async ({ page, request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});

test('the offer is checked with the server before it is reused', async ({ request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  const response = await request.get('/api/offer');
  expect(response.headers()['cache-control']).toMatch(/no-cache|no-store/);
});

test('a static file is reused only when the server agrees', async ({ request }) => {
  const first = await request.get('/style.css');
  expect(first.headers()['cache-control']).toBe('no-cache');
  const etag = first.headers()['etag'];
  expect(etag).toBeTruthy();

  const again = await request.get('/style.css', { headers: { 'If-None-Match': etag } });
  expect(again.status()).toBe(304);
});

// The returning customer again, with routing switched on. It passes, and
// that is the warning: routing turns the browser's cache off.
test('routing hides the flaw', async ({ page, request }) => {
  await page.route('**/*', (route) => route.continue());
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

```
%%CAP cache-final%%
```

```
%%CAP cache-log%%
```

```
%%CAP flaw-fixed%%
```
