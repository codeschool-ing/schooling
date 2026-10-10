---
title: Attaching what the browser said
version: 1
---

TBD Save it as `evidence/errors.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

let messages = [];

// Before each test: listen to the page, as look.mjs did in lesson 1.
test.beforeEach(async ({ page }) => {
  messages = [];
  page.on('console', (m) => messages.push(`console.${m.type()}: ${m.text()}`));
  page.on('pageerror', (e) => messages.push(`pageerror: ${e.message}`));
});

// After each test, passed or failed: put what was heard into the report.
test.afterEach(async ({}, testInfo) => {
  await testInfo.attach('browser messages', {
    body: messages.join('\n') || '(none)',
    contentType: 'text/plain',
  });
});

// Fails on purpose: the product list is answered with a 404, as if the
// server had broken, and the page's script throws reading it.
test('the shop lists eight products', async ({ page }) => {
  await page.route('**/api/products', (route) => route.fulfill({ status: 404, body: 'not found' }));
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
});
```

```
%%CAP errors-run%%
```

```
%%CAP errors-trace%%
```
