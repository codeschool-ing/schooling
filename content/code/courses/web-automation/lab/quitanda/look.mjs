// What the Network and Console panels show, printed by a browser nobody
// is watching. Run it with the shop started: node look.mjs [address]
import { chromium } from '@playwright/test';

const address = process.argv[2] ?? 'http://localhost:3000/';
const browser = await chromium.launch();
const page = await browser.newPage();
const start = Date.now();
const ms = () => String(Date.now() - start).padStart(5) + ' ms';

page.on('response', (response) => {
  const request = response.request();
  const path = new URL(response.url()).pathname;
  console.log(`${ms()}  ${response.status()} ${request.method()} ${path}  (${request.resourceType()})`);
});
page.on('console', (message) => console.log(`${ms()}  console.${message.type()}: ${message.text()}`));
page.on('pageerror', (error) => console.log(`${ms()}  uncaught error: ${error.message}`));

await page.goto(address);
await page.waitForLoadState('networkidle');
await browser.close();
