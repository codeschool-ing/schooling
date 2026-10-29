---
title: The policy, written directive by directive
version: 1
---

**A Content Security Policy is a list of directives, each naming a kind of resource and where the page
may load it from.** Anything the list does not allow, the browser refuses, and says so in the console.
For a page like the planner, which loads its own files and nothing else, the policy is short, and every
`'self'` in it means the page's own origin.

`vite.config.ts` gets the headers once, as an object, and gives them to the preview server:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

const securityHeaders = {
  "Content-Security-Policy": [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ].join("; "),
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "Cross-Origin-Opener-Policy": "same-origin",
};

export default defineConfig({
  server: {
    proxy: { "/api": "http://127.0.0.1:3000" },
  },
  preview: {
    headers: securityHeaders,
  },
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

| directive or header | what it says | why the planner wants it |
|---|---|---|
| `default-src 'self'` | the fallback for every kind not named | anything forgotten below is still limited |
| `script-src 'self'` | scripts only from this origin, **and no inline script** | an injected `<script>` does not run |
| `style-src 'self'` | stylesheets only from this origin, no inline `<style>` | the build has one stylesheet file |
| `img-src 'self'` | images only from here | `book.svg` is the only one |
| `connect-src 'self'` | `fetch` and WebSocket only to here | a script that did run could not send data elsewhere |
| `object-src 'none'` | no plugins | nothing legitimate needs them |
| `base-uri 'self'` | no `<base>` pointing elsewhere | a `<base>` would turn every relative address into somebody else's |
| `form-action 'self'` | forms submit only here | an injected form cannot post your data away |
| `frame-ancestors 'none'` | no other page may put this one in a frame | lesson 9, clickjacking |
| `X-Content-Type-Options: nosniff` | believe the `Content-Type`, never guess | a file served as text is never run as a script |
| `Referrer-Policy` | send only the origin to other sites, never the whole address | addresses can carry what other sites should not see |
| `Permissions-Policy` | no camera, microphone or location, for this page or anything inside it | the planner uses none of them |
| `Cross-Origin-Opener-Policy: same-origin` | a window this page opens, or that opened it, cannot reach into it | another site's tab loses its handle on this one |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-policy\" aria-label=\"Five things the planner's page might try to run or load, each checked against its Content Security Policy. Its own script from /assets is allowed by script-src 'self'. An inline script added to the page is refused by the same directive. A script from another origin is refused by script-src 'self'. A fetch to another origin is refused by connect-src 'self'. Another site putting the page in a frame is refused by frame-ancestors 'none'.\"><defs><marker id=\"l08-policy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-policy-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-policy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"130\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">what the page tries</text><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the directive that decides</text><rect x=\"14\" y=\"34\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">its own /assets/index-….js</text><path d=\"M250 50 L330 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"34\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 50 L580 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-phosphor)\"></path><rect x=\"580\" y=\"34\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">runs</text><rect x=\"14\" y=\"76\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a &lt;script&gt; added to the page</text><path d=\"M250 92 L330 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"76\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 92 L580 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">refused</text><rect x=\"14\" y=\"118\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a script from another origin</text><path d=\"M250 134 L330 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"118\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">script-src 'self'</text><path d=\"M510 134 L580 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"118\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">refused</text><rect x=\"14\" y=\"160\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">fetch() to another origin</text><path d=\"M250 176 L330 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"160\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">connect-src 'self'</text><path d=\"M510 176 L580 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"160\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">refused</text><rect x=\"14\" y=\"202\" width=\"236\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">another site framing the page</text><path d=\"M250 218 L330 218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-paper-dim)\"></path><rect x=\"330\" y=\"202\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">frame-ancestors 'none'</text><path d=\"M510 218 L580 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-policy-ah-amber)\"></path><rect x=\"580\" y=\"202\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">refused</text></svg>", "caption": "Every load passes one directive. The page's own files pass; everything that is not the page's own, including text that became a script, is refused before it runs."}
```

**`script-src 'self'` is the line that earns the policy its place.** Lesson 9 shows text becoming
markup; with this line, markup that becomes a `<script>` is refused by the browser, a second defence
behind the first.

```
ana@dev:~/planner$ npx playwright test e2e/headers.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (41ms)
  ✓  2 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (214ms)

  2 passed (3.7s)
```

Both tests pass: the headers are there, and the page loads under them with nothing in the console.

```
ana@dev:~/planner$ curl -s -I http://localhost:4173/
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
Etag: W/"1a1-oQnFYEXs7j/YT1F2ilqAR+fppH0"
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
Date: Fri, 23 Oct 2026 23:28:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Serve the build with a Content Security Policy and four other headers"
```
