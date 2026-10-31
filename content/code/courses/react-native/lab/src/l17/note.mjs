// note.mjs: open the planner in a browser set to a locale, and print what it says about the week.
//
//   node note.mjs URL LOCALE
import { chromium } from "playwright";

const [url, locale] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ locale });
await page.goto(url);
console.log(`${locale}:`, await page.getByText(/^Your phone's calendar/).innerText());
await browser.close();
