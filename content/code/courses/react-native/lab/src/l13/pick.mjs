// pick.mjs: press a button that opens a file chooser, hand it a file as a person would, and
// describe the photo the screen shows afterwards.
//
//   node pick.mjs URL BUTTON FILE
import { chromium } from "playwright";

const [url, button, file] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url);
await page.waitForLoadState("networkidle");
const opened = page.waitForEvent("filechooser");
await page.getByRole("button", { name: button }).click();
const chooser = await opened;
const capture = await chooser.element().getAttribute("capture");
console.log("file chooser:", capture ? `capture="${capture}"` : "no capture attribute");
await chooser.setFiles(file);
// the <img> react-native-web draws, found by its address rather than by its name
const photo = page.locator('img[src^="blob:"]');
await photo.waitFor();
const [alt, w, h] = await photo.evaluate((img) => [img.alt, img.naturalWidth, img.naturalHeight]);
console.log(`photo: ${w}×${h}, alt="${alt}"`);
await browser.close();
