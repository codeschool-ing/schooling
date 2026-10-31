// offline.mjs: open the planner three times and say what each visit shows: once with the server, once
// more in the same browser with the server cut off, and once in a fresh browser with it cut off.
//
//   node offline.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const cutOff = (target) => target.route("http://localhost:8008/**", (route) => route.abort());

async function visit(context, label) {
  const page = await context.newPage();
  await page.goto(url);
  const shown = page.getByText(/^This week: |^The plan could not be loaded/);
  await shown.waitFor();
  console.log(`${label}: ${await shown.innerText()}`);
  return page;
}

const mine = await browser.newContext();
const first = await visit(mine, "with the server");
await first.waitForTimeout(1500); // the persister writes at most once a second
const stored = await first.evaluate(() => localStorage.getItem("planner-cache")?.length ?? 0);
console.log(`stored: ${stored} characters under planner-cache`);
await first.close(); // one tab at a time: SQLite on the web holds its file for the tab that opened it
await cutOff(mine);
await visit(mine, "same browser, server cut off");
const fresh = await browser.newContext();
await cutOff(fresh);
await visit(fresh, "new browser, server cut off");
await browser.close();
