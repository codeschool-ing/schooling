---
title: Sending a page in pieces
version: 1
---

**An HTTP response does not have to be complete before it is sent.** A server can send the start of a
page, keep the connection open, and send the rest when it has it. The browser reads HTML as it
arrives and draws what it has, so the part that was quick appears while the part that was slow is
still being made. That is **streaming**, and every server in this course could already do it:
`res.write` sends a piece, `res.end` sends the last one.

The common picture is that server rendering means waiting for the slowest query before sending
anything. Lesson 1's `server.ts` does exactly that: it reads the whole plan, draws the whole page,
and only then writes a byte. If the sessions came from a slow database, the heading, the link and
the form, which need none of it, would wait for it too.

## A page in two parts

`stream.ts` is a small server for one page, a course's, that sends it in two parts. **The sessions
are slow on purpose**: `sessionsOf` waits a second before reading them, to stand for a slow query.
Everything else goes at once. Save it beside `server.ts`:

```schooling-example
{"language": "typescript", "file": "stream.ts", "parts": [
 {"code": "// stream.ts: a course page sent in two parts over one response. Everything that\n// is quick goes at once, with a placeholder; the sessions follow when they are\n// ready, with a few lines of script that put them where the placeholder was.\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);\nconst read = async (): Promise<Plan> => JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));", "note": "A server of its own, on port 3005, so that server.ts keeps working beside it."},
 {"code": "// The sessions are slow on purpose: the second's wait stands for a slow database query.\nasync function sessionsOf(slug: string) {\n  await new Promise((done) => setTimeout(done, 1000));\n  return (await read()).sessions.filter((s) => s.course === slug);\n}", "note": "The slow part. Nothing else in the file waits for it."},
 {"code": "createServer(async (req, res) => {\n  const slug = new URL(req.url ?? \"/\", \"http://localhost\").pathname.split(\"/\")[2];\n  const course = (await read()).courses.find((c) => c.slug === slug);\n  if (!course) {\n    // Decided before the first byte, so it can still be a 404.\n    res.writeHead(404, { \"content-type\": \"text/plain\" }).end(\"no such course\\n\");\n    return;\n  }", "note": "Whether the course exists is quick to find out, so it is decided before anything is sent, and an unknown course can still get a 404."},
 {"code": "  res.writeHead(200, { \"content-type\": \"text/html; charset=utf-8\" });\n  res.write(`<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><title>${esc(course.title)}</title></head>\n<body><main><p><a href=\"/\">All courses</a></p><h1>${esc(course.title)}</h1>\n<ul id=\"sessions\"><li>Loading sessions…</li></ul></main>\n`);", "note": "The first piece: the status, the headers, and the page up to a placeholder in the list. res.write sends it now and leaves the response open."},
 {"code": "  const rows = (await sessionsOf(slug)).map((s) => `<li>${s.date} · ${s.minutes} min</li>`).join(\"\");\n  res.end(`<template id=\"later\">${rows}</template>\n<script>document.getElementById(\"sessions\").replaceChildren(document.getElementById(\"later\").content)</script>\n</body></html>\n`);\n}).listen(3005, () => console.log(\"streaming on http://localhost:3005\"));", "note": "The second piece, a second later: the sessions inside a template, which the browser parses and does not show, and a script that moves them into the list in place of the placeholder."}
]}
```

Start it in a third terminal with `node stream.ts`. To see the pieces, `tools/chunks.ts` asks for a
page with Node's `fetch` and prints each piece of the body as it arrives, with the time since the
request. Save it in `tools/`:

```typescript
// tools/chunks.ts: ask for a page and print each piece of the response as it
// arrives: how long after the request, how many bytes, and how it begins.
//
//   node tools/chunks.ts URL
const start = performance.now();
const response = await fetch(process.argv[2]);
console.log(`${Math.round(performance.now() - start)} ms  status ${response.status}`);
const decoder = new TextDecoder();
for await (const chunk of response.body!) {
  const text = decoder.decode(chunk, { stream: true }).replace(/\s+/g, " ");
  console.log(`${Math.round(performance.now() - start)} ms  ${chunk.length} bytes  ${text.slice(0, 60)}`);
}
```

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3005/courses/git
```

**The status and the first piece arrived at once, and the second a second later**, exactly where the
wait is. An unknown course got its 404 immediately, because the server looked the course up before
writing anything.

```schooling-figure
@fig
```
