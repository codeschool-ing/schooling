---
title: What production needs, and what only you need
version: 1
---

**A dependency is either something the server runs, or something only the people working on it
run.** npm keeps the two in separate fields, and that separation is what lets a production install
leave the second kind out:

| field | what goes in it | installed in production? |
|---|---|---|
| `dependencies` | what the code imports when it runs: Express | yes |
| `devDependencies` | tools for working on it: a formatter, a linter, a test helper | no |
| `peerDependencies` | for a library: "I work with the copy of X that you have" | a server rarely declares one |
| `optionalDependencies` | something used if it installs, skipped if it fails | yes, if it can |

The project's one development tool is **Prettier**, which formats code so that nobody argues about
spaces. It has no dependencies of its own, which makes it a clean example:

```
ana@dev:~/server/links$ npm install --save-dev --save-exact prettier@3.9.10

added 1 package, and audited 67 packages in 373ms

29 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/links$ npm pkg get dependencies devDependencies
{
  "dependencies": {
    "express": "^5.3.0"
  },
  "devDependencies": {
    "prettier": "3.9.10"
  }
}
```

`--save-dev` put it under `devDependencies`. **`--save-exact` recorded `3.9.10` with no caret**,
which is right for a formatter: a new minor version may format the same file differently, and a
reformatted file in a pull request that changed nothing else is noise. For a library the server
imports, the caret and the lockfile together are the usual arrangement; for a tool whose output is
compared byte for byte, the exact version is.

## What production installs

`--omit=dev` installs, or lists, without the development half:

```
ana@dev:~/server/links$ npm ls --omit=dev
links@0.1.0 /home/ana/server/links
└── express@5.3.0
```

The production tree has Express and not Prettier. **A server deployed with development tools inside
it** carries code it never runs, and every package it carries is one more that a security advisory
can name; the section on `npm ci` installs a production copy this way.

A package in the wrong field fails in the other direction too. Something your code imports, put under
`devDependencies` by mistake, works on your laptop, where everything is installed, and fails in
production with `ERR_MODULE_NOT_FOUND` on the first request that reaches the import. That is one more
reason lesson 3's rule matters: with `import` statements at the top of every file, the missing package
stops the server at start-up rather than at three in the morning.
