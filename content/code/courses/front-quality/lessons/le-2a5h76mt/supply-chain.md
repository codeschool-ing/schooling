---
title: The code you did not write
version: 1
---

**Every package in `node_modules` that reaches the browser runs with the page's rights, and every one
that runs in the build or the tests runs with yours.** The planner's own code is a few hundred lines; the
code it installed is far more:

```
ana@dev:~/planner$ npm ls --all --parseable | wc -l
114
```

**114 packages, for an app that ships one 3 kB script.** Almost all of them are tools that never
reach the browser, Vite, Vitest, Playwright and what they depend on, and they run on your computer every
time you type `npm test`. A Software Supply Chain Failure, A03 of the 2025 list, is any of them being
vulnerable or replaced by somebody else's code.

Three things the planner already does about it, and one command:

- **Exact versions and a lockfile.** `package.json` names exact versions and `package-lock.json` names
  every package below them, with a hash of each. `npm ci` installs exactly that, so a release published
  tomorrow does not arrive in your project unasked.
- **Integrity hashes.** Each entry in the lockfile carries the hash of the file npm downloaded; a copy
  that differs by one byte is refused at install.
- **Signatures.** The npm registry signs what it serves, and npm can check every installed package
  against those signatures with one command:

```sh
npm audit signatures
```

*That command was not run where this course was recorded.* It fetches the keys it checks against from
Sigstore's servers, and the recording machine was refused there; on your machine it prints how many
packages had verified signatures, and names any that did not.

And **known vulnerabilities**: `npm audit` compares every installed version with the advisories published
for it.

```
ana@dev:~/planner$ npm audit
found 0 vulnerabilities
```

**Nothing known, today.** That sentence has a date on it: a package that is clean now can have an advisory
next month, which is why `npm audit` belongs in the checks a project runs on every pull request, not in a
course's transcript.

## For a script loaded from somewhere else

A page that loads a script from a CDN instead of from its own build can make the browser check it, with
**Subresource Integrity**: an `integrity="sha384-…"` attribute on the `<script>` tag, the hash of the
file the page expects. If the CDN ever serves something else, the browser refuses it. The planner loads
nothing from anywhere else, which lesson 8's `script-src 'self'` would refuse anyway, and that is the
strongest version of the same idea.
