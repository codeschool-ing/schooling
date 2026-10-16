import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'tests',
  reporter: 'list',
  use: { baseURL: 'http://localhost:3000' },
  // Playwright starts the shop before the tests and stops it after.
  webServer: {
    command: 'npm start',
    url: 'http://localhost:3000/api/products',
    reuseExistingServer: !process.env.CI,
  },
});
