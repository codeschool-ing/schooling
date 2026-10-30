---
title: Hydration, and the request the browser does not make
version: 1
---

**With the dev server rendering on the server, the page has its text before any script runs.** A
`look` with JavaScript turned off now reads the week:

```
ana@dev:~/planner$ look http://localhost:4200/ --no-js --text main
This week

19 October to 25 October 2026

2 hours 45 minutes planned, 1 hour 30 minutes done.

1 hour 15 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 1 hour 50 minutes
Git: 25 minutes
```

With JavaScript on, the browser receives that HTML, shows it, and then runs the application.
Angular in the browser does not draw the page a second time. It walks the elements the server sent,
pairs each one with the component and the binding that made it, and attaches the event listeners.
That is **hydration**, and in development it reports what it did:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 7 component(s) and 63 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
2 hours 45 minutes planned, 1 hour 30 minutes done.

1 hour 15 minutes to go.

Done this week
```

"7 component(s) and 63 node(s)" were taken over as they were, and none had to be rebuilt.
`provideClientHydration`, which `ng add` put in `app.config.ts`, is what switches this on. Without
it, the browser would throw the server's HTML away and draw everything again from an empty
`<app-root>`, and the server's work would be visible only as a flicker.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A request rendered on the server, in two lanes, time running left to right. In the server&#x27;s lane, the server renders the page and asks the API for the data. An arrow carries the HTML and the ng-state script down to the browser&#x27;s lane, where three boxes follow: the browser shows the HTML, runs the scripts, and hydrates the page, attaching the listeners. A bracket over the first two browser boxes says that a click made then is recorded and replayed. A note under the last box says the first GET of the data is answered from ng-state.\"><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">server</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">browser</text><line x1=\"100\" y1=\"30\" x2=\"100\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"110\" y=\"50\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">renders the page</text><text x=\"200\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GET /api/planner</text><line x1=\"290\" y1=\"94\" x2=\"318\" y2=\"146\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,146.0 311.8,141.0 317.2,138.0\" fill=\"var(--amber)\"></polygon><text x=\"312\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTML + ng-state</text><rect x=\"320\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shows the HTML</text><text x=\"380\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">text, no listeners</text><rect x=\"455\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs the scripts</text><text x=\"515\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.js</text><rect x=\"590\" y=\"150\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hydrates</text><text x=\"650\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listeners attached</text><line x1=\"440\" y1=\"172\" x2=\"452\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,172.0 444.6,175.1 444.6,168.9\" fill=\"var(--wire)\"></polygon><line x1=\"575\" y1=\"172\" x2=\"587\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"587.0,172.0 579.6,175.1 579.6,168.9\" fill=\"var(--wire)\"></polygon><path d=\"M 320 140 L 320 134 L 575 134 L 575 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"447\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a click now is recorded, then replayed</text><text x=\"650\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the first GET is answered</text><text x=\"650\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from ng-state</text></svg>", "caption": "The server sends a finished page and the data it used; the browser shows it at once, and takes it over when the scripts have run."}
```

## No second request

`--network` printed no request. The week's data came from `/api/planner`, but the browser never
asked for it: the API's terminal has one `GET` for that page, made by the server.

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | grep -o '<script id="ng-state"[^>]*>.\{70\}'
<script id="ng-state" type="application/json">{"3bb753e941676b4de8a395d1ce503b99d0917105de6c7d9ada19de76449229d7":{"
```

The server wrote every answer `HttpClient` received while rendering into a script element at the
foot of the page, `ng-state`, keyed by a hash of the request. In the browser, the first identical
`GET` is answered from there. This is the **HTTP transfer cache**, and `provideClientHydration`
turns it on with the defaults: `GET` and `HEAD` requests only, and none that carries an
`Authorization` header, because the page is HTML anybody can save and read again. A request that
changes something, a `PATCH`, always goes to the server.

## A click before the scripts arrive

The other part of the line `ng add` wrote is `withEventReplay()`. Between the HTML arriving and
hydration finishing, the page looks finished and is not: a link or a button has no listener yet.
The server marks each element that has one:

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | grep -o 'jsaction="[^"]*"' | sort | uniq -c
      4 jsaction="click:;"
```

A small script at the top of the body records every click on a marked element. When hydration is
done, Angular plays those clicks back to the real listeners, so a person who tapped "JavaScript"
on a slow phone is taken to it rather than ignored.

## The server asks for `withFetch()`

The dev server's terminal has two complaints, the first printed once and the second for every page
it rendered. (The line about the lockfile is Vite noticing the packages `ng add` installed.)

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Browser bundles     
Initial chunk files  | Names            |  Raw size
main.js              | main             |  25.02 kB | 
styles.css           | styles           |   8.81 kB | 
chunk-VL5AOURQ.js    | -                |   6.21 kB | 
polyfills.js         | polyfills        | 172 bytes | 

                     | Initial total    |  40.21 kB

Lazy chunk files     | Names            |  Raw size
chunk-CVOEV7ZX.js    | courses-routes   |  40.42 kB | 


Server bundles      
Initial chunk files  | Names            |  Raw size
main.server.mjs      | main.server      |  26.27 kB | 
chunk-5G2P2OON.mjs   | -                |   6.24 kB | 
server.mjs           | server           |   1.84 kB | 
polyfills.server.mjs | polyfills.server | 363 bytes | 

Lazy chunk files     | Names            |  Raw size
chunk-4PI5SPPZ.mjs   | courses-routes   |  40.46 kB | 

Application bundle generation complete. [3.062 seconds] - 2026-10-23T12:00:03.623Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
9:00:03 AM [vite] (client) Re-optimizing dependencies because lockfile has changed
  ➜  Local:   http://localhost:4200/
NG02801: Angular detected that `HttpClient` is not configured to use `fetch` APIs. It's strongly recommended to enable `fetch` for applications that use Server-Side Rendering for better performance and compatibility. To enable `fetch`, add the `withFetch()` to the `provideHttpClient()` call at the root of the application.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
XHR support in `@angular/platform-server` is deprecated and will be removed in a future version of Angular. It has known security and performance issues in server environments, such as forwarding `Authorization` headers on cross-origin redirects and susceptibility to denial-of-service (DoS) via redirect loops. Please enable the HttpClient fetch backend instead by using `withFetch()`.
```

On the server, `HttpClient` still sends its requests the way it does in a browser, through
`XMLHttpRequest`, which Node.js does not have; Angular fills the gap with a library, `xhr2`, and the
second message says why that is a poor choice on a server. `withFetch()` makes `HttpClient` use the
`fetch` that Node.js and every browser have. It is one more feature in the `provideHttpClient`
call:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import {
  PreloadAllModules,
  provideRouter,
  withComponentInputBinding,
  withPreloading,
  withRouterConfig,
} from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      withPreloading(PreloadAllModules),
    ),
    provideHttpClient(withFetch(), withInterceptors([requestedBy])),
    provideClientHydration(withEventReplay()),
  ],
};
```

The import `ng add` put after the others has moved up beside them, which is where a person would
have written it. The interceptor from lesson 12 still runs: interceptors sit in front of whichever
backend sends the request, and the API's terminal still shows `planner` on each line. The next
pages render with no complaint in the dev server's terminal.
