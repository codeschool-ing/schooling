---
title: Once it is installed
version: 1
---

**An installed planner is the same planner in a different frame.** Every lesson before this one still holds,
and a few things change.

- **The window** is the manifest's: no address bar with `standalone`, the theme colour in the title bar, the
  name and the icon in the system's list of windows. A link to an address outside `scope` opens in the browser
  rather than inside the app.
- **The start** is `start_url`, whatever page the person installed it from. The planner's is `/`, so the app
  always opens on the list of courses.
- **The page can tell.** The CSS media query `(display-mode: standalone)`, and the same in
  `matchMedia` from a script, is true inside the installed app, which is how a page hides its install button,
  or a link that only makes sense in a browser, once it is installed.
- **Updates are the service worker's.** There is no app store and no version to download: the next time the app
  opens, the browser checks `/sw.js` as lesson 10 described, and the new pages come from the server as they
  always did. The manifest itself is checked from time to time too, and a changed icon or name reaches the
  installed app, in Chromium after a delay and sometimes with a question to the person.

## Storage that stays

**A browser may clear a site's storage when the disk runs short**, the service worker's caches included, and an
installed app is one a person has said they want to keep. `navigator.storage.persist()` asks for the site's
storage to be kept unless the person clears it themselves; Chromium grants it more readily to installed apps,
and `navigator.storage.estimate()` says how much the site uses and may use. The planner keeps nothing it could
not fetch again, so it does not ask; an app that keeps a person's own work offline should.

## Uninstalling

From the app's own menu, or from the system's list of applications, as any other. **What goes with it is the
window and the icon, not the data**: the site's storage belongs to the site, in the browser, and stays until the
person clears it there.
