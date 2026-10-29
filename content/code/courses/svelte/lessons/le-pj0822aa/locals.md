---
title: locals, and an id for each request
version: 1
---

**`event.locals` is an object that belongs to one request**, which a hook can write to and every server
load function, action and endpoint of that request can read. Applications usually put the signed-in
user there: a hook reads the session cookie once, and everything after it knows who is asking. The
planner has no users, but it has a use for the same mechanism straight away: **a short id for each
request**, printed in the log line, so that when something goes wrong, the line in the log and the
page the person saw can be matched up. Replace `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';"},
 {"code": "async function log({ event, resolve }) {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}\n\nasync function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);", "note": "Set before `resolve`, so everything that handles the request can read `event.locals.id`. Eight hex characters are plenty to tell a day's requests apart."}
]}
```

`crypto` is the Web Crypto API, which Node has as a global, as browsers do. Build, restart, and ask for a
page twice:

```
ana@dev:~/planner$ curl -s -o /dev/null http://localhost:3000/ && curl -s -o /dev/null http://localhost:3000/courses/piano
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
5ac1a69f GET / 200 36 ms
25d2780e GET /courses/piano 404 3 ms
```

Each line now starts with the id of its request. The next section puts the same id on the page a person
sees when something fails.

`locals` is the server's, like the hooks file. It never reaches the browser unless a load function
returns something from it, which makes it the right place for things the browser must not see, and the
wrong place for anything a page needs: that goes in what a load function returns.
