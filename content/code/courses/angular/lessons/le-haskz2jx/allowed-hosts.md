---
title: The production server, and the hosts it answers for
version: 1
---

**`ng build` now produces two programs: the files a browser downloads, and a Node.js server that
renders pages.**

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|Prerendered|Output location'
                      | Initial total    | 344.15 kB |                95.25 kB
Prerendered 0 static routes.
Output location: /home/ana/planner/dist/planner
```

```
ana@dev:~/planner$ ls dist/planner dist/planner/server
dist/planner:
3rdpartylicenses.txt
browser
prerendered-routes.json
server

dist/planner/server:
angular-app-engine-manifest.mjs
angular-app-manifest.mjs
assets-chunks
chunk-ITOR7NUX.mjs
chunk-KUERU4XA.mjs
chunk-KYQQYI4M.mjs
chunk-LYHAGGDF.mjs
chunk-PJRDAGXT.mjs
chunk-UBU2ZLSD.mjs
index.server.html
main.server.mjs
polyfills.server.mjs
server.mjs
```

`dist/planner/browser` holds what it always held. `dist/planner/server/server.mjs` is `server.ts`,
built, with the whole application inside it. It is started with Node.js, in a terminal of its own;
`ng add` also wrote it into `package.json` as `npm run serve:ssr:planner`, which runs the same line:

```
ana@dev:~/planner$ node dist/planner/server/server.mjs
Node Express server listening on http://localhost:4000
```

It listens on port 4000, and the API from lesson 12 is still running on 3000. But the first page it
is asked for comes back empty:

```
ana@dev:~/planner$ look http://localhost:4000/ --no-js --text body
```

And its terminal says why:

```
ana@dev:~/planner$ node dist/planner/server/server.mjs
Node Express server listening on http://localhost:4000
ERROR: Bad Request ("http://localhost:4000/").
Header "host" with value "localhost:4000" is not allowed.
Falling back to client side rendering. This will become a 400 Bad Request in a future major version.

For more information, see https://angular.dev/best-practices/security#preventing-server-side-request-forgery-ssrf
```

## Why a server checks its own name

**A request names the site it is for in its `Host` header, and the person sending the request
writes that header.** A browser fills it in from the address bar; `curl`, or any program, can write
anything. That matters here because of how the server resolves a relative URL. When the planner
renders on the server and asks for `/api/planner`, there is no address bar: Angular builds the full
URL from the request it is answering, `Host` header included. A request sent with
`Host: evil.example` would make the planner's own server fetch `http://evil.example/api/planner`
and render what came back into the page.

That is **server-side request forgery**: a stranger choosing what a server inside your network
requests. On a real host the dangerous target is not a stranger's site but something only the
server can reach, an internal admin page or the address where a cloud machine reads its own
credentials. The defence is to list the names the site is served under and refuse the rest, which
is the `security.allowedHosts` block `ng add` wrote into `angular.json` with an empty list. For now
an empty list falls back to rendering in the browser, with the error above; the message says a
future version will refuse the request instead.

The planner is served as `localhost`, so that is the list:

```
ana@dev:~/planner$ npx ng config projects.planner.architect.build.options.security.allowedHosts '["localhost"]'
```

The list is read at build time, so build again and restart the server, Ctrl-C and the same command.
A port is not part of the name, and `localhost:4000` matches `localhost`. Then the planner's own
name renders, and any other is refused:

```
ana@dev:~/planner$ look http://localhost:4000/ --no-js --text app-week
This week

19 October to 25 October 2026

The week could not be loaded: Http failure response for http://localhost:4000/api/planner: 404 Not Found
```

```
ana@dev:~/planner$ curl -s -i -H 'Host: evil.example' http://localhost:4000/ | head -1
HTTP/1.1 400 Bad Request
```

The dev server needs none of this: it answers only on `localhost` unless told otherwise, and it
allows that name. A deployment adds its real names, `planner.example.com` and whatever else points
at it. A name may start with `*.` to allow every subdomain, which is worth doing only for a domain
you control every subdomain of. A `*` on its own allows every name, and is the defence switched off
with a setting that looks like one. The list can also come from an environment variable,
`NG_ALLOWED_HOSTS`, read when the server starts, so a deployment can set its own names without a
build.

The page now renders, and says the week could not be loaded. That is the next section.
