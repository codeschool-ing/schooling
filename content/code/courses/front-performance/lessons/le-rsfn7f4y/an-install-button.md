---
title: An install button of the planner's own
version: 1
---

**The browser's own offer to install is easy to miss**: an icon in the address bar, or an entry in a menu.
Chromium lets a page make the offer itself. When a page qualifies, the browser fires **`beforeinstallprompt`**
at it; a page that calls `preventDefault()` keeps the event, and calling its `prompt()` later, from a click,
shows the browser's install dialog then.

In `index.html`, a button for it, hidden until there is something to offer; add it just before `<main id="app">`:

```html
    <button id="install" class="install" hidden>Install the planner</button>
```

It is placed with `position: fixed`, at the end of `src/style.css`, so that appearing late moves nothing on the
page, which is lesson 5's layout shift avoided by design:

```css
.install { position: fixed; right: 1rem; bottom: 1rem; }
```

And at the end of `src/main.ts`:

```typescript

// Chromium offers to install an app by firing beforeinstallprompt. The page keeps the
// event and shows its own button, so the offer comes when the person asks for it.
type InstallOffer = Event & { prompt(): Promise<void> };
let offer: InstallOffer | null = null;
const install = document.getElementById("install")!;
addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault();
  offer = e as InstallOffer;
  install.hidden = false;
});
install.addEventListener("click", async () => {
  install.hidden = true;
  await offer?.prompt();
  offer = null;
});
```

`InstallOffer` is written out because TypeScript's description of the DOM does not include the event: it is a
Chromium feature, not a standard. `prompt()` can be called once per event, so the button hides itself and the
offer is dropped after it.

`tools/installable.ts` already looks for a button with this id, a few seconds after the page loads. Build,
restart, and ask:

```
ana@dev:~/planner$ node tools/installable.ts http://localhost:3000/
manifest: http://localhost:3000/manifest.webmanifest
not installable: no-acceptable-icon (minimum-icon-size-in-pixels=144)
```

**The button is shown**, because the browser fired the event. In a browser that never fires it, Safari and
Firefox, it stays hidden, and the page is exactly what it was. That is the right failure: a page that showed the
button everywhere would offer something it cannot give. For Safari, the honest alternative is a sentence saying
where *Add to Home Screen* is, shown only there.

**The planner does not press the button.** `prompt()` opens a dialog for a person to answer, and a test that
answered it would be testing the browser.
