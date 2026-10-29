---
title: The deep link, and the server that hid it
version: 1
---

**An app whose addresses are real paths needs the host to answer every one of those paths with
`index.html`, and the development tools hide that need until the first deploy.** Lesson 1 ended on it: a
link clicked inside the planner works, because the app draws the screen; the same address typed or
reloaded is a request to the host for a file called `course/git`, and there is none.

## Two servers, two answers

Ask Vite's preview server and the planner's host for the same address:

```
ana@dev:~/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4173/course/git
200
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/course/git
404
```

**The preview server answered 200 and the host 404.** `vite preview` treats the project as a single-page
app and answers any path it has no file for with `index.html`, which is convenient and is exactly why it
is not a production server: it forgives a mistake that every static host will punish. A site checked
only with `npm run preview` is a site whose deep links have never been tested.

## A rewrite

The fix is a rule with status 200, a rewrite: for any path, serve `/index.html`, at the same address.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two answers to a request for /course/git. A redirect answers 301 with a new location, and the browser asks again at another address, which changes the address bar. A rewrite answers 200 with the contents of index.html at the same address, and the app reads the address and draws the course.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a redirect</text><rect x=\"20\" y=\"52\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /course/git</text><line x1=\"180\" y1=\"70\" x2=\"260\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,70.0 252.6,73.1 252.6,66.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"262\" y=\"52\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">301</text><text x=\"320\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">location: /</text><text x=\"480\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the address bar changes</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a rewrite</text><rect x=\"20\" y=\"132\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /course/git</text><line x1=\"180\" y1=\"150\" x2=\"260\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,150.0 252.6,153.1 252.6,146.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"262\" y=\"132\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">200</text><text x=\"320\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.html</text><text x=\"480\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same address, the app draws the course</text></svg>", "caption": "A redirect sends the browser elsewhere; a rewrite serves another file where the browser already is."}
```

Add it below the redirect, because the first rule that matches decides and `/*` matches everything:

```
ana@dev:~/planner$ echo '/* /index.html 200' >> public/_redirects
ana@dev:~/planner$ cat public/_redirects
# public/_redirects
/courses/* /course/:splat 301
/* /index.html 200
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/git
200 text/html; charset=utf-8
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/nothing
200 text/html; charset=utf-8
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/assets/nothing.js
200 text/html; charset=utf-8
```

The host was still running and needed no restart: it reads the rules on every request. Now
`/course/git` is a 200 with the page, the browser runs the planner's script, and the script reads the
address and draws the course. Reload works, a bookmark works, a link pasted into a chat works.

## The two prices of a catch-all

The last line of that transcript is the first price. `/assets/nothing.js` does not exist, and the rule
answered it with the page, as HTML, with a 200. **A missing script now looks like a page to every tool
that checks status codes**, and the browser that asked for a script and got HTML refuses to run it,
with an error about the MIME type rather than about a missing file. That error is what a visitor gets
when a stale `index.html` asks for scripts from an earlier build, which lesson 1 called the reason a
release is the whole folder at once.

The second price is the planner's own *Not found* screen. `/course/nothing` is also a 200 now, because
the host cannot know which courses exist; only the app can, and it draws *Not found* on a page the
server called a success. That is called a **soft 404**: right for a person, wrong for a crawler or a
monitor that reads status codes. For an app like this one it is the accepted trade, and it is worth
knowing it was made.

## A host with no rules

GitHub Pages reads no rules file, so it cannot rewrite. What it does do is serve the site's `404.html`
for any path it has no file for. A copy of `index.html` saved as `404.html` is therefore the app, served
for every unknown path, with the status 404. Make a copy of the build the way GitHub Pages would hold it,
without the rules file it would ignore, serve it with `node host.mjs /tmp/pages 8081` in another terminal,
and ask for a course:

```
ana@dev:~/planner$ rm -rf /tmp/pages && cp -r dist /tmp/pages && rm /tmp/pages/_redirects
ana@dev:~/planner$ cp /tmp/pages/index.html /tmp/pages/404.html
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{size_download}\n' http://127.0.0.1:8081/course/git
404 482
ana@dev:~/planner$ wc -c < /tmp/pages/index.html
482
```

The page arrives whole, the same bytes as `index.html`, and the planner draws the course. The status is
404, on every deep link. A person never notices; a search engine treats every one of those pages as
missing, and a link checker reports the whole site broken. It is the standard workaround for GitHub
Pages and it is a workaround: an app that needs its deep links indexed belongs on a host with rules, or
on hash addresses such as `#/course/git`, which never reach the server at all.
