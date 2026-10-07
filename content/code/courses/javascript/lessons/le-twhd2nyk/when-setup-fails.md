---
title: When the setup fails
version: 2
---

**Every failure below was met for real while this course was being set up, and each message says
exactly what is wrong once you know how to read it.** They come in the order you would meet them:
installing Node, running `page`, and then running your first files. This section is for the moment
something does not work, so it shows each message before explaining it.

## `node: command not found`

The last line of the install, before the terminal was closed:

```
ana@dev:~$ node --version
bash: line 13: node: command not found
```

The shell looked for a program called `node` in every folder on its `PATH` and found none. **A
terminal reads its `PATH` once, when it opens**, so a terminal opened before `~/.local/bin` existed
never looks there. Open a new terminal before changing anything else; on a desktop, log out and in
again if a new window still says the same. If it persists, `ls ~/.local/bin` should list `node`,
`npm` and `npx`, and an empty answer means the `ln` line has not run.

Ubuntu's own terminal may answer instead with a suggestion to `sudo apt install nodejs`. **Do not
take it**, for the reason in the next section but one.

## `cannot execute binary file: Exec format error`

```
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~$ tar -xJf node-v22.22.0-linux-arm64.tar.xz
ana@dev:~$ ./node-v22.22.0-linux-arm64/bin/node --version
bash: line 7: ./node-v22.22.0-linux-arm64/bin/node: cannot execute binary file: Exec format error
```

**That file was built for a different processor.** `linux-arm64` runs on an ARM machine, a Mac with
an Apple chip running a Linux virtual machine for instance, and this computer is `x86_64`. Run
`uname -m`, download the file whose name matches it, and unpack that one over the same folder.

## Ubuntu's own Node is too old

```
ana@dev:~$ apt-cache policy nodejs | head -n 3
nodejs:
  Installed: (none)
  Candidate: 18.19.1+dfsg-6ubuntu5
```

Ubuntu 24.04 does ship a package called `nodejs`, and **it is version 18**, four major versions
behind the one this course was recorded on, and no longer supported by the Node project. Most of the
course would run on it, and then a newer piece of syntax would fail with a `SyntaxError` that looks
like your mistake. `node --version` is the check: anything below `v22` is the wrong Node.

## `Executable doesn't exist`

`page` run before the browser was downloaded:

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ echo '<script>console.log("the browser works")</script>' > check.html
ana@dev:~/js$ page check.html 2>&1 | head -n 13
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launchPersistentContext: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
╔═════════════════════════════════════════════════════════════════════════╗
║ Looks like Playwright Test or Playwright was just installed or updated. ║
║ Please run the following command to download new browsers:              ║
║                                                                         ║
║     npx playwright install                                              ║
║                                                                         ║
║ <3 Playwright Team                                                      ║
╚═════════════════════════════════════════════════════════════════════════╝
```

`npm install` fetched Playwright and not the browser, and the path in the first long line is where
Playwright looked for one. The box suggests `npx playwright install`, which downloads three
browsers; the command in the previous section downloads the one `page` uses. Run it in `~/js-tools`.

## `Cannot find package 'playwright'`

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ node ~/Downloads/page.mjs check.html 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'playwright' imported from /home/ana/Downloads/page.mjs
```

`page.mjs` was saved where the browser saves files, in `~/Downloads`. **Node looks for a package
beside the program that imports it**, in a `node_modules` folder there or in a folder above, and
Playwright is in `~/js-tools/node_modules`. Move both files into `~/js-tools`.

## `EADDRINUSE`

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ node ~/js-tools/serve.mjs &
serving /home/ana/js on http://127.0.0.1:8080
ana@dev:~/js$ page check.html 2>&1 | head -n 5
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 127.0.0.1:8080
ana@dev:~/js$ kill %1
```

**Only one program at a time can listen on an address**, and `serve.mjs` was already holding
`127.0.0.1:8080` in the background when `page` tried to start its own server there. Stop the other
one: `kill %1` stops the job this terminal sent to the background, and closing the terminal it runs
in stops it too.

## `Cannot find module`

```
ana@dev:~/js$ node helo.js
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/js/helo.js'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

Long, and only one line of it matters: `Error: Cannot find module '/home/ana/js/helo.js'`. **Node
is telling you the full path it tried**, and the file is called `hello.js`. Everything indented
under it is Node's own code on the way to that error; you can ignore it until lesson 17 teaches
you to read a stack. The two usual causes are a typo, as here, and a terminal sitting in a
different directory from the file. `pwd` says where you are, `ls` what is there.

## `Invalid or unexpected token`

A file pasted from a word processor or a chat window often carries typographic quotes, `“` and
`”`, where the language wants the plain `"`:

```javascript
console.log(“Hello”);
```

```
ana@dev:~/js$ node quotes.js 2>&1 | head -n 5
/home/ana/js/quotes.js:1
console.log(“Hello”);
            

SyntaxError: Invalid or unexpected token
```

The `2>&1 | head -n 5` on the end keeps the first five lines; the rest is the same list of Node
internals as above. **A token is one word of the language**, and `“` is not one. Node names the
file and the line, `quotes.js:1`, and that is where to look. Retype the quotes in your editor.

## `Unexpected token '<'`

```
ana@dev:~/js$ node hello.html 2>&1 | head -n 5
/home/ana/js/hello.html:1
<!doctype html>
^

SyntaxError: Unexpected token '<'
```

**Node was handed a page instead of a program.** `<` is where HTML starts and JavaScript does not.
A page goes to `page`, or to a browser; only the `.js` file goes to `node`.
