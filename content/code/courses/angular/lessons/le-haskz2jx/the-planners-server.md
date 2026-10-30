---
title: The server is yours
version: 1
---

**In development the dev server forwarded `/api` to the API; in production nothing does, because
`proxy.conf.json` belongs to `ng serve`.** The production server is asked for `/api/planner`, finds
no file of that name, and renders the application at that address. The application has no route
there either:

```
ana@dev:~/planner$ curl -s -i http://localhost:4000/api/planner | head -1
HTTP/1.1 404 Not Found
```

A `404`, from `NotFound`, in HTML, where the planner expected JSON. The production server needs to
do what the proxy did, and `src/server.ts` is where. It is ordinary Express code the project owns,
and `ng add` left a comment in it saying where an API belongs: before the line that renders
everything else. The planner's API already exists, on port 3000, so the server forwards to it:

```schooling-example
{"language": "typescript", "file": "src/server.ts", "parts": [
 {"code": "// src/server.ts\nimport {\n  AngularNodeAppEngine,\n  createNodeRequestHandler,\n  isMainModule,\n  writeResponseToNodeResponse,\n} from '@angular/ssr/node';\nimport express from 'express';\nimport { join } from 'node:path';\n\nconst browserDistFolder = join(import.meta.dirname, '../browser');"},
 {"code": "const plannerApi = process.env['PLANNER_API'] ?? 'http://localhost:3000';\n\nconst app = express();\nconst angularApp = new AngularNodeAppEngine();", "note": "Where the API is, from an environment variable, with lesson 12's address when there is none."},
 {"code": "app.use('/api', express.text({ type: 'application/json' }), async (req, res) => {\n  try {", "note": "Every request under `/api`, first. `express.text` reads a JSON body as text, which is all a forward needs: the API checks it."},
 {"code": "    const answer = await fetch(plannerApi + req.originalUrl, {\n      method: req.method,\n      headers: {\n        'content-type': 'application/json',\n        'x-requested-by': req.get('x-requested-by') ?? '-',\n      },\n      body: typeof req.body === 'string' ? req.body : undefined,\n    });\n    res.status(answer.status).type('application/json').send(await answer.text());", "note": "`originalUrl` still has `/api` in it, so the API sees the address the browser asked for."},
 {"code": "  } catch (error) {\n    console.error(`The planner's API at ${plannerApi} did not answer:`, error);\n    res.status(502).json({ error: 'the planner API did not answer' });\n  }\n});", "note": "An API that does not answer is a `502`, said in JSON, and said in this terminal. A forward that failed quietly would leave nobody knowing which of the two servers was down."},
 {"code": "app.use(\n  express.static(browserDistFolder, {\n    maxAge: '1y',\n    index: false,\n    redirect: false,\n  }),\n);\n\napp.use((req, res, next) => {\n  angularApp\n    .handle(req)\n    .then((response) => (response ? writeResponseToNodeResponse(response, res) : next()))\n    .catch(next);\n});\n\nif (isMainModule(import.meta.url) || process.env['pm_id']) {\n  const port = process.env['PORT'] || 4000;\n  app.listen(port, (error) => {\n    if (error) {\n      throw error;\n    }\n\n    console.log(`Node Express server listening on http://localhost:${port}`);\n  });\n}\n\nexport const reqHandler = createNodeRequestHandler(app);", "note": "The rest is what `ng add` wrote, with its comments taken out."}
]}
```

Only the headers the API reads are passed on. A forward that copied every header would also copy
the cookies and anything else the browser sent to a server that has no use for them; the API is
told what it needs and no more.

Build, and restart the server, this time with the script `ng add` wrote into `package.json`,
`npm run serve:ssr:planner`, which runs the same line. The planner works on port 4000 as it did on
4200, ticking included:

```
ana@dev:~/planner$ look http://localhost:4000/courses/javascript --today 2026-10-23 --network --text app-course-sessions --do 'check Sat 24 Oct, 50 minutes'
-- check Sat 24 Oct, 50 minutes
net  PATCH /api/sessions/5  200
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

The page arrived rendered, so the browser asked for nothing until the box was ticked; the `PATCH`
went to the production server and through it to the API. Untick it, with the same command, so the
planner is as it was.

## When the API is down

Stop the API with Ctrl-C in its terminal, and open the week:

```
ana@dev:~/planner$ look http://localhost:4000/ --today 2026-10-23 --no-js --text app-week
This week

19 October to 25 October 2026

The week could not be loaded: Http failure response for http://localhost:4000/api/planner: 502 Bad Gateway
```

The server rendered the page with the error lesson 12 wrote for this case, and its terminal says
which server failed:

```
ana@dev:~/planner$ npm run serve:ssr:planner

> planner@0.0.0 serve:ssr:planner
> node dist/planner/server/server.mjs

Node Express server listening on http://localhost:4000
The planner's API at http://localhost:3000 did not answer: TypeError: fetch failed
    at node:internal/deps/undici/undici:14902:13
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async file:///home/ana/planner/dist/planner/server/server.mjs:60:3140 {
  [cause]: Error: connect ECONNREFUSED 127.0.0.1:3000
      at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1637:16) {
    errno: -111,
    code: 'ECONNREFUSED',
    syscall: 'connect',
    address: '127.0.0.1',
    port: 3000
  }
}
```

Start the API again, and commit:

```
ana@dev:~/planner$ git add -A && git commit -q -m "SSR: the planner is rendered on the server"
```

`dist/` is in the `.gitignore` the CLI wrote in lesson 2, so the build is not in the commit: a
build is made from a commit, never kept in one.
