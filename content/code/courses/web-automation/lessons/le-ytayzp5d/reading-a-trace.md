---
title: Reading a trace without the viewer
version: 1
---

TBD

```
%%CAP trace-list%%
```

```
%%CAP trace-actions%%
```

```
%%CAP trace-network%%
```

Save it as `evidence/search.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails on purpose: the search race of lesson 3. The answer to "p"
// arrives last and replaces the list.
test('typed key by key, the list settles on papaya', async ({ page }) => {
  await page.goto('/search.html');
  await page.getByLabel('Fruit').pressSequentially('papaya');
  await expect(page.locator('#results')).toHaveAttribute('aria-busy', 'false');
  await expect(page.locator('#results li')).toHaveText(['Papaya']);
});
```

```
%%CAP search-run%%
```

```
%%CAP search-network%%
```

```
%%CAP search-actions%%
```
