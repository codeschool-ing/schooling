---
title: Diagnosis
version: 1
---

Save it as `quarantine.config.js`:

```javascript
// The quarantine: tests known to be flaky, run apart from the gate.
// Everything else comes from the project's own configuration.
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

export default defineConfig({
  ...base,
  testDir: 'quarantine',
});
```

Save it as `quarantine/typing.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Lesson 3's search, typed just under the speed at which its defect stops
// showing. Whether it shows is decided by a few milliseconds.
test('typed at 145 ms a key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya', { delay: 145 });
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```
