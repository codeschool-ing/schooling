---
title: A new version
version: 1
---

**A service worker is updated the way it was installed, and it waits.** This is the part of service workers
that surprises everybody once, so it is worth walking through before it happens.

1. **The browser checks.** On every navigation to a page in its scope, and at least once a day, the browser
   fetches `/sw.js` again, past the HTTP cache. If one byte differs, it is a new version.
2. **The new version installs** beside the old one, running its own `install`: with `CACHE` changed to
   `planner-v2`, opening that cache and fetching the offline page into it.
3. **It waits.** The old version still controls every open tab of the site, and the new one does not take
   over while any of them is open. A visitor who keeps a tab open for a week runs the old worker for a week.
4. **It activates** when the last of those tabs closes, and its `activate` deletes `planner-v1`. The next
   page opened is controlled by the new version.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two versions of the worker along time. Version 1 controls the open tabs. Version 2 is found, installs, and then waits while any tab controlled by version 1 is open. When the last one closes, version 2 activates, deletes version 1&#x27;s cache, and controls the pages opened after.\"><text x=\"108\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">version 1</text><rect x=\"120\" y=\"50\" width=\"380\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">controls the open tabs</text><text x=\"108\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">version 2</text><rect x=\"240\" y=\"100\" width=\"80\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">install</text><rect x=\"320\" y=\"100\" width=\"300\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waiting</text><rect x=\"620\" y=\"100\" width=\"90\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"665.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">activate</text><line x1=\"240\" y1=\"40\" x2=\"240\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"240\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">/sw.js differs</text><line x1=\"620\" y1=\"40\" x2=\"620\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"620\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the last tab closes</text><text x=\"665\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner-v1 deleted</text></svg>", "caption": "A new worker waits for the old one's pages to go."}
```

## Why it waits

**Two versions must never serve the same page at once.** A page loaded through the old worker expects the
files the old worker keeps; if the new one took over halfway, its next request could get a file from a
different build, which is lesson 8's hashed chunks mixed across deploys. Waiting is the safe default.

`self.skipWaiting()` in `install` skips the wait, and `clients.claim()` in `activate` takes over the open
pages at once. Both are right for a worker whose caches cannot disagree with the pages already open, and
risky for one that can; a common middle way is for the page to show *a new version is ready*, and call
`skipWaiting` on the worker when the person agrees, reloading the page after it.

## What this means for the planner

**Changing the worker means changing `CACHE`.** The file has to differ by at least a byte to be seen as new,
and a new cache name is what makes the new version start clean while `activate` clears the old one. Changing a
page or a script does not need a new worker: pages are network first, and a new build's scripts have new names.
