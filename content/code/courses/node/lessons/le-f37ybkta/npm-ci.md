---
title: npm ci, the install that deploys
version: 1
---

**`npm install` reads `package.json` and may change the lockfile; `npm ci` reads the lockfile and
refuses to change anything.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two commands and three things on disk. npm install reads package.json, writes package-lock.json and fills node_modules. npm ci reads only package-lock.json, refuses if it does not match package.json, deletes node_modules and installs exactly what the lockfile lists.\"><rect x=\"30\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package.json</text><text x=\"115\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ranges you ask for</text><rect x=\"275\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package-lock.json</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exact versions installed</text><rect x=\"520\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><text x=\"605\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the code that runs</text><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">npm install</text><path d=\"M115 98 C 115 60, 360 60, 360 96\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"360\" y1=\"90\" x2=\"360\" y2=\"97\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,97.0 356.9,89.6 363.1,89.6\" fill=\"var(--amber)\"></polygon><path d=\"M115 98 C 115 40, 605 40, 605 96\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"605\" y1=\"90\" x2=\"605\" y2=\"97\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,97.0 601.9,89.6 608.1,89.6\" fill=\"var(--amber)\"></polygon><text x=\"238\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">writes what it resolved</text><text x=\"480\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fills</text><text x=\"30\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">npm ci</text><path d=\"M360 156 C 360 200, 605 200, 605 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"605\" y1=\"166\" x2=\"605\" y2=\"157\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,157.0 608.1,164.4 601.9,164.4\" fill=\"var(--phosphor)\"></polygon><text x=\"483\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">deletes, then installs exactly this</text><path d=\"M115 156 C 115 196, 360 196, 360 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"238\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">only compares: refuses if they differ</text></svg>", "caption": "On a laptop, npm install changes the lockfile. Where a deployment is built, npm ci reads it and changes nothing."}
```

On your laptop the first is how you add and update. On a build server,
in a container, anywhere a deployment is made, the second is the one to run, because it installs
exactly what was tested and nothing else.

`npm ci` deletes `node_modules` first, whatever is in it, and installs from the lockfile alone:

```
ana@dev:~/server/links$ npm ci

added 66 packages, and audited 67 packages in 484ms

29 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Same 66 packages, the tree recorded in `package-lock.json`, in under a second.

## When the two files disagree

The lockfile must describe what `package.json` asks for. Change a range by hand without installing,
and they no longer match:

```
ana@dev:~/server/links$ npm pkg set dependencies.express='^4.21.0'
ana@dev:~/server/links$ npm ci 2>&1 | head -6
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's express@5.3.0 does not satisfy express@4.22.3
npm error Invalid: lock file's accepts@2.0.0 does not satisfy accepts@1.3.8
ana@dev:~/server/links$ npm pkg set dependencies.express='^5.3.0'
```

**`npm ci` refused, and named the difference.** On a build server that refusal is the point: a
lockfile that does not match its `package.json` means somebody changed one without the other, and
installing anyway would deploy versions nobody tested. The fix is on the laptop, with `npm install`,
and a commit of both files. Here, the change is undone by putting the range back.

## A production install

`--omit=dev` leaves the development tools out, as the section on kinds of dependency showed with
`npm ls`:

```
ana@dev:~/server/links$ npm ci --omit=dev

added 65 packages, and audited 66 packages in 502ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/links$ npm run format

> links@0.1.0 format
> prettier --write server.js src test

sh: 1: prettier: not found
```

One package fewer, Prettier, and `npm run format` would now fail for lack of it, which in production
is the right result. This is the command lesson 10's process managers and the `docker` course's
images are built with.
