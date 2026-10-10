---
title: The tab order, captured
version: 1
---

A manual pass is the real test, and it has one weakness: it leaves nothing behind. **A script
that presses Tab and writes down what it reached turns the pass into a transcript**, something
you can attach to a defect report, compare before and after a fix, and run again on every commit.
Playwright can press keys as well as click, and the accessibility tree from lesson 13's DevTools
pane can be read from a script, so the two together describe the tab order the way a keyboard
user meets it.

In `~/a11y`, the project lesson 13 set up, `nano tab.js`:

```schooling-example
{"language": "javascript", "file": "a11y/tab.js", "parts": [{"code": "// a11y/tab.js\n// Presses Tab through a page and prints every element that takes the focus,\n// named as the accessibility tree names it, and whether a focus outline shows.\n// Then tries to book a seat with the keyboard alone, and with the mouse.\nconst { chromium } = require(\"playwright\");\n\nconst url = process.argv[2] || \"http://localhost:8000/book.html\";", "note": "A second program in `~/a11y`, beside `audit.js`, using the same Playwright. It takes the page's address on the command line."}, {"code": "\nasync function focused(page) {\n  const here = page.locator(\":focus\");\n  if (await here.count() === 0) return null;\n  const name = (await here.ariaSnapshot()).split(\"\\n\")[0].replace(/^- /, \"\").replace(/:$/, \"\");\n  const outline = await here.evaluate(el => {\n    const s = getComputedStyle(el);\n    return s.outlineStyle !== \"none\" && parseFloat(s.outlineWidth) > 0;\n  });\n  return { name, outline };\n}", "note": "`focused` answers which element has the focus right now, named the way a screen reader would hear it: `:focus` finds the element, and the first line of its `ariaSnapshot()` is its role and its accessible name. It also asks the browser whether an outline is drawn. **That is an indicator, not a proof**: a page may show focus with a background or a shadow, and this check would call that invisible. When it says *no focus outline*, look."}, {"code": "\nasync function result(page) {\n  await page.waitForFunction(() => document.getElementById(\"result\").textContent, null,\n                             { timeout: 2000 }).catch(() => {});\n  return (await page.textContent(\"#result\")) || \"(nothing happened)\";\n}", "note": "`result` waits up to two seconds for the booking's answer to appear on the page."}, {"code": "\n(async () => {\n  const browser = await chromium.launch();\n  const page = await browser.newPage();\n  await page.goto(url);\n  await page.waitForLoadState(\"networkidle\");\n\n  console.log(\"Tab order:\");\n  for (let n = 1; n <= 12; n++) {\n    await page.keyboard.press(\"Tab\");\n    const now = await focused(page);\n    if (!now) { console.log(`  ${n}. (focus left the page)`); break; }\n    console.log(`  ${n}. ${now.name}${now.outline ? \"\" : \"   <- no focus outline\"}`);\n  }", "note": "**The tab walk.** Press Tab, print what has the focus, up to twelve times, until the focus leaves the page for the browser's own controls. The list it prints is the tab order, the sequence a keyboard user meets."}, {"code": "\n  await page.reload();\n  await page.waitForLoadState(\"networkidle\");\n  await page.keyboard.press(\"Tab\");\n  if (/^link \"Skip/.test((await focused(page))?.name || \"\")) {\n    await page.keyboard.press(\"Enter\");\n    await page.keyboard.press(\"Tab\");\n    console.log(`Enter on the skip link, then Tab: ${(await focused(page)).name}`);\n  }", "note": "On a fresh load, one Tab: if the first thing reached is a skip link, press Enter on it, then Tab once more, and print where the focus went. On a page with no skip link this prints nothing."}, {"code": "\n  await page.fill(\"#seat\", \"20\");\n  await page.fill(\"#customer\", \"ana\");\n  let reached = false;\n  for (let n = 0; n < 6 && !reached; n++) {\n    await page.keyboard.press(\"Tab\");\n    reached = /\"Book\"/.test((await focused(page))?.name || \"\");\n  }\n  if (reached) {\n    await page.keyboard.press(\"Enter\");\n    console.log(`Keyboard, Enter on Book: ${await result(page)}`);\n  } else {\n    console.log(\"Keyboard: Tab from the name field never reaches Book\");\n  }", "note": "**The keyboard booking.** Type a seat and a name, then press Tab until the focus reaches something named Book, at most six times. If it does, press Enter, the way a keyboard user would, and print what the page answered."}, {"code": "\n  await page.fill(\"#seat\", \"21\");\n  await page.$eval(\"#result\", el => { el.textContent = \"\"; });\n  await page.getByText(\"Book\", { exact: true }).click();\n  console.log(`Mouse, click on Book: ${await result(page)}`);\n  await browser.close();\n})();", "note": "**The mouse booking**, the way a functional test does it: a click on the text Book, seat 21. The two lines side by side are the lesson's point."}]}
```

Run it against `book2.html`, the page that passed every automated audit in lesson 13. Run
`python3 seed.py` in `~/boxoffice` first if you want the same booking numbers as here.

```
ana@nft:~/a11y$ node tab.js http://localhost:8000/book2.html
Tab order:
  1. textbox "Your name"   <- no focus outline
  2. link "What's on"   <- no focus outline
  3. link "Prices"   <- no focus outline
  4. link "Access"   <- no focus outline
  5. combobox "Show"   <- no focus outline
  6. spinbutton "Seat": "1"   <- no focus outline
  7. (focus left the page)
Keyboard: Tab from the name field never reaches Book
Mouse, click on Book: Booked: seat 21, booking 295113.
```

## Reading it

**The first stop is the name field**, at the bottom of the form, before the site's navigation and
before the two fields above it. That is `tabindex="1"`, doing exactly what the previous section
said: one positive value moves its element in front of the whole page. A sighted keyboard user
sees the focus jump down, then back up to the links; a screen reader user arrives at the name field
before knowing which show they are booking.

**Book is not in the list at all.** After the seat field the focus leaves the page. The `<div>`
cannot take the focus, so it cannot be reached, so Enter and Space never get the chance to fail.
The keyboard line says it plainly, and the line under it is the mouse booking the same seat with
no trouble. That pair of lines is the defect report: one task, two ways of doing it, one of them
impossible.

**Every stop says *no focus outline*.** `*:focus { outline: none; }` still applies, and nothing
else on the page draws the focus another way. A sighted keyboard user pressing Tab on this page
sees nothing move.

## Turning it into a test

A transcript a person reads is the first step. The second is an assertion a pipeline can fail on,
and `tab.js` already holds the pieces: the list of names in order, and whether Book was reached.
Written as a test, in the Playwright Test runner `web-automation` used, it would assert three
things about the booking page:

- the tab order equals the list you expect, in reading order;
- every stop on it has a visible indicator;
- the booking can be completed with Tab and Enter alone.

The first is the most valuable and the most fragile: it fails on every new link in the header,
which is right, because somebody should look at the order whenever it changes. Keep the expected
list in the test, next to a comment saying who agreed it.
