// big.mjs: make a picture the size of a camera's photo, 4000 by 3000 pixels, to pick as one.
//
//   node big.mjs FILE
import { chromium } from "playwright";

const [file] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 4000, height: 3000 } });
await page.setContent('<body style="margin:0;height:100vh;background:linear-gradient(135deg,#1d6f42,#e8c547)">');
await page.screenshot({ path: file });
await browser.close();
