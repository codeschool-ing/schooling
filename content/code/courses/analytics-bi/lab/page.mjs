// What a reader of the Streamlit app sees, read by a headless browser.
//   node page.mjs metric-both | metric-office | load
import pw from '../../../../../node_modules/playwright/index.js';
const { chromium } = pw;
const mode = process.argv[2];
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const p = await (await b.newContext({ viewport: { width: 1000, height: 900 } })).newPage();
await p.goto('http://localhost:8501');
if (mode.startsWith('metric')) {
  await p.waitForSelector('[data-testid="stMetricValue"]', { timeout: 30000 });
  if (mode === 'metric-office') {
    await p.locator('.react-aria-ComboBox button[aria-label="Remove home"]').click();
    await p.waitForTimeout(4000);
  }
  const label = await p.innerText('[data-testid="stMetricLabel"]');
  const value = await p.innerText('[data-testid="stMetricValue"]');
  const tags = await p.$$eval('.react-aria-ComboBox [data-tag] span[title]', xs => xs.map(x => x.innerText.trim()));
  console.log(`Segment: ${tags.join(', ')}`);
  console.log(`${label.trim()}: ${value.trim()}`);
} else {
  // load the page once, so the app runs and writes what went wrong to its terminal
  await p.waitForTimeout(8000);
}
await b.close();
