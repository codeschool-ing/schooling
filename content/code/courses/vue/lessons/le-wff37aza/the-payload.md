---
title: The payload, what crosses from the server to the browser
version: 1
---

**The payload is the data the server fetched while rendering a page, written into the page as a
`<script>` the browser reads before it hydrates.** It is how `useFetch` on the browser's side finds
its answer without asking, and it is in the HTML of every server-rendered page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"What one visit to the week page does with useFetch. On the server, rendering the page runs useFetch, which calls GET /api/courses inside the server, and the answer is used twice: to draw the HTML, and written into the page as the payload, the __NUXT_DATA__ script. The browser receives the HTML and the payload together, shows the HTML, and when it hydrates, useFetch in the browser finds its answer in the payload under the same key and makes no request. A plain $fetch in setup has no key and no payload, so the browser asks the API a second time.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the server</text><rect x=\"40\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useFetch(...)</text><rect x=\"190\" y=\"62\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/api/courses</text><line x1=\"162\" y1=\"79\" x2=\"188\" y2=\"79\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,79.0 180.6,82.1 180.6,75.9\" fill=\"var(--wire)\"></polygon><rect x=\"40\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">HTML</text><rect x=\"180\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">__NUXT_DATA__</text><line x1=\"100\" y1=\"98\" x2=\"100\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,128.0 96.9,120.6 103.1,120.6\" fill=\"var(--wire)\"></polygon><line x1=\"245\" y1=\"98\" x2=\"240\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"240.0,128.0 238.1,120.2 244.3,121.2\" fill=\"var(--wire)\"></polygon><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the answer, used twice</text><rect x=\"400\" y=\"30\" width=\"300\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the browser</text><rect x=\"420\" y=\"62\" width=\"260\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shows the HTML at once</text><rect x=\"420\" y=\"120\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useFetch(...)</text><text x=\"550\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">finds its key in the payload</text><line x1=\"322\" y1=\"147\" x2=\"418\" y2=\"142\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,142.0 410.8,145.5 410.5,139.3\" fill=\"var(--amber)\"></polygon><line x1=\"322\" y1=\"100\" x2=\"418\" y2=\"79\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,79.0 411.5,83.6 410.1,77.5\" fill=\"var(--phosphor)\"></polygon><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no request: nothing to ask</text></svg>", "caption": "The payload is the server's answer carried inside the page, so the browser does not ask again."}
```

Here it is in the week's HTML:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o '<script type="application/json"[^>]*>'
<script type="application/json" data-nuxt-logs="nuxt-app">
<script type="application/json" data-nuxt-data="nuxt-app" data-ssr="true" id="__NUXT_DATA__">
```

The second one, `__NUXT_DATA__`, is the payload. Its beginning:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | cut -c1-420
id="__NUXT_DATA__">[["ShallowReactive",1],{"data":2,"state":45,"once":47,"_errors":48,"serverRendered":24,"path":50},["ShallowReactive",3],{"session-count":4,"$f7xzspbwcnt2l":5},6,{"courses":6,"sessions":19},[7,11,15],{"id":8,"title":9,"goal":10},"statistics","Statistics",180,{"id":12,"title":13,"goal":14},"spanish","Spanish",120,{"id":16,"title":17,"goal":18},"guitar","Guitar",90,[20,25,29,32,37,41],{"id":21,"course
```

**It is JSON in a format of its own**, written by a library called `devalue`: one array, in which
each value is written once and everything else points at it by position. `{"data":2,…}` means *the
data is item 2*; item 3 maps each key to its item, and the courses come after it. The format can say
what JSON cannot, a `Date`, a `Map`, a ref, and a value used twice is stored once. Look for the two
keys of the last section:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | grep -o '"session-count":-\?[0-9]*\|"\$f[a-z0-9]*":-\?[0-9]*'
"session-count":4
"$f7xzspbwcnt2l":5
"session-count":-1
"$f7xzspbwcnt2l":-1
```

`session-count` is the layout's key, and `$f…` the key `useFetch` made from its URL, each pointing at
the item holding its data; item 4 is `6`, the layout's data, one number, because `transform` ran on the
server before the payload was written. The second pair is the map of errors, and `-1` is how `devalue`
writes `undefined`: neither fetch failed. **Whatever
the handler returns, and only that, is what crosses.**

## The payload is public

The payload is part of the page, so it is readable by anybody who can open the page, with *view
source* or `curl`, and whatever the server fetched while rendering is in it, whether the template
uses it or not. Measure the page, the payload inside it, and the API's own answer:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | wc -c
5081
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'id="__NUXT_DATA__">[^<]*' | wc -c
956
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/api/courses | wc -c
1051
```

**The payload is 956 bytes of the page's 5,081**, smaller than the API's answer of 1,051 because
`devalue` writes each repeated value once, and every value of that answer is in it. For the planner
every byte of the API's answer is meant for the reader. It is a different matter when a server route
returns a whole record, an account with its e-mail and its password hash, and the page shows a name: the
template hides the rest from the screen, and the payload gives it to every visitor. `transform`, or
`pick: ['name']` for the simple case, run on the server and keep such a field out of the payload. They
do not keep it out of the route, which answers anybody who calls `/api/…` directly, with `curl` as here.
**So a server route returns what its callers may see, and nothing else**, and a field that must stay
private stops in the route.
