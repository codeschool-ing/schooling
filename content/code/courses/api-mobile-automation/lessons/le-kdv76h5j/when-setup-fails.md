---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over one line of output
that looked like a catastrophe and was a small thing. These are the failures that come up while
following the last two sections, each with what it prints and what fixes it. Every one of them was
produced on purpose, on the machine the transcripts come from.

## `node: command not found`

The terminal was opened before `~/.bashrc` learnt where Node lives:

```
ana@laptop:~/boxoffice$ node --version
bash: node: command not found
```

A terminal reads `~/.bashrc` once, when it opens. **Open a new terminal**, or run `source ~/.bashrc`
in this one. If a new terminal still cannot find it, `ls /opt/node/bin` says whether the unpacking
worked, and `tail -1 ~/.bashrc` shows whether the `export` line is there. On Ubuntu Desktop the
message is longer and suggests `sudo apt install nodejs`. Do not take the suggestion: that is the
old Node 18 the last section went around.

## `Failed to connect`

curl asked and nobody answered:

```
ana@laptop:~/boxoffice$ curl localhost:8080/health
curl: (7) Failed to connect to localhost port 8080 after 0 ms: Couldn't connect to server
ana@laptop:~/boxoffice$ echo $?
7
```

Exit code 7 is curl's way of saying the connection was refused, which means **nothing is listening
on that port**. boxoffice is not running: its terminal was closed, or Ctrl-C stopped it, or it was
started in another directory and failed there. Look at the second terminal; if its last line is a
prompt rather than a request, start the server again.

## `EADDRINUSE`

boxoffice was started a second time while the first one was still running, in another terminal or
a tab you forgot:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 0.0.0.0:8080
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at Server.listen (node:net:2102:7)
    at file:///home/ana/boxoffice/boxoffice.mjs:230:4
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '0.0.0.0',
  port: 8080
}

Node.js v22.22.0
```

Read the first line of the error: `EADDRINUSE`, address in use. Only one program can listen on a
port, and the first boxoffice already has 8080. Find the terminal where it runs and press Ctrl-C
there, or start this one on another port with `PORT=8081 node boxoffice.mjs` and send your requests
to `localhost:8081`.

## `SyntaxError: Unexpected end of input`

The file stops before its end. This one was saved from a paste that lost its last line:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
file:///home/ana/boxoffice/boxoffice.mjs:230



SyntaxError: Unexpected end of input
    at compileSourceTextModule (node:internal/modules/esm/utils:346:16)
    at ModuleLoader.moduleStrategy (node:internal/modules/esm/translators:107:18)
    at #translate (node:internal/modules/esm/loader:546:20)
    at afterLoad (node:internal/modules/esm/loader:596:29)
    at ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:601:12)
    at #createModuleJob (node:internal/modules/esm/loader:624:36)
    at #getJobFromResolveResult (node:internal/modules/esm/loader:343:34)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:311:41)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:664:25)

Node.js v22.22.0
```

Node reads the whole file before running any of it, so a missing bracket at the end is reported at
the end, `boxoffice.mjs:230`, however far above it the real cut was. **Copy the file again with the
button on its block** and save over the old one, rather than hunting for the missing piece.
