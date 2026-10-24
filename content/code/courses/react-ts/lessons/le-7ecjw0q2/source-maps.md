---
title: Source maps
version: 1
---

**A built file is unreadable on purpose.** Lesson 13 met it in a stack trace, where the planner's
components were called `Vt` and `Wt`. A **source map** is the key that reads it back: a file that says,
for each position in the built code, which file, line and name of yours it came from. Browsers' developer
tools and error-reporting services read it and show your code instead of the minified one.

`vite build` writes none by default. `--sourcemap` asks for them:

```
ana@dev:~/planner$ npx vite build --sourcemap | grep -E 'assets|built'
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-jvv40fJe.js  111.87 kB │ gzip:  35.01 kB │ map:   739.71 kB
dist/assets/index-R8L4SX4s.js         356.90 kB │ gzip: 112.12 kB │ map: 1,847.19 kB
✓ built in 636ms
ana@dev:~/planner$ tail -c 60 dist/assets/index-*.js; echo
,f as s,Vo as t};
//# sourceMappingURL=index-R8L4SX4s.js.map
ana@dev:~/planner$ npx vite build --sourcemap hidden > /dev/null && ls dist/assets
CourseScreen-jvv40fJe.js
CourseScreen-jvv40fJe.js.map
index-R8L4SX4s.js
index-R8L4SX4s.js.map
index-ims8OhNo.css
ana@dev:~/planner$ tail -c 60 dist/assets/index-*.js; echo
as c,so as i,c as l,ko as n,ot as o,Ao as r,f as s,Vo as t};
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
CourseScreen-jvv40fJe.js
index-R8L4SX4s.js
index-ims8OhNo.css
```

- **The first build** wrote a `.map` beside each JavaScript file, 1.8 MB for the main one, five times
  the code it describes, because it carries your sources inside it. The last line of the built file
  names it: `//# sourceMappingURL=index-R8L4SX4s.js.map`. Developer tools follow that comment, so
  anybody who opens them on the site can read your code as you wrote it, comments included.
- **`--sourcemap hidden`** wrote the maps and left the comment out. Browsers do not find them, but the
  files exist, to be uploaded to an error-reporting service, which uses them to turn a user's minified
  stack trace into yours. That is the usual choice in production.
- **The plain build** at the end has no maps at all, which is what the planner deploys from now.

To make the choice permanent rather than a flag, it goes in `vite.config.ts` as `build: { sourcemap:
'hidden' }`.
