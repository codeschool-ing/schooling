import { test, expect } from '@playwright/test';

test('the shop opens and lists its fruit', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Fruit of the season' })).toBeVisible();
  await expect(page.locator('#products li')).toHaveCount(8);
});
