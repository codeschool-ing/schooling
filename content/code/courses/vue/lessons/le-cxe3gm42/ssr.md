---
title: Server-side rendering, and hydration
version: 1
---

**A Nuxt page is rendered on the server first: the server runs the page's components, turns what they
draw into HTML, and sends that.** The browser shows the HTML at once, then downloads the same
components, runs them, and attaches them to the elements already on the screen instead of drawing new
ones. The second half is called **hydration**, and after it the page is an ordinary Vue application,
the same as the Vite planner's. Start the Nuxt dev server again and look at the week with JavaScript
turned off:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --no-js --text 'main section:nth-child(3)'
== the text of main section:nth-child(3)
Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
75 of 195 minutes done
```

**The whole week, totals included, with no script run at all.** The server called `useFetch`, which
asked `/api/courses` without leaving the server, ran `weekTotal`, rendered the rows, and sent the
result. What a page without JavaScript cannot do is anything that needs Vue to listen:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --no-js --do 'check label:has-text("21 October") input' --do 'goto /' --text 'main section:nth-child(3) footer'
-- check label:has-text("21 October") input
-- goto /
== the text of main section:nth-child(3) footer
75 of 195 minutes done
```

The box was ticked, because a checkbox ticks itself, and nothing told the server; the page loaded
again still says 75. The `@change` that sends the `PATCH` is attached by hydration, and until hydration
has happened a page *looks* finished and is not. That gap is the price of rendering on the server:
the reader sees the page sooner, and can click on it before it can answer. On a slow phone it can be
a second or two.

## The page and what follows it

With JavaScript, the browser makes these requests, apart from the modules of Nuxt and Vue:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep -v '^net  GET /_nuxt/@' | grep -c '^net'
20
```

A development server is no place to count requests, though, as lesson 17 showed with Vite's. Stop it
and build the planner the way it would be deployed:

```
ana@dev:~/vue/planner-nuxt$ npm run build 2>&1 | tail -3
[nitro] ✔ You can preview this build using node .output/server/index.mjs
config 301ms · modules 62ms · app 409ms · types 404ms · client 974ms · server 419ms · nitro 3.80s
◆ ✨ Build complete in 6.37s!
```

The result is `.output`, and it is very different from the Vite planner's `dist`:

```
ana@dev:~/vue/planner-nuxt$ du -sh .output
3.1M	.output
ana@dev:~/vue/planner-nuxt$ ls .output .output/server/node_modules
.output:
nitro.json
public
server

.output/server/node_modules:
@babel
@vue
devalue
entities
estree-walker
fnv1a-64
hookable
nostics
object-identity
source-map-js
ufo
unhead
vue
vue-bundle-renderer
vue-router
```

**`public` is what the browser downloads, and `server` is a program**, Nitro with the planner's pages
and API routes compiled into it, and the packages it needs at run time copied beside it, fifteen entries
of a small `node_modules`. `node-forge` is not among them: the advisory of lesson 18 was in the dev
server's tooling and never reaches a build. Run it:

```
ana@dev:~/vue/planner-nuxt$ node .output/server/index.mjs
Listening on http://0.0.0.0:3000
```

**`0.0.0.0` means every network the computer is on**, not only `localhost`, which is what a server
behind a host's proxy needs, and also why lesson 18's endpoints, which ask nobody who they are, must not
run like this on a computer anyone else can reach. The week page, from the built server:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep '^net'
net  GET /  200
net  GET /_nuxt/entry.DM7gLlzw.css  200
net  GET /_nuxt/DqJQdDDH.js  200
net  GET /_nuxt/P0c8VxyF.js  200
net  GET /_nuxt/D5BqGcD9.js  200
net  GET /_nuxt/VuPL-ScY.js  200
net  GET /_nuxt/Ay1E5qCJ.js  200
net  GET /_nuxt/fetch.B5cEvZ0E.css  200
net  GET /_nuxt/pages.B5v9DPLB.css  200
net  GET /_nuxt/default.CF8CboJV.css  200
net  GET /_nuxt/DIj-9ZNw.js  200
```

**Eleven requests, and none of them is `/api/courses`.** The page arrived with its data inside it: the
server sent what `useFetch` received along with the HTML, so the browser's copy of the page could
hydrate with the same data without asking for it again. That copy is the *payload*, and lesson 20 is
about it. The rest is the stylesheets and the chunks of the code, a few more than the Vite build's
four because Nuxt splits the layout, the page and its own runtime apart.
