---
title: A site in a folder, and the base path
version: 1
---

**A site served from a folder instead of from the root of its address needs to be built knowing the
folder's name.** This is the difference between the four hosts that breaks the most first deploys, and
GitHub Pages is where people meet it. A repository called `planner` is published at
`https://<user>.github.io/planner/`, not at the root of a domain, and a build made for `/` is broken
there in a way that looks like nothing at all: a blank page, and no error on it.

## Broken, on purpose

A static host serving a folder is easy to stand in for: put the build inside a folder called
`planner`, and serve the folder above it. Build as before, copy, and start `host.mjs` on the new root:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ rm -rf site && mkdir site && cp -r dist site/planner
ana@dev:~/planner$ grep -o 'src="[^"]*"' site/planner/index.html
src="/assets/index-BVi82VJx.js"
```

Then ask for the page, and for the script the page names, the way a browser would:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/
200
ana@dev:~/planner$ js=$(grep -o '/assets/[^"]*\.js' site/planner/index.html); echo $js
/assets/index-BVi82VJx.js
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:8080$js"
404
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A site published in the folder planner of its address. The folder holds index.html and assets. A page built for the root asks for /assets/index.js, which resolves from the root of the address, outside the folder, where there is nothing: 404. Built with base /planner/, it asks for /planner/assets/index.js, inside the folder: 200.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">https://ana.github.io/</text><rect x=\"20\" y=\"40\" width=\"340\" height=\"170\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the root of the address</text><rect x=\"130\" y=\"80\" width=\"210\" height=\"115\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">planner/</text><text x=\"150\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index.html</text><text x=\"150\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">assets/index.js</text><text x=\"150\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses.json</text><text x=\"72\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nothing</text><text x=\"72\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">here</text><text x=\"390\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">built for /</text><text x=\"390\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">src=\"/assets/index.js\"</text><path d=\"M 385 112 C 350 55, 60 50, 72 126\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"548\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">404</text><text x=\"390\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">built with base /planner/</text><text x=\"390\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">src=\"/planner/assets/index.js\"</text><line x1=\"388\" y1=\"172\" x2=\"344\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"344.0,150.0 352.0,150.5 349.2,156.1\" fill=\"var(--phosphor)\"></polygon><text x=\"592\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text></svg>", "caption": "A path that starts with / is resolved from the root of the address, so a site in a folder has to be built with the folder's name."}
```

**The page is found and the script is not.** `index.html` says `src="/assets/…"`, and a path that starts
with `/` is resolved from the root of the address, so the browser asks for `/assets/…` and not for
`/planner/assets/…`. In the browser you get a blank page; the console says the script failed to load,
and nothing on the page says anything. The host's log says exactly which request missed:

```
ana@dev:~/planner$ node host.mjs site
serving site on http://127.0.0.1:8080
200 GET /planner/
404 GET /assets/index-BVi82VJx.js
```

## Built for the folder

Vite's `base` option is the path the site will be served from, and it changes three things at once:
the paths the build writes into `index.html`, the value of `import.meta.env.BASE_URL` that every link
and the `fetch` in the planner start with, and nothing else. Pass it on the command line:

```
ana@dev:~/planner$ npm run build -- --base=/planner/ > /dev/null
ana@dev:~/planner$ rm -rf site && mkdir site && cp -r dist site/planner
ana@dev:~/planner$ grep -o 'src="[^"]*"' site/planner/index.html
src="/planner/assets/index-Cch1FzyD.js"
ana@dev:~/planner$ js=$(grep -o '/planner/assets/[^"]*\.js' site/planner/index.html)
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:8080$js"
200
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/courses.json
200
```

The `--` hands what follows to the script rather than to `npm`. Now the page names
`/planner/assets/…`, the script is found, and the data the script fetches is found too, because
`main.ts` asks for `${base}courses.json`. Open `http://127.0.0.1:8080/planner/` in your browser and the
planner works, with links to `/planner/course/git` and the rest.

## On the command line, or in the configuration

Vite's guide sets `base` in `vite.config.ts`. That is right when the site lives in one place. The
planner may be served from `/planner/` by GitHub Pages and from `/` by the other three, so this course
keeps the default in the project and **puts `--base` where the deploy is decided**, in the GitHub Pages
workflow of the previous section. A build for one host then cannot leak into another.

Two things `base` does not fix, and both are lesson 4:

- **a path the app built by hand without it.** A `fetch("/courses.json")` or an `href="/course/git"`
  written as a literal ignores `base` and breaks in the folder. The planner has none, because every
  path in it starts with `import.meta.env.BASE_URL`; a search for `"/` in `src/` finds any that slip in.
- **an address typed or bookmarked.** Opened from its own link, `/planner/course/git` works, because the
  app drew it. Typed into the address bar, or reloaded, it is a request to the host for a file called
  `course/git`, and there is none:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/course/git
404
ana@dev:~/planner$ rm -rf site
```

That 404 is the same on every static host until it is told otherwise, and each one is told in its own
way. Lesson 4 tells all four. The `site` folder was only a stand-in for the host; the last command
removed it, and the next build without `--base` writes the `/` version again.
