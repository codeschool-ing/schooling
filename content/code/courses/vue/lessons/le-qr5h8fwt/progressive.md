---
title: A page at a time
version: 1
---

**Vue can take over one element of a page that already exists, and leave the rest of it alone.** That
is what Vue's own documentation means by calling it a *progressive* framework, and it is the one thing
on this subject where Vue differs from the other three in the track: React, Angular and Svelte expect
to own the whole page, or at least to be built by their own tools. Vue can be added to a page that a
server already renders, a widget at a time, with no build step at all.

This section does it with no project, to show what the build step was adding.

## The page

Make a folder beside the planner, and copy into it the one file of Vue that runs in a browser as it
is. It came in the planner's `node_modules`, and it is Vue, the template compiler included, as a
single module:

```
ana@dev:~/vue$ mkdir adopt && cd adopt
ana@dev:~/vue/adopt$ cp ../planner/node_modules/vue/dist/vue.esm-browser.prod.js .
ana@dev:~/vue/adopt$ ls
vue.esm-browser.prod.js
```

Then the page. Imagine that the first two elements were already there, written by somebody else, and
that you were asked to add a counter:

```schooling-example
{"language": "html", "file": "index.html", "parts": [
 {"code": "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"utf-8\">\n    <title>Our study group</title>\n  </head>\n  <body>\n    <h1>Our study group</h1>\n    <p>We meet on Thursdays. This paragraph is plain HTML.</p>", "note": "An ordinary page. Nothing here knows about Vue, and nothing will touch it."},
 {"code": "    <div id=\"counter\">\n      <p>{{ minutes }} minutes studied today</p>\n      <button @click=\"minutes += 25\">Add a 25-minute session</button>\n    </div>", "note": "The one element Vue is given. Its contents are the template: the browser parses them as HTML, and Vue compiles them where they stand."},
 {"code": "    <script type=\"module\">\n      import { createApp, ref } from './vue.esm-browser.prod.js'\n\n      createApp({\n        setup() {\n          return { minutes: ref(0) }\n        },\n      }).mount('#counter')\n    </script>\n  </body>\n</html>", "note": "Imported straight from the file beside the page. `setup()` returns what the template may read, which is the long form of what `<script setup>` does for you."}
]}
```

A page opened from disk cannot import a module, so serve the folder. Python comes with Ubuntu, and
this starts a plain web server in **a second terminal**, inside `~/vue/adopt`:

```sh
python3 -m http.server 8000
```

Then click the button twice:

```
ana@dev:~/vue/adopt$ look http://localhost:8000/ --do 'click button' --do 'click button' --text body
-- click button
-- click button
== the text of body
Our study group

We meet on Thursdays. This paragraph is plain HTML.

50 minutes studied today

Add a 25-minute session
```

**The heading and the first paragraph are untouched, and the counter counts.** `ref(0)` is lesson 2's
subject; here it is enough that changing `minutes` changed the paragraph.

## Why projects rarely stay like this

It works, and for a widget on a server-rendered page it is the right tool. For an application it
stops scaling, for three reasons you can see from here:

| without a build | with Vite and `.vue` files |
|---|---|
| the template is compiled in the browser, on every visit, by a build of Vue that carries the compiler | compiled once, on your machine; the browser gets the smaller runtime |
| a component is an object in a `<script>`, with its template in a string or in the page | a component is a file, with its markup, logic and style together |
| a mistake in the template shows up when somebody opens the page | it shows up in the terminal the moment you save, as the setup failures showed |

The size is measurable. The file you copied includes the compiler, and the runtime the planner ships
in lesson 17 does not:

```
ana@dev:~/vue/adopt$ ls -l vue.esm-browser.prod.js ../planner/node_modules/vue/dist/vue.runtime.esm-browser.prod.js
-rw-r--r-- 1 ana ana 113290 Oct 23 19:33 ../planner/node_modules/vue/dist/vue.runtime.esm-browser.prod.js
-rw-r--r-- 1 ana ana 175436 Oct 23 19:33 vue.esm-browser.prod.js
```

**The compiler is 62 kB of the 175**, about a third, sent to every visitor so that their browser can do
work your machine could have done once. Stop the server with Ctrl-C; its terminal shows the two
requests the page made:

```
ana@dev:~/vue/adopt$ python3 -m http.server 8000
127.0.0.1 - - [23/Oct/2026 19:33:54] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 19:33:54] "GET /vue.esm-browser.prod.js HTTP/1.1" 200 -
```

**The rest of the course works in the planner**, with the build, because
that is how Vue applications are written. When you meet a server-rendered page with Vue sprinkled on
it, you will know what you are looking at.
