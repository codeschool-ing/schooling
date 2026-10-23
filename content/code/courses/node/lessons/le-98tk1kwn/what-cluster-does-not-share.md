---
title: What the workers do not share
version: 1
---

**Every worker in a cluster is a separate process with its own memory.** Anything a program keeps in a
variable exists once per worker, and the workers never see each other's. The links service keeps its
links in a `Map`, loaded from the file the first time a request needs it, and that is enough to break
it. In the links folder, the launcher from the last section runs `server.js` four times over, with a
data file of its own so that your links are left alone:

```
ana@dev:~/server/links$ rm -f demo/cluster.json && DATA_FILE=demo/cluster.json node --env-file=.env ../procs/cluster.js server.js
primary 15317: 4 workers of server.js
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/demo/cluster.json',
  adminKey: '(set, 32 characters)'
}
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 GET /nothing-here 404
127.0.0.1 POST /links 201
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 302
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 404
127.0.0.1 GET /9g9m9z 302
127.0.0.1 POST /links 201
SIGINT: closing; requests already open are finished first
SIGINT: closing; requests already open are finished first
SIGINT: closing; requests already open are finished first
closed
closed
closed
SIGINT: closing; requests already open are finished first
closed
^C
```

From the second terminal: eight requests to warm every worker up, so each loads the empty store; then
one new link; eight visits to it; and a second link.

```
ana@dev:~/server/links$ for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/nothing-here; done; echo
404 404 404 404 404 404 404 404 
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://nodejs.org/"}' http://127.0.0.1:3000/links
{"code":"9g9m9z","url":"https://nodejs.org/","visits":0,"created":"2026-10-22T22:48:38.249Z"}
ana@dev:~/server/links$ for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/9g9m9z; done; echo
404 404 404 302 404 404 404 302 
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"code":"k4ucg2","url":"https://example.com/","visits":0,"created":"2026-10-22T22:48:38.349Z"}
ana@dev:~/server/links$ cat demo/cluster.json
[
  {
    "code": "k4ucg2",
    "url": "https://example.com/",
    "visits": 0,
    "created": "2026-10-22T22:48:38.349Z"
  }
]
```

**One visit in four found the link, and three in four answered 404**: the worker that created it had
it in its `Map`, and the other three had loaded the store before it existed and never looked again.
**Then the file lost the first link.** The second one was created on another worker, whose `Map` had
never held the first, and the save wrote that `Map` over the file. Nothing failed and nothing was
logged: a link that was answered with 201 is gone, and the visits it had are gone with it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Why the links service breaks in a cluster. Four workers each hold their own Map of links. A link created on worker 4 exists only in worker 4&#x27;s Map, so the other three answer 404 for it. Each worker writes its whole Map over the same file, so the file holds whatever the last writer knew.\"><rect x=\"20\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><text x=\"100\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"100\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(empty)</text><text x=\"100\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"100\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"192\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><text x=\"272\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"272\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(empty)</text><text x=\"272\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"272\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"364\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><text x=\"444\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"444\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(empty)</text><text x=\"444\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">404</text><line x1=\"444\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"536\" y=\"30\" width=\"160\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker 4</text><text x=\"616\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Map</text><text x=\"616\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the new link</text><text x=\"616\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">302</text><line x1=\"616\" y1=\"130\" x2=\"360\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"260\" y=\"182\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">demo/cluster.json</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">whatever the last save held</text></svg>", "caption": "State in a variable is state per worker: the workers disagree, and the file keeps the last word."}
```

The same failure is waiting in anything held in memory:

| kept in a worker's memory | what goes wrong in a cluster |
|---|---|
| a cache, like the store's `Map` | each worker has its own, and they disagree |
| a counter, like visits or a rate limit | each counts a quarter, and the limit is four times too loose |
| sessions held in memory | a user signed in on one worker is a stranger to the next |
| a file each worker rewrites | the last writer wins, and every other write is lost |

**The fix is to keep the state outside the processes**: a database, or a store such as Redis, that all
the workers ask. That is the subject of the database courses. Until then the links service runs as one
process, which is correct, and as fast as it needs to be.

A program can still use `cluster` safely if it holds nothing between requests. The question to ask of
a service before running it in a cluster, or as several copies behind a load balancer, is the same:
**does a request depend on anything a previous request left in memory?**
