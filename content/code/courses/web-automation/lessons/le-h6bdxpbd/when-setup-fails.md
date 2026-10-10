---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over a screenful of output
that looks like a catastrophe and turns out to be one small thing. These are the failures that come
up while following the last two sections, each with what it prints and what fixes it. Every one of
them was produced on purpose, on the machine the transcripts come from.

**Read an error from the line that names the problem, not from the top.** Node and npm both print
a lot of context around the one sentence that matters, and in each case below that sentence is
quoted so you can find it.

## `address already in use`

The shop is already running in another terminal, or a test run left one behind, and a second
`npm start` tries to take the same port:

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 0.0.0.0:3000
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at Server.listen (node:net:2102:7)
    at file:///home/ana/quitanda/app/server.js:69:4
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '0.0.0.0',
  port: 3000
}

Node.js v22.22.0
```

`EADDRINUSE` means **another program already holds port 3000**; the lines around it are
Node saying where in its own code it noticed. Find the terminal where the shop is running and stop
it with Ctrl+C. If you cannot find one, a test run is the usual culprit: Playwright's `webServer`
stops the server it started, but a run you interrupted halfway may not have.

## `Executable doesn't exist`

Playwright is installed and its browsers are not:

```
ana@laptop:~/quitanda$ npx playwright test

Running 1 test using 1 worker

  ✘  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (4ms)


  1) tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ───────────────────────────────────
```

The box says what to do, and it is right: `npx playwright install chromium` downloads the build
this version expects. The path above it is worth reading too, because it tells you **which
browser build** Playwright looked for. When you upgrade Playwright, the build number in that path
changes, and the browsers you downloaded for the old version no longer count.

## `Could not read package.json`

`npm start` run from the wrong folder:

```
ana@laptop:~$ npm start
npm error code ENOENT
npm error syscall open
npm error path /home/ana/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-10T07_07_06_918Z-debug-0.log
```

npm looks for `package.json` in the folder you are in, and the path it names, `/home/ana`, is the
home directory rather than the project. `cd ~/quitanda` and run it again. The `debug-0.log` it
mentions holds nothing more useful than the lines above it.

## `Invalid package.json`

The project's `package.json` with one comma too many after the `"test"` line, which is what
happens when a line is deleted by hand from a list:

```
ana@laptop:~/quitanda$ npm start
npm error code EJSONPARSE
npm error JSON.parse Invalid package.json: JSONParseError: Expected double-quoted property name in JSON at position 146 (line 8 column 3) while parsing near "...playwright test\",\n  },\n  \"devDependencie..."
npm error JSON.parse Failed to parse JSON data.
npm error JSON.parse Note: package.json must be actual JSON, not just JavaScript.
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-10T07_07_07_057Z-debug-0.log
```

JSON does not allow a comma after the last item of an object, though JavaScript does, which is
what the last error line is hinting at. **The position tells you where to look**: line 8,
column 3, where the parser found a `}` when it expected another name. The mistake itself is on
the line before.

## A warning about the module type

Not every message stops the shop. Here `"type": "module"` was left out of `package.json`, and the
server starts anyway:

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

(node:4221) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/quitanda/app/server.js is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/quitanda/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
quitanda is listening on http://localhost:3000
```

Node 22 guesses, notices the file uses `import`, and reads it again as a module. It works, and the
warning says how to stop the guessing: put the line back. Leave it out and the guess happens on
every start, for every file, and a later tool that does not guess will fail where Node did not.

## A version of Node that is too old

If `node --version` prints anything below `v22`, the tools in this course may fail in ways that
look unrelated to the version. On Windows, `where node` lists every `node` on your path, in the
order they are found; on macOS and Linux, `which -a node` does the same. The first one listed is
the one that answers. Uninstall the old one, or reinstall Node from nodejs.org so the new one comes
first. This failure was not reproduced for the transcripts, because the machine they come from has
only the one Node.

## When it is none of these

Two things narrow down almost anything else. Run `npm start` on its own and open
`http://localhost:3000`: if the shop does not open in your own browser, the problem is in the
application or its files, and the tests have nothing to do with it. If it opens and the test still
fails, compare your files with the blocks in the last two sections. Copying with the button on each
block avoids most of these; a file saved in the wrong folder causes most of the rest.
