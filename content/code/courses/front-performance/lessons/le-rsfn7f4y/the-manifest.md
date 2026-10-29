---
title: The manifest
version: 1
---

**The manifest is a JSON file that describes the app**, linked from every page. Save it as
`public/manifest.webmanifest`:

```json
{
  "id": "/",
  "name": "Study planner",
  "short_name": "Planner",
  "description": "Plan your study sessions, course by course, week by week.",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#1d4ed8",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

| member | what it decides |
|---|---|
| `id` | the app's identity: two manifests with the same `id` are the same app, whatever else changes |
| `name`, `short_name` | the name in the list of applications, and under the icon where space is short |
| `start_url` | the page the app opens at |
| `scope` | the addresses that belong to the app; a link outside it opens in the browser |
| `display` | `standalone` is a window of its own without the browser's toolbar; `browser` is an ordinary tab |
| `background_color` | the colour of the window before the first paint, while the page loads |
| `theme_color` | the colour of the window's title bar, and of the status bar on Android |
| `icons` | the pictures the system draws the app with, which the next section makes |

In `index.html`, two lines just before the `<title>` link the manifest and repeat the theme colour for
browsers that read it from the page:

```html
    <link rel="manifest" href="/manifest.webmanifest" />
    <meta name="theme-color" content="#1d4ed8" />
```

And `server.ts` learns one more type, the manifest's own. In its table of types, replace the last line of
entries with:

```typescript
  ".png": "image/png", ".woff2": "font/woff2", ".webmanifest": "application/manifest+json",
```

## Asking the browser

**Chromium can say whether a page is installable, and if not, why**, through the developer tools' protocol:
the same check it makes before it offers to install. `tools/installable.ts` asks it. Save it in `tools/`:

```typescript
// tools/installable.ts: ask Chromium whether a page could be installed as an app, and if
// not, why not: the same check the browser makes before it offers to install one.
//
//   node tools/installable.ts URL
import { chromium } from "playwright";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Two things this check needs that a test browser does not have by default: the full browser,
// not the headless shell Playwright uses, which has no installer to ask; and a profile on disk,
// because nothing can be installed into a private window, which every fresh context is.
const profile = await mkdtemp(join(tmpdir(), "installable-"));
const context = await chromium.launchPersistentContext(profile, { channel: "chromium" });
const page = await context.newPage();
await page.goto(process.argv[2], { waitUntil: "networkidle" });
const cdp = await context.newCDPSession(page);
const manifest = await cdp.send("Page.getAppManifest");
console.log(`manifest: ${manifest.url || "none"}`);
const { installabilityErrors } = await cdp.send("Page.getInstallabilityErrors");
if (installabilityErrors.length === 0) console.log("installable");
for (const e of installabilityErrors) {
  const args = e.errorArguments.map((a) => `${a.name}=${a.value}`).join(", ");
  console.log(`not installable: ${e.errorId}${args ? ` (${args})` : ""}`);
}
// A page that offers its own install button, as the planner does, shows it once Chromium has
// fired beforeinstallprompt, which it does a moment after the page qualifies.
await page.waitForTimeout(3000);
if (await page.$("#install")) console.log(`install button: ${(await page.isVisible("#install")) ? "shown" : "hidden"}`);
await context.close();
await rm(profile, { recursive: true });
```

Its comment names the two things a test browser lacks. Build, restart `server.ts`, and ask:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**The manifest is found, and the answer is no: there is no acceptable icon.** The manifest names three icons,
and none of the files exists yet; Chromium wants at least one of 144 pixels or more that it can actually load.
The next section draws them.
