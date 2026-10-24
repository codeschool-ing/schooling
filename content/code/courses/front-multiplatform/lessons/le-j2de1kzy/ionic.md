---
title: Ionic, phone controls for the web
version: 1
---

**Ionic is a library of components that look and behave like a phone's**: lists with the platform's
spacing, toolbars, tabs, modal sheets that slide up, and the iOS or the Android look chosen by the
platform the app runs on. They are web components, so they work in a plain page and inside Angular, React and Vue alike. In a Capacitor app they are the usual way to make the WebView look like an app
rather than a page, which is half of lesson 6's checklist.

A small page shows them. It is a second Vite project beside the planner, so the planner stays as it is:

```
ana@dev:~$ npm create vite@9.3.1 planner-ionic -- --template vanilla-ts --no-interactive > /dev/null
ana@dev:~$ cd planner-ionic
ana@dev:~/planner-ionic$ rm -r src public && mkdir src
ana@dev:~/planner-ionic$ npm install -E -D vite@8.3.5 typescript@6.0.3 > /dev/null
ana@dev:~/planner-ionic$ npm install -E @ionic/core@9.0.9

added 7 packages, and audited 24 packages in 3s

found 0 vulnerabilities
ana@dev:~/planner-ionic$ cp ../planner/src/planner.ts ../planner/public/courses.json src/
```

The page, `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner, with Ionic</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

and its script, which draws the planner's courses and the week with Ionic's elements, from the same
`planner.ts` and `courses.json`:

```typescript
// src/main.ts: the planner's list of courses, drawn with Ionic's components.
import { defineCustomElements } from "@ionic/core/loader";
import "@ionic/core/css/ionic.bundle.css";
import { mondayOf, weekTotal, type Plan } from "./planner";
import data from "./courses.json";

defineCustomElements();
const plan: Plan = data;
const today = new URLSearchParams(location.search).get("today") ?? new Date().toISOString().slice(0, 10);
const total = weekTotal(plan, mondayOf(today));

document.querySelector("#app")!.innerHTML = `
<ion-app>
  <ion-header><ion-toolbar><ion-title>Study planner</ion-title></ion-toolbar></ion-header>
  <ion-content>
    <ion-list>
      <ion-list-header>This week: ${total.done} of ${total.planned} minutes done</ion-list-header>
      ${plan.courses.map((c) => `<ion-item button detail>${c.name}</ion-item>`).join("")}
    </ion-list>
  </ion-content>
</ion-app>`;
```

```
ana@dev:~/planner-ionic$ npm run build | tail -n 7
dist/assets/ion-textarea.entry-cJZu5Eto.js                 46.89 kB │ gzip:  6.76 kB
dist/assets/ion-select_3.entry-BpSFIhwz.js                 55.20 kB │ gzip: 10.98 kB
dist/assets/ion-item_8.entry-DjDaxm16.js                   57.04 kB │ gzip:  9.10 kB
dist/assets/ion-datetime.entry-Tm1Iz27X.js                 57.53 kB │ gzip: 13.18 kB
dist/assets/index-DQslBGJ4.js                              85.22 kB │ gzip: 26.91 kB

✓ built in 473ms
```

The build is larger than the planner's, because each Ionic component is a module of its own, loaded the
first time the page uses it. Opened in Chromium:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:4175/?today=2026-10-21' --wait 1500
- banner: Study planner
- main:
  - list:
    - text: "This week: 75 of 125 minutes done"
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
```

**The same week, 75 of 125, and the same three courses**, now as Ionic list items, each a button, under
a toolbar that the tree calls a banner. Nothing native happened here: this is a web page with phone-like
components, and Capacitor would wrap it exactly as it wrapped the planner in lesson 2.
