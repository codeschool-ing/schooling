---
title: What the development server does
version: 1
---

**Vite's development server does not build the planner.** It serves each file as the browser asks for
it, translated on the way: TypeScript and JSX in, plain JavaScript out. Browsers have understood
`import` for years, so the browser follows the imports itself, one request per module:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -E 'GET /(src|node_modules)' | head -n 12
net  GET /src/main.tsx  200
net  GET /node_modules/.vite/deps/react-router_dom.js?v=a137e1be  200
net  GET /node_modules/.vite/deps/react.js?v=a137e1be  200
net  GET /src/courseLoader.ts  200
net  GET /src/index.css  200
net  GET /node_modules/.vite/deps/@tanstack_react-query.js?v=a137e1be  200
net  GET /src/PlannerProvider.tsx  200
net  GET /src/queryClient.ts  200
net  GET /src/ErrorBoundary.tsx  200
net  GET /node_modules/.vite/deps/react-router.js?v=a137e1be  200
net  GET /src/Root.tsx  200
net  GET /src/WeekScreen.tsx  200
ana@dev:~/planner$ ls node_modules/.vite/deps | grep -v '\.map$'
@hookform_resolvers_zod.js
@tanstack_react-query.js
_metadata.json
development-CEpG6Jw9.js
jsx-runtime-cNwuCTLA.js
package.json
react-4hkZzRew.js
react-dom-CRx58tZq.js
react-dom.js
react-dom_client.js
react-hook-form.js
react-router.js
react-router_dom.js
react.js
react_jsx-dev-runtime.js
react_jsx-runtime.js
rolldown-runtime-SbdDWaPq.js
zod.js
```

- **`/src/main.tsx`, `/src/Root.tsx` and the rest are your files**, each fetched when something imports
  it, and each translated when it is fetched. Changing one means translating one, which is why an edit
  shows in the browser almost at once, and why the server starts in a fraction of a second whatever
  the size of the project.
- **The dependencies are the exception.** React, React Router and React Query are hundreds of small
  modules each, and fetching them one by one would be slow, so Vite **bundles them in advance** into
  `node_modules/.vite/deps`, one file per package the code imports. The `?v=a137e1be` is a hash of
  that work: it changes when the dependencies do, so the browser can keep these files for as long as it
  likes.

The listing also has files with hashed names, `react-4hkZzRew.js` and friends: code that several of the
bundled packages share, kept once rather than copied into each.

Lesson 1 promised a flag. By default the server answers only on `localhost`, this machine. **`--host`**
makes it answer on the machine's network addresses too, so that a phone on the same network can open
the planner, which is the quickest test of a layout on a real small screen:

```

> planner@0.0.0 dev
> vite --host


  VITE v8.3.5  ready in 217 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.0.2.2:5173/  eth0
```

The `--` passes the flag through `npm run dev` to `vite`. The `Network` line is the address to type on
the phone; the one here is the lab machine's. The flag means what it says: **anyone on the same
network** can open it, so on a café's network, leave it off.

```schooling-figure
{"svg": "<svg data-fig=\"dev-and-build\" viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two ways the same source reaches a browser. With the development server: each file of src is translated when the browser asks for it, one request per module, and the dependencies come pre-bundled from node_modules/.vite/deps. With a build: everything is bundled ahead into a few files in dist/assets with hashed names, plus index.html and the files from public.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">npm run dev</text><rect x=\"30\" y=\"36\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/main.tsx</text><rect x=\"30\" y=\"70\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/Root.tsx</text><rect x=\"30\" y=\"104\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/src/WeekScreen.tsx</text><rect x=\"30\" y=\"138\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">…</text><rect x=\"30\" y=\"176\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"189.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.vite/deps/</text><text x=\"115.0\" y=\"202.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react.js · …</text><text x=\"215\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one request</text><text x=\"215\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">per module</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">npm run build</text><rect x=\"400\" y=\"40\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dist/index.html</text><rect x=\"400\" y=\"82\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">assets/index-R8L4SX4s.js</text><rect x=\"400\" y=\"124\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">assets/CourseScreen-jvv40fJe.js</text><rect x=\"400\" y=\"166\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses.json · favicon.svg</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">copied from public/, no hash</text></svg>", "caption": "Development translates on request; a build bundles ahead."}
```
