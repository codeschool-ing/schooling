---
title: What the frameworks send
version: 1
---

**Each of the four frameworks of lesson 2 sends cache headers of its own**, and the quickest way to know
what is to ask. `tools/heads.ts` fetches a page, finds the first script it names, and prints the
`Cache-Control` of both. Save it in `tools/`:

```typescript
// tools/heads.ts: for each address, the cache-control of the page and of the first
// script the page names, which is what a browser will keep and for how long.
//
//   node tools/heads.ts URL...
for (const url of process.argv.slice(2)) {
  const page = await fetch(url);
  const html = await page.text();
  // A script element, or a modulepreload for one; and the page's <base>, which relative addresses start from.
  const src = html.match(/<script[^>]+src="([^"]+)"/)?.[1] ?? html.match(/href="([^"]+\.js)"/)?.[1];
  const base = new URL(html.match(/<base href="([^"]+)"/)?.[1] ?? url, url);
  const script = src ? await fetch(new URL(src, base)) : null;
  console.log(url);
  console.log(`  page    ${page.headers.get("cache-control") ?? "(none)"}`);
  console.log(`  script  ${script?.headers.get("cache-control") ?? "(none)"}`);
}
```

Start the four production servers of lesson 2, each on its own port, as lesson 4 last did, and ask all five
servers, the planner's first:

```
ana@dev:~/planner$ node tools/heads.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
http://localhost:3000/courses/git
  page    max-age=0, s-maxage=10
  script  public, max-age=31536000, immutable
http://localhost:3001/courses/git
  page    s-maxage=3600, stale-while-revalidate=82800
  script  public, max-age=31536000, immutable
http://localhost:3002/courses/git
  page    (none)
  script  public, max-age=31536000, immutable
http://localhost:3003/courses/git
  page    (none)
  script  public,max-age=31536000,immutable
http://localhost:3004/courses/git
  page    (none)
  script  public, max-age=31536000
```

**Every framework keeps its scripts for a year**, because every one of them names its build's files with a
hash, as Vite does. Three of them add `immutable`; Angular's server sends the year without it, which costs
a check when the person reloads the page, in the browsers that check.

**The pages differ.** Nuxt, SvelteKit and Angular send nothing for a page drawn on the server, which leaves
the browser to guess, as the section "What a cache saves" described. For a page that is the same for
everybody, a header like the planner's is one line of their configuration. **Next.js sends `s-maxage=3600,
stale-while-revalidate=82800`** for the course page, whose lesson-3 version regenerates every hour and
expires after a day: a CDN may keep it an hour, and serve it stale for the rest of the day while it fetches
a new one. That is incremental regeneration written as a header, which any CDN understands.

Stop the four servers when you are done.
