// journal.mjs: on This week, read what the journal says, mark one session done, read it again, then
// reload the page and read it a third time; last, read it in a browser that has never been here.
//
//   node journal.mjs URL BUTTON
import { chromium } from "playwright";

const [url, button] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = page.getByText(/logged on this phone/i);
await page.goto(url);
console.log("before:      ", await logged.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
console.log("after:       ", await logged.innerText());
await page.reload();
console.log("after reload:", await logged.innerText());
await page.close();
const other = await (await browser.newContext()).newPage();
await other.goto(url);
console.log("new browser: ", await other.getByText(/logged on this phone/i).innerText());
await browser.close();
