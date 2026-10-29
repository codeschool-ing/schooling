---
title: Publishing the first version
version: 1
---

**`npm publish` uploads the archive `npm pack` showed to the registry the package's scope points at.**
Which registry that is lives in a project's `.npmrc`, one line, committed with the code because it is an
address and not a secret:

```
ana@dev:~/planner-ui$ echo '@planner:registry=http://127.0.0.1:4873/' > .npmrc
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"npm install in the planner reads the project&#x27;s .npmrc. A package in the @planner scope is fetched from the private registry at 127.0.0.1:4873, which needs the login token kept in ~/.npmrc. Every other package, such as vite, is fetched from the public registry at registry.npmjs.org.\"><rect x=\"20\" y=\"70\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">npm install</text><text x=\"105\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the planner</text><rect x=\"220\" y=\"30\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"232\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@planner/*</text><text x=\"440\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">127.0.0.1:4873</text><rect x=\"220\" y=\"136\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">everything else</text><text x=\"440\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">registry.npmjs.org</text><line x1=\"190\" y1=\"95\" x2=\"218\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,60.0 215.8,67.7 211.0,63.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"190\" y1=\"115\" x2=\"218\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,150.0 211.0,146.2 215.8,142.3\" fill=\"var(--paper-dim)\"></polygon><text x=\"470\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from the project's .npmrc</text><text x=\"470\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">needs the token in ~/.npmrc</text><text x=\"470\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">public, no token</text></svg>", "caption": "One line in the project's .npmrc sends one scope to a private registry; the token that opens it stays in the home folder."}
```

The line says: anything named `@planner/…` lives at this address. Every other package still comes from
the public registry. **This is what stops an internal package being published to the public npm by
mistake**, and what stops `npm install` asking the public registry for a name it should never look for
there, a confusion attackers have used against companies whose internal names leaked.

Build, then publish:

```
ana@dev:~/planner-ui$ npm run build > /dev/null
ana@dev:~/planner-ui$ npm publish 2>&1 | tail -1
+ @planner/ui@0.1.0
ana@dev:~/planner-ui$ npm view @planner/ui versions
0.1.0
ana@dev:~/planner-ui$ npm publish 2>&1 | grep -m1 'npm error'
npm error code E409
```

`+ @planner/ui@0.1.0` is npm's way of saying the version is now in the registry. `npm view` asks the
registry what it holds, which is the check that the publish went where you meant.

## A published version is final

Run `npm publish` again and it fails, as the last command showed, with `E409`, HTTP's code for a conflict: the version exists. **A version, once published, is never
replaced**; the public registry forbids reusing a version number even after an unpublish. That rule is the
reason a version means anything: whoever installed `0.1.0` today gets the same files as whoever installs it
in a year. A mistake in `0.1.0` is fixed by publishing `0.1.1`.

Commit what the library has so far:

```
ana@dev:~/planner-ui$ git add . && git commit -qm "The planner's UI library, 0.1.0"
```
