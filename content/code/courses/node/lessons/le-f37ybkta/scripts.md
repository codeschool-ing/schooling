---
title: Scripts, the project's own commands
version: 1
---

**`scripts` in `package.json` names the commands a project is run with, so that nobody has to
remember them.** `npm run` with nothing after it lists them:

```
ana@dev:~/server/links$ npm run
Lifecycle scripts included in links@0.1.0:
  start
    node server.js
  test
    node --test --test-reporter=spec
available via `npm run-script`:
  dev
    node --watch server.js
  format
    prettier --write server.js src test
```

`start` and `test` are lifecycle scripts, which npm knows by name: `npm start` and `npm test` run
them without the word `run`. The others need it: `npm run dev`, `npm run format`. **Whoever clones the
project types `npm test` and does not need to know that the tests use Node's own runner** with a
particular reporter; the script is the documentation, and it is always up to date because it is what
runs.

## What a script can see

A script runs in a shell, with two additions to its environment:

- **`node_modules/.bin` is on its `PATH`.** Every package with a command puts it there, so the
  `prettier` in the `format` script is the project's own copy, the exact version in the lockfile, and
  not whatever might be installed elsewhere on the computer.
- **npm sets variables** describing the run and the package, such as `npm_lifecycle_event`, the name
  of the script, and `npm_package_version`.

```
ana@dev:~/server/links$ npm run format

> links@0.1.0 format
> prettier --write server.js src test

server.js 31ms
src/code.js 8ms
test/code.test.js 4ms
```

Prettier rewrote nothing it did not need to and listed what it looked at. Arguments for the command
inside a script go after `--`, so that npm does not read them as its own: `npm test -- --test-only`
hands `--test-only` to `node --test`.

## node --run

Node 22 can run a script itself, without npm, and it starts faster because npm is not loaded first:

```
ana@dev:~/server/links$ npm pkg set scripts.hello='echo hello from $npm_lifecycle_event'
ana@dev:~/server/links$ npm run hello

> links@0.1.0 hello
> echo hello from $npm_lifecycle_event

hello from hello
ana@dev:~/server/links$ node --run hello
hello from
ana@dev:~/server/links$ npm pkg delete scripts.hello
```

Same script, two runners, and the second line printed nothing after `from`. **`node --run` sets none
of npm's variables**, and it does not run the `pre` and `post` scripts npm runs around a script of
the same name. For a script that only calls a program, it is the quicker way; for anything that
relies on what npm adds, `npm run` is the one that works. This course uses `npm`, and the hello script
goes again with `npm pkg delete scripts.hello`.

## dev, and --watch

`npm run dev` starts the server with `node --watch`, which restarts it whenever a file it loaded
changes. It replaces the tools that used to be installed for this, and it is a development
convenience only: in production the process should change when somebody deploys, not when a file is
touched.
