---
title: One behaviour, three layers
version: 1
---

Save it as `unit/total.test.js`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { total } from '../app/store.js';

test('an empty basket costs nothing', () => {
  assert.equal(total([]), 0);
});

test('one banana costs 590 cents', () => {
  assert.equal(total([{ id: 'banana', qty: 1 }]), 590);
});

test('quantities multiply and lines add up', () => {
  // three bananas and two guavas: 3 * 590 + 2 * 1290
  assert.equal(total([{ id: 'banana', qty: 3 }, { id: 'guava', qty: 2 }]), 4350);
});
```

Save it as `tests/basket-api.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Only the request fixture: HTTP to the shop, and no browser.
test('a banana in the basket costs 590 cents', async ({ request }) => {
  await request.post('/api/reset');
  const response = await request.post('/api/basket', { data: { id: 'banana' } });
  expect(response.status()).toBe(200);
  expect(await response.json()).toEqual({ lines: [{ id: 'banana', qty: 1 }], total: 590 });
});
```

Save it as `tests/basket-ui.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a banana in the basket shows R$ 5,90', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await expect(page.locator('.basket-total')).toHaveText('R$ 5,90');
});
```
