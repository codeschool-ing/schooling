// frames.mjs: open the Courses tab, go to This week, press a button, come back, and print the
// week bar's drawn width every 50 ms for the next half second.
//
//   node frames.mjs URL BUTTON [--reduced]
//
// --reduced asks the browser for reduced motion, as the phone's accessibility setting would.
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ reducedMotion: flag === "--reduced" ? "reduce" : "no-preference" });
await page.goto(url);
await page.waitForLoadState("networkidle");
await page.getByRole("tab", { name: "This week" }).click(); // Courses stays mounted behind it
const press = await page.getByRole("button", { name: button, exact: true }).elementHandle();
const tab = await page.getByRole("tab", { name: "Courses" }).elementHandle();
// Pressed and measured inside the page, in one go, so the times are the page's own and not
// the program's round trips to the browser.
const widths = await page.evaluate(
  ([press, tab]) =>
    new Promise((done) => {
      press.click();
      tab.click();
      const seen = [];
      const look = () => {
        const bar = document.querySelector('[data-testid="week-done"]');
        seen.push(Math.round(bar.getBoundingClientRect().width));
        if (seen.length < 11) setTimeout(look, 50);
        else done(seen);
      };
      look();
    }),
  [press, tab],
);
console.log("width every 50 ms:", widths.join(" "));
await browser.close();
