---
title: Splitting by route
version: 1
---

**A route is the natural place to cut the code**, which lesson 13 promised: each screen is a piece
that some visits never need. The course route already does it, with the `lazy` property in `main.tsx`:

```tsx
lazy: async () => ({ Component: (await import('./CourseScreen')).CourseScreen }),
```

`lazy` is called the first time the route is needed, and returns the parts of the route that were left
out of the list: here, its `Component`. It is the same dynamic `import()` as lesson 13's, but **the
router calls it**, and draws the screen once the code and the loader's data are both there. There is no
`Suspense` to place: until then, the router keeps the old screen up.

Build, and open a course from the preview server:

```
ana@dev:~/planner$ npm run build | grep -E "assets|built"
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-Cl8g1eB6.js  111.69 kB │ gzip:  34.90 kB
dist/assets/index-BcPNGV8E.js         356.60 kB │ gzip: 112.00 kB
✓ built in 510ms
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network --do 'click link Organic chemistry' | grep -E 'assets|api|^-- |heading'
net  GET /assets/index-ims8OhNo.css  200
net  GET /assets/index-BcPNGV8E.js  200
net  GET /api/planner  200
-- click link Organic chemistry
net  GET /assets/CourseScreen-Cl8g1eB6.js  200
  - heading "Organic chemistry" [level=1]
```

**`CourseScreen-BH827cGS.js` is fetched on the click and not before**, as in lesson 13, now without the
`lazy`, the `Suspense` and the preload effect that `App` used to carry. The main file grew from lesson
13's 262 kB to 357 kB: most of that is React Router itself, which every screen needs.

The loader, by contrast, is in the main file, imported by `main.tsx`. It is a few lines, so it costs
almost nothing there. A route can lazy-load its loader too, from the same `lazy` function, when the
loader is large.
