---
title: Lazy loading, a file per page
version: 1
---

**A route whose component is written as `() => import('./views/CourseView.vue')` is loaded lazily: its
code is not part of the first file the browser downloads, and is fetched the first time somebody opens
that page.** The week is what everybody sees first, so it is imported normally; a course's page is
loaded when a course is opened.

The dev server shows it. This is the parameters section's click again, with the network list, and
`CourseView.vue` and `CourseWeek.vue` arrive *after* the click, not with the rest of the page:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text - --network
net  GET /  200
net  GET /src/main.js  200
net  GET /@vite/client  200
net  GET /src/router.js  200
net  GET /node_modules/.vite/deps/vue.js?v=f3072b2a  200
net  GET /src/App.vue  200
net  GET /src/main.css  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /src/keys.js  200
net  GET /src/views/NotFound.vue  200
net  GET /src/views/HomeView.vue  200
[vite] connected.
net  GET /src/planner.js  200
net  GET /src/composables/usePlannerData.js  200
net  GET /src/composables/useToday.js  200
net  GET /src/components/AppFooter.vue  200
net  GET /node_modules/.vite/deps/vue-router.js?v=00952696  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/components/CourseCard.vue  200
net  GET /src/components/SessionRow.vue  200
net  GET /src/components/PlannerPanel.vue  200
net  GET /node_modules/.vite/deps/vue.runtime.esm-bundler-CWNVreLk.js?v=6664c211  200
net  GET /src/components/SessionRow.vue?vue&type=style&index=0&scoped=b7ae2f26&lang.css  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /src/components/CourseCard.vue?vue&type=style&index=0&scoped=a191423e&lang.css  200
net  GET /src/components/PlannerPanel.vue?vue&type=style&index=0&scoped=0710be83&lang.css  200
net  GET /courses.json  200
-- click text=Spanish >> nth=0
net  GET /courses.json  200
net  GET /src/views/CourseView.vue  200
net  GET /src/views/CourseWeek.vue  200
net  GET /src/views/CourseView.vue?vue&type=style&index=0&scoped=62175599&lang.css  200
```

(The list is long because in development Vite serves every module as a file of its own; the lines to
find are the last ones, after `-- click`.)

## In the build

The difference matters in production, where Vite bundles the application into a few files. Build it:

```
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 43 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                       0.43 kB │ gzip:  0.29 kB
dist/assets/CourseView-DCK-DYkd.css   0.06 kB │ gzip:  0.08 kB
dist/assets/index-CiPQPnxa.css        0.78 kB │ gzip:  0.43 kB
dist/assets/CourseAll-DFaCYQ3J.js     0.50 kB │ gzip:  0.35 kB
dist/assets/CourseWeek-Cbc2IZvv.js    0.57 kB │ gzip:  0.39 kB
dist/assets/CourseView-CT3GQE2y.js    0.82 kB │ gzip:  0.51 kB
dist/assets/index-DZAU1O19.js        95.24 kB │ gzip: 37.07 kB

✓ built in 377ms
```

**Each lazily imported view became a file of its own**, `CourseView-….js`, `CourseWeek-….js` and
`CourseAll-….js`, beside the main `index-….js`. A student who never opens a course never downloads
them. The characters after the dash are a hash of each file's contents, so a file that has not changed
keeps its name between builds and stays in the browser's cache; lesson 17 is about the build, and
explains the rest of this output.

## What to make lazy

Lazy loading costs a request at the moment the page is opened, so it is a trade:

- **Load lazily** the pages that not everybody visits, and the heavy ones: a settings page, an admin
  area, a page with a chart library.
- **Load eagerly** the page everybody lands on, and anything small. A lazy 2 kB page costs a request
  that takes longer than the 2 kB would have.

The planner's views are all small, and splitting them is for showing the mechanism. The not-found page
is imported eagerly on purpose: it is what is shown when something is already wrong, and that is not
the moment to depend on one more request succeeding.
