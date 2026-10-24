---
title: Interceptors, for what every request needs
version: 1
---

**An interceptor is a function every request passes through on its way out, and every answer on its
way back.** It is where a thing that concerns all requests goes, so that no single request has to
remember it: a header that says who is asking, a token that proves it, a log line, a retry. The
request is immutable, so an interceptor that changes one makes a changed copy with `clone` and
passes that on with `next`.

The planner's API logs one header, `X-Requested-By`, and so far every line says `-`. An interceptor
that sets it on every request:

```schooling-example
{"language": "typescript", "file": "src/app/requested-by.ts", "parts": [
 {"code": "// src/app/requested-by.ts\nimport { HttpInterceptorFn } from '@angular/common/http';\n\nexport const requestedBy: HttpInterceptorFn = (req, next) =>\n  next(req.clone({ setHeaders: { 'X-Requested-By': 'planner' } }));", "note": "An interceptor is a function of the request and `next`, the rest of the chain. What it returns is the answer, so it may look at that too."}
]}
```

Interceptors are a feature of `HttpClient`, so this is where `provideHttpClient()` comes in, with
`withInterceptors` listing them in the order a request meets them:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

The page is the same. The API's terminal is not:

```
ana@dev:~/planner$ node server/api.mjs
the planner's API is on http://localhost:3000
GET /api/planner -
PATCH /api/sessions/5 -
PATCH /api/sessions/9 -
```

The last `GET` came with the header, and neither the store nor the resource knows it was added. The
resource uses `HttpClient` underneath, so it goes through the same chain as a `patch` does.

## What interceptors are for

| an interceptor that | is how an application |
|---|---|
| adds `Authorization: Bearer ...` | sends a signed-in user's token with every request |
| reads the status of the answer | sends somebody to the sign-in page on a 401 |
| logs the method, the URL and the time taken | finds out which requests are slow |
| tries again on a network failure | survives a moment of bad Wi-Fi |

**One protection is built in rather than written.** `HttpClient` already defends against
cross-site request forgery, where another site's page makes your browser send a request to your
API with your cookies: when the server sets an `XSRF-TOKEN` cookie, `HttpClient` copies it into an
`X-XSRF-TOKEN` header on every request that changes something, and the server checks that the two
match. A page on another site cannot read your cookies, so it cannot send the header. The planner's
API uses no cookies, so there is nothing to forge yet; an API that signs people in with one should
check the header.
