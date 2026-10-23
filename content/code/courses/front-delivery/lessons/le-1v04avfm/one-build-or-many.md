---
title: One build, or one per environment
version: 1
---

**A value fixed at build time means a site with two environments is two builds**, and that is a choice
with a cost. The staging build and the production build of the planner differ in one variable, and so
they differ in their files:

```
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets/*.js
dist/assets/index-sAFi8ckx.js
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null && ls dist/assets/*.js
dist/assets/index-2shUX-Zw.js
```

Two different hashes. **What was checked on staging is not, byte for byte, what goes to production**:
production is a second build of the same commit, made later, with other values. Usually that is fine.
Occasionally it is the whole incident: a dependency resolved differently, a variable missing in one
environment and not the other, a build that worked on Tuesday and fails on Thursday.

## Build once and promote

The alternative is to build once and move the same folder from one environment to the next, which is
called **promoting** a build. For that to work, nothing that differs between environments may be inside
the bundle, so it has to arrive another way: the page fetches it when it starts. A small file next to
`index.html`, written by the deploy rather than by the build, holds the values:

```json
{ "title": "Study planner (staging)" }
```

and the app reads it before drawing anything. This is a pattern, not a change to the planner:

```typescript
const config = await fetch(`${import.meta.env.BASE_URL}config.json`).then((r) => r.json());
```

The deploy for each environment copies the same `dist/` and writes a different `config.json` beside it.

| | a build per environment | one build, promoted |
|---|---|---|
| where a value lives | in the bundle | in a file fetched at start |
| what reaches production | a second build of the same commit | the folder that was tested |
| cost at start | none | one more request before the first screen |
| a wrong value is fixed by | building again | replacing one small file |
| what the hosts do by default | Vercel, Netlify and Cloudflare Pages build each environment separately | you arrange it, in your own pipeline |

**Neither is a secret store.** `config.json` is as public as the bundle; it is fetched by the same
browser. The choice is between two ways of publishing a value, never between publishing it and not.

## What this course does

The planner stays with a build per environment, because that is what all three hosts with previews do
for you and the planner has one harmless variable. The question is worth asking again the day a site
has many: the more values differ between environments, the more a promoted build saves, and the more a
second build has to go wrong.
