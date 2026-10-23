---
title: overrides, and engines
version: 1
---

Two fields of `package.json` that you will need rarely, and need badly when you do.

## overrides: a version you choose for somebody else's dependency

Sometimes a fix exists for a package deep in your tree, and the package that depends on it has not
yet released a version that uses it. **`overrides` replaces the version npm would choose for a
package, wherever it appears in the tree.** In the scratch project of the previous section, put
Express back at 4.17.1, which pins `qs` to exactly 6.7.0, and override `qs` to the newest:

```
ana@dev:~/server/audited$ npm install --save-exact express@4.17.1

removed 18 packages, changed 23 packages, and audited 51 packages in 536ms

1 package is looking for funding
  run `npm fund` for details

7 vulnerabilities (3 low, 4 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/server/audited$ npm pkg set overrides.qs=6.16.1
ana@dev:~/server/audited$ npm install

added 18 packages, changed 1 package, and audited 69 packages in 457ms

12 packages are looking for funding
  run `npm fund` for details

6 vulnerabilities (3 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/server/audited$ npm ls qs
audited@ /home/ana/server/audited
└─┬ express@4.17.1
  ├─┬ body-parser@1.19.0
  │ └── qs@6.16.1 deduped
  └── qs@6.16.1 overridden

ana@dev:~/server/audited$ npm audit | grep -E '^[a-z-]+  '
body-parser  <=1.20.5
cookie  <0.7.0
path-to-regexp  <=0.1.12
send  <0.19.0
```

`npm pkg set` wrote the override into `package.json`:

```json
{
  "overrides": {
    "qs": "6.16.1"
  }
}
```

and after the install, `npm ls` marks the copy it chose, and `npm audit` no longer lists `qs`.
**An override is a promise you make on behalf of another package's author**: that their code works
with a version they never tested. Run the tests, write down why the override is there, and remove it
when the parent catches up. Left in place, it is a version nobody updates on purpose.

## engines: the Node a project runs on

The `links` project says `"engines": { "node": ">=22" }`. On its own that is a statement, and npm only
warns when it is not met. With **`engine-strict`** set in the project's `.npmrc`, npm refuses to
install on any other Node. To see it refuse, ask for a Node this machine does not have, in a scratch
copy:

```
ana@dev:~/server/strict$ echo '{ "name": "strict", "private": true, "engines": { "node": ">=24" } }' > package.json
ana@dev:~/server/strict$ echo engine-strict=true > .npmrc
ana@dev:~/server/strict$ npm install express@5.3.0
npm error code EBADENGINE
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: undefined
npm error notsup Not compatible with your version of node/npm: undefined
npm error notsup Required: {"node":">=24"}
npm error notsup Actual:   {"npm":"10.9.4","node":"v22.22.0"}
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-16T22_55_33_823Z-debug-0.log
```

**`EBADENGINE` is the refusal**, and it names both versions. For a server that is worth having: a
build server with the wrong Node fails at install, with a message, instead of at the first request
that uses something the old Node does not have. Put `engine-strict=true` in the `.npmrc` of `links`
too, beside the lockfile, and the project's own `>=22` is held from then on.
