---
title: What each one sends besides the HTML
version: 1
---

**A server-rendered page that will hydrate has to send its data twice: once drawn as HTML, and once
as data the script can read.** The script in the browser has to build the same page the server
built, and it cannot do that from the HTML alone, so each framework writes what the server knew
into the page, inside a `<script>` that is not code but data. In lesson 1 the planner did this the
expensive way: its script fetched `/courses.json` again. The four frameworks all avoid the second
request, and they differ in what they put in the page instead.

`tools/payload.ts` asks a server for a page and measures the scripts written inside it, the ones
with no `src`. It also says whether the titles of the **other** courses are in the page, which
tells you whether it carries the whole plan or only what this page needed. Save it beside
`weigh.ts`:

```typescript
// tools/payload.ts: what a server-rendered page carries besides its HTML.
//
//   node tools/payload.ts URL...
//
// The scripts written inside the page (no src), their size, and whether the
// titles of the two courses this page does not show are anywhere in it.
for (const url of process.argv.slice(2)) {
  const html = await (await fetch(url)).text();
  const inline = [...html.matchAll(/<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g)];
  const bytes = inline.reduce((sum, m) => sum + Buffer.byteLength(m[1]), 0);
  const others = ["HTML and CSS", "JavaScript"].filter((t) => html.includes(`"${t}"`));
  console.log(`${url}  ${inline.length} inline scripts, ${bytes} bytes, other courses: ${others.join(", ") || "none"}`);
}
```

It uses Node's own `fetch`, with no browser, because the question is what the server sent. Run it
against the Git page of all five:

```
ana@dev:~/planner$ node tools/payload.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
http://localhost:3000/courses/git  0 inline scripts, 0 bytes, other courses: none
http://localhost:3001/courses/git  10 inline scripts, 5486 bytes, other courses: none
http://localhost:3002/courses/git  3 inline scripts, 1071 bytes, other courses: HTML and CSS, JavaScript
http://localhost:3003/courses/git  1 inline scripts, 737 bytes, other courses: none
http://localhost:3004/courses/git  3 inline scripts, 1409 bytes, other courses: HTML and CSS, JavaScript
```

## Four answers to the same problem

**Nuxt and Angular send the whole plan.** Each records the response of every data request the
server made while rendering, `useFetch("/api/plan")` in one and `HttpClient.get("/courses.json")`
in the other, and writes it into the page: Nuxt in a `<script id="__NUXT_DATA__">`, Angular in a
`<script id="ng-state">`. In the browser the same request is answered from that copy instead of the
network. The page shows one course and carries three, because the request returned three.

**SvelteKit sends what `load` returned**, and the `load` of the course page returned one course and
its two sessions. The data is written into the small script that starts the app, as the argument
to `kit.start`. A `load` that returned the whole plan would send the whole plan: the framework sends
exactly what you wrote, and the choice is yours.

**Next.js sends something else again.** Its pages are server components, which never run in the
browser, so there is no component there that needs the data. What it sends, in a series of
`self.__next_f.push(...)` calls, is the *rendered* result: a description of the tree of elements the
server produced, which React in the browser uses to hydrate and to keep the page when the person
navigates. The two other courses are not in it because no element shows them. **The data a server
component reads stays on the server**, which is also why it can read a file, a database or a secret
without any of it reaching the page.

None of these is wrong. They are the same trade made four ways: data the browser does not get has to
be fetched again the moment it is needed, and data it gets that it never uses is bytes on every
first load. Lesson 4 is about what the script does with this data once it has arrived.
