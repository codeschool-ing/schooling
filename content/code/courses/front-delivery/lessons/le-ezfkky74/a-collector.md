---
title: A collector
version: 1
---

**A collector is a server with one address that accepts error reports and keeps them.** A hosted
service's collector is large and does a great deal with what it receives; this one keeps each report as a
line of JSON in a file and prints a summary, which is enough to see the whole chain work.

```javascript
// api/collector.mjs
import { appendFileSync } from "node:fs";
import { createServer } from "node:http";

const LIMIT = 16 * 1024;

createServer(async (req, res) => {
  if (req.method !== "POST" || req.url !== "/errors") {
    res.writeHead(404).end();
    return;
  }
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (body.length > LIMIT) {
      res.writeHead(413).end();
      return;
    }
  }
  let report;
  try {
    report = JSON.parse(body);
  } catch {
    res.writeHead(400).end();
    return;
  }
  const line = { at: new Date().toISOString(), ...report };
  appendFileSync(new URL("errors.jsonl", import.meta.url), JSON.stringify(line) + "\n");
  console.log(`${line.release} ${line.source}: ${line.message}`);
  res.writeHead(204).end();
}).listen(4001, "127.0.0.1", () => console.log("Collecting errors on http://127.0.0.1:4001/errors"));
```

Everything the planner sends arrives from browsers the team does not control, so the collector trusts
none of it:

- **A size limit.** A report is a message and a stack, a few kilobytes. Anything over 16 kB is refused
  with a 413 before it is read to the end, so one page cannot fill the disk.
- **JSON or nothing.** A body that does not parse is refused with a 400, and nothing is written.
- **Its own timestamp.** `at` is the collector's clock. The browser's clock can be wrong by hours, and a
  report's time is the one thing the team must be able to sort by.
- **Answers nothing useful.** A 204, no content, so the collector tells a stranger nothing about itself.

A public collector needs more than this: a rate limit per address, so one broken page in a loop does not
drown every other report, and a check that reports come from the planner's own origin. Hosted services
do both. This one listens only on `127.0.0.1`.

## Reaching it from the page

The page reaches the collector the way it reaches GraphQL, through Vite's proxy, so it never leaves its
own origin. Add the second address to `vite.config.ts`, which also gains the build option the section on
source maps explains:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    proxy: {
      "/graphql": "http://127.0.0.1:4000",
      "/errors": "http://127.0.0.1:4001",
    },
  },
  build: { sourcemap: "hidden" },
});
```

`vite preview`, which serves a finished build, uses the same proxy, which the next section relies on.
Give development the address, keep the reports out of Git, and start the collector in a terminal of its
own:

```
ana@dev:~/planner$ printf 'VITE_GRAPHQL_URL=/graphql\nVITE_ERRORS_URL=/errors\n' > .env.development
ana@dev:~/planner$ printf 'api/errors.jsonl\nmaps\n' >> .gitignore
```

## The first report

With the GraphQL server, the collector and `npm run dev` running, open the JavaScript course, stop the
GraphQL server with Ctrl-C, and press **Mark done**. Lesson 10's rollback happens as before, and the
collector's terminal now shows what the page reported:

```
ana@dev:~/planner$ node api/collector.mjs
Collecting errors on http://127.0.0.1:4001/errors
dev saveDone: Response not successful: Received status code 502
```

`dev` is the release, since nothing set one; `saveDone` is where it was caught; and the message is
Apollo's. The whole report is the last line of the file:

```
ana@dev:~/planner$ tail -1 api/errors.jsonl
{"at":"2026-10-24T00:50:20.952Z","message":"Response not successful: Received status code 502","stack":"ServerError: Response not successful: Received status code 502\n    at parseJsonEncoding (http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13909:36)\n    at parseResponse (http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13934:9)\n    at http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13938:18","source":"saveDone","release":"dev","path":"/course/javascript"}
```

The stack is readable here because the dev server sends each module as it was written. The next section
shows what a stack looks like from the build that real people get.
