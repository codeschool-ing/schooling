---
title: NODE_ENV
version: 1
---

**`NODE_ENV` is a convention, not a feature of Node**: Node itself ignores it. Libraries read it, and
by long agreement the one value that means something is `production`. Lesson 6 showed what it changes
in Express — the default error page stops printing the stack trace — and it changes two more things
worth knowing:

| who reads it | what `NODE_ENV=production` changes |
|---|---|
| Express | errors answer `Internal Server Error` with no stack; templates, if any, are cached |
| npm | `npm install` and `npm ci` leave out `devDependencies`, as `--omit=dev` does |
| many libraries | quieter logs, fewer checks that cost time |

The second row is the surprise: a build that sets `NODE_ENV=production` before installing gets no
test runner and no formatter, and a build step that needed one fails. Install first, with the dev
tools, and set `NODE_ENV` for running.

## Production or not, and nothing else

The convention works because it has two positions. **Code that branches on `NODE_ENV` in many places**
— a different timeout here, a skipped check there — has two programs, and the one in production is
the one that was not run on a laptop. The rule in this course is that `NODE_ENV` means "is this
production?" and nothing more, read in one place:

```javascript
production: env.NODE_ENV === "production",
```

That line from `config.js` is the only read. Values like `staging` or `qa` look tidy and break the
convention: every library that checks `=== "production"` treats them as development, stack traces
included. A staging server runs with `NODE_ENV=production` and differs from production only in its
other variables.
