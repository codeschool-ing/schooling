// boxes.mjs: open a page at a phone's size and print where every element
// with a testID was laid out, and its background colour.
//
//   node boxes.mjs URL [WIDTH HEIGHT] [--dark]
import { chromium } from "playwright";

const args = process.argv.slice(2);
const dark = args.includes("--dark");
const [url, width = "390", height = "844"] = args.filter((a) => a !== "--dark");
const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: Number(width), height: Number(height) },
  colorScheme: dark ? "dark" : "light",
});
await page.goto(url);
await page.waitForLoadState("networkidle");
for (const el of await page.locator("[data-testid]").all()) {
  const id = await el.getAttribute("data-testid");
  const b = await el.boundingBox();
  const bg = await el.evaluate((e) => getComputedStyle(e).backgroundColor);
  const box = [b.x, b.y, b.width, b.height].map((n) => Math.round(n));
  console.log(`${id.padEnd(12)} x=${box[0]} y=${box[1]} w=${box[2]} h=${box[3]}  ${bg}`);
}
await browser.close();
