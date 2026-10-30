// crash.mjs: hand the planner a plan in a shape it does not expect, as a server deployed with a renamed
// field would, and print what the screen says and the first place the stack points at.
//
//   node crash.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = [];
page.on("console", (m) => m.type() === "error" && logged.push(m.text()));
// "sessions" renamed to "items" on the server, and nobody told the app
await page.route("**/plan", (route) =>
  route.fulfill({ json: { courses: [], items: [] }, headers: { "access-control-allow-origin": "*" } }),
);
await page.goto(url);
console.log("screen:", await page.getByText(/^Something went wrong|^The plan could not be loaded/).innerText());
const report = logged.find((t) => t.startsWith("render failed:"));
if (report) {
  console.log("error: ", report.split("\n")[0]);
  console.log("stack: ", report.split("\n").find((l) => l.includes("/_expo/static/js/"))?.trim());
}
await browser.close();
