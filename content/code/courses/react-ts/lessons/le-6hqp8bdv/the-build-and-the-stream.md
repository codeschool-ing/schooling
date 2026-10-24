---
title: The build, and a page that streams
version: 1
---

**The production build is where the boundary becomes files.** Stop the development server and build:

```
ana@dev:~/planner-next$ npm run build

> planner-next@0.1.0 build
> next build

▲ Next.js 16.4.3 (Turbopack)
✓ Running next.config.ts took 35ms
- Cache Components enabled
- Partial Prefetching enabled

  Creating an optimized production build ...
✓ Compiled successfully in 3.1s
  Running TypeScript ...
  Finished TypeScript in 1821ms ...
  Collecting page data using 3 workers ...
  Generating static pages using 3 workers (0/3) ...
✓ Generating static pages using 3 workers (3/3) in 218ms
  Finalizing page optimization ...

Route (app)
┌ ◐ /
└ ○ /_not-found


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

`Running TypeScript` is the check `tsc -b` did in the Vite project, part of the build here. The table
at the end is about Cache Components. `/` is **◐, a partial prerender**: its static shell, the heading
and the *Loading the planner…* fallback, was rendered now, at build time, and the planner itself will
be rendered per request and streamed into it. `/_not-found` is Next.js's 404 page, fully static.

Now the promise from the start of the lesson, checked in the files. `.next/static` is what is sent to
browsers; `.next/server` stays on the server:

```
ana@dev:~/planner-next$ grep -rl 'localhost:3001' .next/static | wc -l
0
ana@dev:~/planner-next$ grep -rl 'ArrowRight' .next/static | wc -l
2
ana@dev:~/planner-next$ grep -rl 'localhost:3001' .next/server | wc -l
2
```

- **The API's address is in no file a browser receives.** It is in `lib/planner.ts`, which only Server
  Components import.
- **`ArrowRight` is**, in two files, because `WeekKeys` is a Client Component.
- The server's files have the address, because that is where the `fetch` runs.

That is the boundary as a deployment sees it, and it is why the `console.log` in `Planner` never
appears in a production browser's console: its code is not there.

**Streaming** is the other half of the ◐. Restart the API with `DELAY=2000`, lesson 11's switch that
makes every answer wait two seconds, and start the production server with `npm start`. Then time a
request for the page:

```
ana@dev:~/planner-next$ curl -s -o /dev/null -w '%{time_starttransfer} %{time_total}\n' 'http://localhost:3000/?week=2026-10-19' | awk '{ printf "first byte after %.1f s, last after %.1f s\n", $1, $2 }'
first byte after 0.0 s, last after 2.0 s
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o 'Loading the planner…' | head -n 1
910:Loading the planner…
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o '80 of 195 minutes done'
7176:80 of 195 minutes done
```

**The first byte arrived at once, and the last after two seconds.** The server did not wait for the API
before it started answering. It sent the static shell straight away, held the connection open, and
sent the planner when the API answered, in the same response. A browser draws the shell, with *Loading
the planner…*, as soon as it arrives, and swaps in the planner when the rest comes.

The two `grep -b` print where in the response each text is, as a byte offset: the fallback at byte 910,
near the start, and the minutes at 7176, near the end, after the two seconds. The fallback was not
replaced in the HTML; the end of the response carries the planner's HTML in a hidden element and a few
lines of script that move it into place. That is `Suspense` on the server: the boundary that lesson 13
used to wait for code now decides **which part of a page may arrive late**.
