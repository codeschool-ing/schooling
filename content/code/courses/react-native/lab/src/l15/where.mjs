// where.mjs: on This week, turn on "Note where I study", mark a session done, and print what the screen
// says. The browser is given a position, as a phone's GPS would give one, unless --deny is passed.
//
//   node where.mjs URL BUTTON [--deny]
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext(
  flag === "--deny" ? {} : { permissions: ["geolocation"], geolocation: { latitude: -23.561414, longitude: -46.655881 } },
);
const page = await context.newPage();
await page.goto(url);
const toggle = page.getByRole("switch", { name: "Note where I study" });
await toggle.click();
await page.waitForTimeout(1000);
console.log("switch on:", await toggle.isChecked());
const alert = page.getByRole("alert");
if (await alert.count()) console.log("alert:", await alert.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
for (const line of await page.getByText(/^Logged on this phone: |^Studied at /).allInnerTexts()) console.log(line);
await browser.close();
