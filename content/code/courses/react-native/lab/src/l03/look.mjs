// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--file LABEL=PATH] [--wait MS] ...
//
// The options run in order, after the page has loaded. --click presses the
// control whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, --file picks PATH in the file chooser that pressing LABEL opens, and
// --wait lets timers run. Then it prints the accessibility tree of the page,
// and every console message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
for (let i = 0; i < args.length; i += 2) {
  if (args[i] === "--grant") await context.grantPermissions([args[i + 1]], { origin: new URL(url).origin });
  if (args[i] === "--geo") {
    const [latitude, longitude] = args[i + 1].split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  }
}
await page.goto(url);
await page.waitForLoadState("networkidle");
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--file") {
    const [label, path] = value.split("=");
    const chooser = page.waitForEvent("filechooser");
    await page.getByRole("button", { name: label, exact: true }).click();
    await (await chooser).setFiles(path);
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else if (flag !== "--grant" && flag !== "--geo") throw new Error(`look: unknown option ${flag}`);
}
await page.waitForTimeout(300);
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
