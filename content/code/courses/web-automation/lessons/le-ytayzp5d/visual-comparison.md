---
title: Comparing screenshots
version: 1
---

TBD Save it as `evidence/visual.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails once, on purpose: the first run has no picture to compare with,
// so it writes one and fails. Every run after compares against it.
test('the shop looks as it did', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page).toHaveScreenshot('shop.png');
});
```

```
%%CAP visual-first%%
```

```
%%CAP visual-second%%
```

```
%%CAP visual-changed%%
```
