---
title: The Sync functions, and when they are fine
version: 1
---

**Most of `node:fs` comes in two forms: one that hands the work to the pool and calls you back, and
one ending in `Sync` that does it on the main thread and returns the answer.** `readFileSync` is
simpler to write, and while it runs, nothing else in the process does.

That is not always wrong. **At start-up nothing else is happening yet**, so reading a
configuration file or a certificate with `readFileSync` before the server listens costs nobody
anything. Inside a request handler it costs every request in the process, for as long as the disk
takes. On a laptop's SSD that is microseconds; on a busy network disk in production it can be the
two seconds of the previous section.

## A flag that finds them

`node --trace-sync-io` prints a warning, with a stack trace, every time a synchronous function runs
after the first turn of the loop — which is to say, everywhere except start-up. This server reads its
banner once at start-up and the same file again on every request. `echo "hello" > motd.txt` makes the
file it reads:

```javascript
// motd.js: the message of the day, read from a file.
const fs = require("node:fs");
const http = require("node:http");

const banner = fs.readFileSync("motd.txt").toString(); // once, at start-up

http
  .createServer((req, res) => {
    const motd = fs.readFileSync("motd.txt").toString(); // on every request
    res.end(banner === motd ? motd : `${motd}(changed since start-up)\n`);
  })
  .listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/loop$ node --trace-sync-io motd.js
(node:13168) WARNING: Detected use of sync API
    at openSync (node:fs:560:18)
    at readFileSync (node:fs:444:35)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at tryStatSync (node:fs:390:25)
    at readFileSync (node:fs:446:17)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at readSync (node:fs:739:18)
    at tryReadSync (node:fs:416:20)
    at readFileSync (node:fs:462:19)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at closeSync (node:fs:517:11)
    at readFileSync (node:fs:479:8)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

^C
```

That is the server's terminal after one `curl http://127.0.0.1:3000/` from the other. The start-up
read printed nothing, as promised. **The read in the handler printed four warnings**,
because `readFileSync` is four system calls: open, stat, read and close. The line naming `motd.js`
is the one to fix.

## What the flag does not see

Write the same two reads with an encoding, `readFileSync("motd.txt", "utf8")`, which is how most
code writes them. The `sed` line below makes that copy of the file, `grep` counts the two lines it
changed, and with the copy running in the first terminal, `curl` asks it once:

```
ana@dev:~/server/loop$ sed 's/("motd.txt").toString()/("motd.txt", "utf8")/' motd.js > motd-utf8.js
ana@dev:~/server/loop$ grep -c utf8 motd-utf8.js
2
ana@dev:~/server/loop$ curl -s http://127.0.0.1:3000/
hello
```

In the first terminal, the server printed nothing before Ctrl-C stopped it:

```
ana@dev:~/server/loop$ node --trace-sync-io motd-utf8.js
^C
```

**Nothing.** In Node 22, reading a file as text with an encoding goes through a faster internal
path that the flag does not watch, and the handler is just as synchronous as before. The flag is
worth running, and its silence is not proof. The habit that is proof is the one this course keeps:
**`Sync` at start-up, the promise or callback form everywhere else.** Lesson 8 uses the promise form,
`node:fs/promises`.
