---
title: What it costs
version: 1
---

**Apollo Client is a library of its own, and the browser downloads all of it before the planner can ask
anything.** The planner without it was a few kilobytes of JavaScript. Measure both builds, the static one
and one made with the variable set, as a deploy that has a server would make it:

```
ana@dev:~/planner$ npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-Cm5GLo6w.js   3.54 kB │ gzip: 1.57 kB
ana@dev:~/planner$ VITE_GRAPHQL_URL=/graphql npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-DYKvyMM5.js     5.27 kB │ gzip:  2.27 kB
dist/assets/apollo-CGBmoQ9B.js  192.66 kB │ gzip: 56.54 kB
```

The static build is 3.54 kB, within a few bytes of lesson 9's, because nothing in it imports Apollo.
The build with a server gets two files: the planner, slightly larger, and a chunk named after
`apollo.ts`, about 190 kB, or about 56 kB compressed, which is what crosses the network. Vite split it out
on its own, because `apollo.ts` is only ever reached through `import()`; the browser fetches it when
`watch` first runs.

## The import that would undo it

The split depends on one rule: **nothing reaches Apollo through a plain `import` from the code every
build runs.** One line breaks it. Put a top-level import of `queries.ts` back into `api.ts`, as a tidy
person might, and build the static version again:

```
ana@dev:~/planner$ sed -i '1a import "./queries";' src/api.ts
ana@dev:~/planner$ head -3 src/api.ts
// src/api.ts
import "./queries";
import type { Course, Session } from "./planner";
ana@dev:~/planner$ npm run build 2>&1 | grep 'assets/.*js'
dist/assets/index-CsC4EW2X.js   38.14 kB │ gzip: 10.39 kB
```

The static build is ten times larger, with not one line of it ever run. `queries.ts` calls `gql` when it
loads, and a call is something the bundler must keep, so `gql` and the parser behind it came along. A
size check in lesson 3's pipeline would have caught this before it shipped; that is what such checks are
for. Put the file back:

```
ana@dev:~/planner$ git restore src/api.ts
ana@dev:~/planner$ git status --short
```

## Whether 56 kB is a lot

It depends on what it replaces. Against lesson 9's twelve lines it is a great deal; against the code a
team would write to cache, share requests and roll back by hand, it is cheap, and that code would have
bugs Apollo has already fixed. **A small app with a few screens is often better served by a small client**,
or by lesson 9's twelve lines; the case for Apollo grows with the number of screens that show the same
objects. The next two sections are about the other choices.
