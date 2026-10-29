---
title: A page and an endpoint at the same address
version: 1
---

**A `+server.js` can sit in the same folder as a `+page.svelte`, and the request decides which of the two
answers it.** A browser asking for a page says so in its `Accept` header, which starts with `text/html`;
a program asking for data says `application/json`, or nothing in particular. SvelteKit sends a `GET` or a
`POST` that prefers HTML to the page, and any other `GET` to the endpoint; a `POST` goes there too only
if the endpoint has a `POST` of its own. So `/courses/guitar` can be the
course page for a person and the course's data for a program, at one address that both can bookmark.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Four requests arrive at the same address, /courses/guitar. A GET whose Accept header starts with text/html goes to the page, +page.svelte, which renders HTML. A POST that prefers HTML, a form sent by the browser, or a POST that use:enhance marks as being for an action, goes to the actions in +page.server.js. A GET that asks for application/json, or for anything at all, goes to the GET in +server.js, which answers JSON.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">/courses/guitar</text><rect x=\"20\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: text/html</text><line x1=\"280\" y1=\"64\" x2=\"418\" y2=\"64\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,64.0 410.6,67.1 410.6,60.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"420\" y=\"44\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+page.svelte</text><text x=\"686\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the page, as HTML</text><rect x=\"20\" y=\"100\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST  ?week=…&amp;/add</text><line x1=\"280\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,120.0 410.6,123.1 410.6,116.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"420\" y=\"100\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+page.server.js</text><text x=\"686\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">an action</text><rect x=\"20\" y=\"156\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: application/json</text><line x1=\"280\" y1=\"176\" x2=\"418\" y2=\"176\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,176.0 410.6,179.1 410.6,172.9\" fill=\"var(--amber)\"></polygon><rect x=\"420\" y=\"156\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">+server.js</text><text x=\"686\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the course, as JSON</text><rect x=\"20\" y=\"212\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: */*</text><line x1=\"280\" y1=\"232\" x2=\"418\" y2=\"232\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,232.0 410.6,235.1 410.6,228.9\" fill=\"var(--amber)\"></polygon><rect x=\"420\" y=\"212\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">+server.js</text><text x=\"686\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the course, as JSON</text><text x=\"360\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the Accept header, and the method, decide which file answers</text></svg>", "caption": "One address, two kinds of answer: SvelteKit picks the file from what the request says it wants."}
```

Save this beside the course page, as `src/routes/(planner)/courses/[id=slug]/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+server.js", "parts": [
 {"code": "// +server.js: a course and all its sessions, as JSON, for a request that does not ask for HTML.\nimport { error, json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET({ params }) {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn json({ course, sessions: sessions.filter((s) => s.course === course.id) });\n}", "note": "Only `GET`. A `POST` that asks for HTML still reaches the page's actions, and `use:enhance` marks its own requests as being for an action."}
]}
```

```
ana@dev:~/planner$ curl -si -H 'Accept: application/json' http://localhost:5173/courses/guitar; echo
HTTP/1.1 200 OK
vary: Accept
content-length: 128
content-type: application/json
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
Date: Sat, 24 Oct 2026 01:13:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"course":{"id":"guitar","name":"Guitar"},"sessions":[{"id":4,"course":"guitar","date":"2026-10-20","minutes":45,"done":false}]}
```

```
ana@dev:~/planner$ curl -s -H 'Accept: text/html' http://localhost:5173/courses/guitar | grep -o '<title>.*</title>'
<title>Guitar · Study planner</title>
```

**The same address, JSON for one and the page for the other.** The first response carries `vary:
Accept`, which SvelteKit adds so that a cache between the two, in the browser or a proxy, keeps the
JSON and the HTML apart instead of handing one to whoever asks for the other.

The page's forms are not affected. They send `POST`s, a browser's own submission prefers HTML, and
`use:enhance` sends a header saying its request is for an action, so both still reach the actions:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,20p
-- fill Date=2026-10-23
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - text: 20 Oct 2026, 45 min
      - 'button "Mark done: 20 Oct 2026"': Mark done
    - listitem:
      - text: 23 Oct 2026, 30 min
      - 'button "Mark done: 23 Oct 2026"': Mark done
```

Whether to share an address is a choice. It keeps one name for one thing, which is pleasant; it also
means the endpoint and the page must agree on what the address means, and a reader of the code has to
know the rule to know which file answers. A separate `/api/…` address, like the previous section's, is
plainer. Both are common.
