---
title: Quarantine
version: 1
---

Save it as `quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// QUARANTINED: lesson 3's search defect, at a speed where it shows only some
// of the time. The test is right and the page is wrong. It goes back into
// tests/ when search.js drops answers to questions the box no longer asks.
test('typed at 145 ms a key, the list settles on papaya', {
  tag: '@quarantine',
  annotation: {
    type: 'quarantine',
    description: 'owner: ana; review by 2026-11-10; reported as the search defect',
  },
}, async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```
