---
title: What a browser does without a window
version: 1
---

Every test in this course so far has run **headless**: the browser starts, loads the shop and
closes, and no window appears. The word suggests a browser with something cut out of it, and the
usual belief is that the something is most of the work: that headless means fetching the HTML and
reading it, the way `curl` does. **It does not. A headless browser parses the page, runs its
scripts, lays it out and paints it, exactly as a browser with a window does.** What it leaves out
is the screen the paint would have gone to.

You already have the evidence. Lesson 1's smoke test counted eight cards, and the HTML the server
sends has none: a script draws them after the page loads, so only a browser that ran the script
could count them. Lesson 7 measured the basket line overflowing a 360-pixel window by forty
pixels, which only a browser that computed the layout could know. And a screenshot, which lesson
16 uses to diagnose failures, is a copy of pixels that were painted with no screen to show them on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Four steps in a row: the HTML arrives; parse it and run the scripts; style and layout; paint. From paint, one arrow goes up to a window on a screen, which only a headed browser has, and one goes down to memory, where a screenshot reads it. A headless browser does the same four steps.\"><rect x=\"20\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"155\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the HTML arrives</text><rect x=\"190\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"265\" y=\"147\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">parse it,</text><text x=\"265\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run the scripts</text><rect x=\"360\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"435\" y=\"147\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">style and</text><text x=\"435\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">layout</text><rect x=\"530\" y=\"120\" width=\"150\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"605\" y=\"155\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">paint</text><path d=\"M170 150 L188 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M188 150 L179 145 L179 155 Z\" fill=\"var(--phosphor)\"></path><path d=\"M340 150 L358 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M358 150 L349 145 L349 155 Z\" fill=\"var(--phosphor)\"></path><path d=\"M510 150 L528 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M528 150 L519 145 L519 155 Z\" fill=\"var(--phosphor)\"></path><rect x=\"530\" y=\"20\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"5 4\"></rect><text x=\"605\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a window</text><text x=\"605\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">on a screen</text><path d=\"M605 120 L605 79\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M605 79 L600 88 L610 88 Z\" fill=\"var(--phosphor)\"></path><rect x=\"530\" y=\"224\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"605\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">memory</text><text x=\"605\" y=\"266\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a screenshot reads it</text><path d=\"M605 180 L605 221\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M605 221 L610 212 L600 212 Z\" fill=\"var(--phosphor)\"></path><text x=\"20\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">headed: the four steps, and a window</text><text x=\"20\" y=\"260\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">headless: the same four, and memory</text></svg>", "caption": "Headless removes the window and nothing before it: the page is still parsed, run, laid out and painted."}
```

## What is different, then

Three things change when the screen goes, and each one comes back in this lesson.

- **The window's size is invented.** A browser with a screen opens a window that fits it. With no
  screen there is nothing to fit, so the browser picks a size, and the two headless Chromiums pick
  different ones. Playwright hides this behind a fixed viewport, which is why it rarely shows; the
  section on differences that bite is the case where it does.
- **The painting is done in software.** A server has no graphics card as a rule, and a headless
  browser does not ask for one. The machine these transcripts were recorded on has none in any
  mode, so this lesson cannot show you a difference there, and does not invent one.
- **The fonts are the machine's.** The shop's stylesheet asks for `system-ui, sans-serif`, which
  means whatever the computer calls its system font. A laptop and a bare build server answer with
  different families, and text of a different width wraps in different places. That matters to a
  screenshot more than to anything else, and lesson 16 is about screenshots.

## Asking the browser what it is

A short script makes these differences visible. It starts Chromium one of three ways, chosen by
its argument, and asks the page five questions a site's own script could ask. Save it as
`modes.mjs`:

```schooling-example
{"language": "javascript", "file": "modes.mjs", "parts": [{"code": "import { chromium } from '@playwright/test';\n\n// One Chromium build, three ways to start it: node modes.mjs shell|new|headed\nconst ways = {\n  shell: { headless: true },\n  new: { headless: true, channel: 'chromium' },\n  headed: { headless: false },\n};\nconst way = process.argv[2] ?? 'shell';\nconst browser = await chromium.launch(ways[way]);", "note": "The same `launch()` three times with different options. `headless: true` is Playwright's default and is written out so the three read alike; `channel: 'chromium'` is the next section's subject."}, {"code": "\n// A page with no viewport of its own takes the size of the browser's window.\nconst bare = await browser.newPage({ viewport: null });\nconst own = await bare.evaluate(() => `${innerWidth}x${innerHeight}`);\nawait bare.close();", "note": "`viewport: null` turns off Playwright's emulated size, so the page measures the window the browser itself opened. With no screen, that window is whatever size the browser invents."}, {"code": "\n// A page as Playwright's tests get it, with the default viewport.\nconst page = await browser.newPage();\nawait page.goto('http://localhost:3000/deals');", "note": "Every test's `page` is made this way. The deals page from lesson 7 is the one that reads the `User-Agent` header, so it shows what the server thinks this browser is."}, {"code": "console.log(way, browser.version(), await page.evaluate((own) => ({\n  userAgent: navigator.userAgent,\n  webdriver: navigator.webdriver,\n  ownWindow: own,\n  viewport: `${innerWidth}x${innerHeight}`,\n  deals: document.querySelector('p').textContent,\n}), own));\nawait browser.close();", "note": "Five things read inside the page, where a site's own script would read them: the name the browser gives, the flag that says a program is driving it, the two sizes and the paragraph the server chose."}]}
```

Start the shop with `npm start` in one terminal and run the script in another. With no argument,
or with `shell`, it starts Chromium the way Playwright's tests do:

```
ana@laptop:~/quitanda$ node modes.mjs shell
shell 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/141.0.7390.37 Safari/537.36',
  webdriver: true,
  ownWindow: '800x600',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

**The browser says what it is, twice.** `HeadlessChrome` in the user agent is the name a site
reads from every request, and `webdriver: true` is the flag a browser raises when a program is driving
it, and a site's script can read it as easily as this one did. Then the two sizes: the window the
browser invented for itself is 800 by 600, and the page a test gets is 1280 by 720, because
Playwright sets that viewport on every page unless told otherwise. The deals page from lesson 7
read `Mobile` nowhere in the user agent and sent the desktop paragraph.

Now ask for a window on a machine that has no screen:

```
ana@laptop:~/quitanda$ node modes.mjs headed 2>&1 | head -12
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Target page, context or browser has been closed
Browser logs:

╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ Looks like you launched a headed browser without having a XServer running.                     ║
║ Set either 'headless: true' or use 'xvfb-run <your-playwright-app>' before running Playwright. ║
║                                                                                                ║
║ <3 Playwright Team                                                                             ║
```

**The full Chromium tried to open a window, found no display and gave up**, and Playwright's own
box names the two ways out: run headless, or give the browser a screen that is not there. The
second is `xvfb-run`, and the section on headed runs on a server is about it.
