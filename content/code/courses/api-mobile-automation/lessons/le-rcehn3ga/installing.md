---
title: Newman, installed into the project
version: 1
---

**Newman is a Node program that runs a Postman collection from the command line**, with the same
scripts and the same variable rules as the app. Lesson 5 already used it, fetched by `npx` into a
cache on each machine. That is fine for trying it and wrong for a project. The version lived only in
a command somebody typed, and a teammate, or a pipeline, would have had to type the same one. **A
project names its tools in a file**, so that anyone who checks it out gets the same ones.

For a Node program that file is `package.json`. boxoffice has never needed one, because it uses
nothing but Node's own modules. Newman is the first package the project depends on, so create the
file now, in `~/boxoffice`, with npm's defaults:

```
ana@laptop:~/boxoffice$ npm init -y
Wrote to /home/ana/boxoffice/package.json:

{
  "name": "boxoffice",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

`-y` answers every question npm would ask with its default, and the name comes from the directory.
Then install Newman:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact newman@6.2.3
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 148 packages, and audited 149 packages in 3s

21 packages are looking for funding
  run `npm fund` for details

19 vulnerabilities (8 moderate, 10 high, 1 critical)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Three things happened, and the transcript shows all of them:

- `node_modules/` now holds Newman and the packages it needs, 148 of them.
- `package.json` gained a `devDependencies` entry for `newman`. *Dev* means a tool for working on the
  project, not a part of what it ships; boxoffice itself still depends on nothing. `--save-exact`
  writes `6.2.3` rather than `^6.2.3`, which would let a later install pick up any 6.x.
- `package-lock.json` appeared. It records the exact version of every one of those packages, so a
  later `npm ci` reproduces this tree to the byte instead of resolving it again.

## The warnings, read rather than skipped

The `npm warn deprecated` lines are the same four lesson 5 met. The last lines are new: **npm
audited the tree and found 19 vulnerabilities, one of them critical.** That deserves a look before
it is dismissed, and the obvious remedy deserves a closer one:

```
ana@laptop:~/boxoffice$ npm audit | grep -m1 'Will install'
Will install newman@4.6.1, which is a breaking change
```

`npm audit fix --force` would replace Newman 6.2.3 with 4.6.1, two major versions older. The
vulnerabilities are in libraries Newman 6.2.3 depends on, and the only remedy npm can compute is an
older Newman whose tree it does not flag. Taking it would swap the tool the whole course was recorded
with for an old one, to silence a report about code that runs only on your own machines.

What a tester does instead is weigh where the code runs. Newman here is a dev dependency: it runs on
your machine and in your pipeline, against a server you started, reading a collection you wrote. It
never reaches a user. **So the finding is recorded, the version stays pinned, and the next Newman
release is checked for a fix.** That is a decision, where ignoring red text would be a habit. A
dependency that shipped inside boxoffice, answering requests from strangers, would get a different
answer.

## A name for the run

`npm init` wrote a `test` script that only prints an error. Open `package.json`, replace the
`scripts` entry with one called `test:api`, and save it as `package.json`:

```json
{
  "name": "boxoffice",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test:api": "newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "newman": "6.2.3"
  }
}
```

The script is the command lesson 5 typed, without `npx`. Inside an npm script, the programs in
`node_modules/.bin` are on the path, so `newman` is the one this project installed. Ask it which it
is:

```
ana@laptop:~/boxoffice$ npx newman --version
6.2.3
```

`npx newman` finds the local one too, now that there is one. From here on the run has a name,
`npm run test:api`, and it means the same thing on every machine that has this `package.json` and
this `package-lock.json`.

## What git should not keep

Lesson 3 made `~/boxoffice` a git repository and gave it a `.gitignore` for `.env`. `node_modules/`
belongs there too: 148 packages that `npm ci` rebuilds exactly from the lock file. So do the files a
run leaves behind, which section 05 and section 06 create. Replace the file, and save it as `.gitignore`:

```
# Secrets live in .env, on this machine only.
.env
# Installed by npm from package-lock.json, never committed.
node_modules/
# What a run leaves behind.
results/
boxoffice.log
```

`package.json` and `package-lock.json` are committed; `node_modules/` never is. Section 06 relies on
both halves of that.
