---
title: Keeping dependencies current
version: 1
---

**A dependency that is never updated becomes a dependency with a known hole in it**, and the longer it
waits, the bigger the jump when somebody finally has to make it. Updating is routine work, done in
small steps, and npm has one command to see where you stand and one to move.

To have something to update, make a scratch project next to `links` that pins Express to an older
release, 5.1.0, and has a range that allows newer ones:

```
ana@dev:~/server/older$ echo '{ "name": "older", "private": true }' > package.json
ana@dev:~/server/older$ npm install express@5.1.0

added 68 packages, and audited 69 packages in 939ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/older$ npm outdated; echo "exit code $?"
Package  Current  Wanted  Latest  Location              Depended by
express    5.1.0   5.3.0   5.3.0  node_modules/express  older
exit code 1
```

## outdated

`npm outdated` compares three versions of each direct dependency:

| column | meaning |
|---|---|
| Current | what is in `node_modules` now |
| Wanted | the newest that `package.json`'s range accepts |
| Latest | the newest published, whatever the range |

Current 5.1.0, Wanted and Latest 5.3.0: the range `^5.1.0` already allows the newest, so the update
is a minor one, which semantic versioning promises will not break you. **npm exits with code 1 when
anything is outdated**, which is why a script can use it as a check.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A line of Express versions from 5.0.0 to 6.0.0 and beyond. The range ^5.1.0 covers 5.1.0 up to, but not including, 6.0.0. Current is 5.1.0, what node_modules holds; Wanted and Latest are both 5.3.0, the newest the range accepts. A 6.0.0, if one were published, would be Latest and outside the range, and npm update would not move to it.\"><line x1=\"30\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,110.0 692.6,113.1 692.6,106.9\" fill=\"var(--wire)\"></polygon><line x1=\"60\" y1=\"104\" x2=\"60\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.0.0</text><line x1=\"170\" y1=\"104\" x2=\"170\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"170\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.1.0</text><line x1=\"280\" y1=\"104\" x2=\"280\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"280\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.2.0</text><line x1=\"390\" y1=\"104\" x2=\"390\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.3.0</text><line x1=\"560\" y1=\"104\" x2=\"560\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">6.0.0</text><rect x=\"170\" y=\"78\" width=\"385\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">^5.1.0</text><text x=\"170\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Current</text><line x1=\"170\" y1=\"66\" x2=\"170\" y2=\"76\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Wanted = Latest</text><line x1=\"390\" y1=\"66\" x2=\"390\" y2=\"76\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a new major: outside the range</text><text x=\"560\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">npm update leaves it alone</text><text x=\"280\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">npm update moves here</text></svg>", "caption": "A caret range accepts every minor and patch release of its major, and nothing past it."}
```

## update

`npm update` moves every dependency to its Wanted version, rewrites the lockfile, and leaves
`package.json`'s ranges as they are:

```
ana@dev:~/server/older$ npm update

removed 3 packages, changed 3 packages, and audited 66 packages in 585ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/older$ npm ls
older@ /home/ana/server/older
└── express@5.3.0
```

## A major version is a decision

When Latest is a new major — Express 4 to 5, say — `npm update` does nothing, because the range does
not allow it, and that is correct. **A major version is the author telling you something will
break.** Express publishes a migration guide for 4 to 5, and lessons 6 and 7 point at the changes
that matter in a server: the route path syntax, errors from `async` handlers, `req.body` when nothing
was sent. The way through is the same for any package: read what the new major changed, install it
with `npm install express@5`, run the tests, and fix what they find.

Small and often is the habit. A project that moves one minor version a month never faces the
afternoon of moving four majors at once, which is the afternoon the next section's audit tends to
force.
