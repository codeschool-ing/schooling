---
title: Regeneration in Next.js
version: 1
---

**In Next.js 16 the age of a page is the age of the cached data it read.** The project's
`getPlan()` is cached with `cacheLife("hours")`, and the build's route table said what that
means: revalidate after an hour, expire after a day. To watch a regeneration happen without
waiting an hour, give the data a lifetime of ten seconds. In `lib/plan.ts`, change one line:

```typescript
  cacheLife({ revalidate: 10, expire: 3600 });
```

`revalidate` is the first number of the previous section, in seconds, and `expire` the second. A
third field, `stale`, is how long the browser's router may reuse a page without asking the server at
all. It is left at its default of five minutes, because **a `stale` under thirty seconds takes the
data out of the prerender altogether**, and the build then refuses the page as uncached. Rebuild and
look at the table:

```
ana@dev:~/meta/next$ npm run build 2>&1 | sed -n '/^Route/,$p' | head -8
Route (app)                Revalidate  Expire
┌ ○ /                             10s      1h
├ ○ /_not-found
├ ƒ /api/revalidate
└   /courses/[slug]
  ├ ◐ /courses/[slug]
  ├ ○ /courses/html-css           10s      1h
  ├ ○ /courses/javascript         10s      1h
```

Start `npx next start -p 3001` in the second terminal. The command below asks for the Git page and
prints two of its headers and its heading; it is run four times around a change to the data:

```
ana@dev:~/meta/next$ look() { curl -s -D - -o /tmp/page.html http://localhost:3001/courses/git | grep -iE '^(x-nextjs-cache|cache-control):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }
ana@dev:~/meta/next$ look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/next$ look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sleep 11; look
x-nextjs-cache: STALE
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sleep 1; look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git and GitHub</h1>
```

Read the four answers in order:

1. **`HIT`, *Git*.** The file from the build.
2. **`HIT`, *Git*, after the data changed.** Nothing has asked for a new render, and the copy is
   younger than ten seconds.
3. **`STALE`, *Git*, eleven seconds later.** The copy is past its ten seconds, so Next.js served it
   anyway and started a render in the background. This is the request that sees the old page.
4. **`HIT`, *Git and GitHub*, a second later.** The render finished, and the new copy is served.

`Cache-Control: s-maxage=10, stale-while-revalidate=3590` is the same pair of numbers written for
whatever cache sits in front of the server: fresh for ten seconds, and usable stale for the rest of
the hour. Lesson 9 reads that header properly. Put the title back and `cacheLife("hours")` back
before the next section.
