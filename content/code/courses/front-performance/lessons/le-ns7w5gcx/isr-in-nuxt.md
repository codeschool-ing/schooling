---
title: Regeneration in Nuxt
version: 1
---

**Nuxt writes the same idea as a route rule**: `swr` with a number of seconds caches each rendered
page for that long on the server, and serves the old copy while it renders a new one. The rule goes
in `nuxt.config.ts`, beside a second one that prerenders the home page at build time, so one site
uses two modes. Replace the file:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  app: { head: { title: "Study planner", htmlAttrs: { lang: "en" } } },
  routeRules: {
    "/": { prerender: true },
    "/courses/**": { swr: 10 },
  },
});
```

`npm run build` this time, not `generate`: the course pages are rendered by the server, on demand,
and only the home page is a file. Start `PORT=3002 node .output/server/index.mjs` in the second
terminal, and run the same four requests as in Next.js, with a `look` that prints Nuxt's headers:

```
ana@dev:~/meta/nuxt$ look() { curl -s -D - -o /tmp/page.html http://localhost:3002/courses/git | grep -iE '^(cache-control|last-modified):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }
ana@dev:~/meta/nuxt$ look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/nuxt$ look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sleep 11; look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sleep 1; look
last-modified: Fri, 23 Oct 2026 23:16:11 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git and GitHub</h1>
```

**The same four steps, and the same request is the one that sees the old page**: the third, eleven
seconds after the change, got *Git* with the old `last-modified`, and the fourth, a second later, got
the new title with a new one. Nuxt says less about it than Next.js, no `HIT` or `STALE` header, so the
`last-modified` date is how you tell which copy came back.

`isr` is the other rule, with the same meaning on a host that supports it, where the copies are kept
by the host's own cache rather than by the Node process. On this computer, with the `node-server`
preset, `swr` is the one that runs. Put the title and the configuration from lesson 2 back
afterwards; lesson 4 needs every page rendered on request.
