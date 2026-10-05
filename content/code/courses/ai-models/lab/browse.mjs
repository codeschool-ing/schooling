#!/usr/bin/env node
// browse: open a page in a headless Chromium, press its button, and say what
// happened. It stands in for ana opening the page and clicking, so a lesson
// can show what a browser did: what the page printed, what it fetched and from
// where, and what it answered.
//
//   browse URL            open, wait for #go to be enabled, click it, print #out
//   browse URL --wait N   give up after N seconds (default 60)
import { chromium } from "playwright";

const [url, , wait = "60"] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const fetched = [];
page.on("console", m => console.log(`console  ${m.text()}`));
page.on("pageerror", e => console.log(`error    ${e.message}`));
page.on("response", async r => {
  // a body the browser compiled as it streamed (the .wasm) is not kept, so
  // its size is the one the server declared
  const length = (await r.allHeaders())["content-length"];
  const body = await r.body().catch(() => null);
  fetched.push([r.status(), body?.length || Number(length ?? 0), new URL(r.url())]);
});
await page.goto(url);
try {
  await page.waitForSelector("#go:not([disabled])", { timeout: Number(wait) * 1000 });
  await page.click("#go");
  await page.waitForFunction(() => document.getElementById("out").textContent !== "ready");
  console.log(`page     ${await page.textContent("#out")}`);
} catch {
  console.log(`page     ${await page.textContent("#out")} (no answer after ${wait} s)`);
}
await browser.close();
for (const [status, bytes, u] of fetched) {
  console.log(`fetched  ${status} ${String(bytes).padStart(9)}  ${u.host}${u.pathname}`);
}
const hosts = new Set(fetched.map(([, , u]) => u.host));
console.log(`${fetched.length} requests, to ${hosts.size} host${hosts.size === 1 ? "" : "s"}: ${[...hosts].join(" ")}`);
