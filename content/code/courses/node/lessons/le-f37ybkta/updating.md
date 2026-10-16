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
