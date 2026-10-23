---
title: The process, and the signals it is sent
version: 1
---

**Every `node` you start is a process: a running program with a number of its own, the memory it was
given, and a parent that started it.** `process` is Node's view of that, and a few of its properties
are worth seeing once. This lesson's programs go in a folder of their own, `~/server/procs`:

```javascript
// proc.js: what a process knows about itself.
console.log("pid", process.pid, "started by", process.ppid);
console.log("node", process.version, "on", process.platform, process.arch);
console.log("arguments", process.argv.slice(2));
console.log("folder", process.cwd());
const { rss, heapUsed } = process.memoryUsage();
console.log(`memory: ${Math.round(rss / 2 ** 20)} MB in all, ${Math.round(heapUsed / 2 ** 20)} MB of JavaScript objects`);
console.log("running for", process.uptime().toFixed(3), "s");
```

```
ana@dev:~/server/procs$ node proc.js one two
pid 14498 started by 14496
node v22.22.0 on linux x64
arguments [ 'one', 'two' ]
folder /home/ana/server/procs
memory: 42 MB in all, 4 MB of JavaScript objects
running for 0.014 s
ana@dev:~/server/procs$ node -e 'process.exitCode = 3'; echo "exit code $?"
exit code 3
```

The **pid** is the process's number, and **ppid** is its parent's, here the shell. `rss` is all the
memory the process holds, the runtime included, and `heapUsed` is the part your objects take: a Node
that has done nothing already holds about 40 MB. **The exit code is the process's last word**: 0 for
success, anything else for failure, and `process.exitCode` sets it without stopping anything, so the
program ends when its work does and reports the code then. `process.exit(code)` stops at once, with
writes and timers still pending, which is why this course reaches for it only when there is nothing
left to lose.

## Signals

**A signal is a message the operating system delivers to a process from outside**, and it is how a
process is asked to stop. Four matter to a server:

| signal | who sends it | can the program handle it? |
|---|---|---|
| `SIGINT` | Ctrl-C in the terminal | yes |
| `SIGTERM` | `kill`, and every service manager stopping a service | yes |
| `SIGHUP` | the terminal closing | yes |
| `SIGKILL` | `kill -KILL`, or `kill -9` | **no**: the process is ended by the system |

Node's default for the first three is to exit. A program can listen for them instead, and this one
listens and does nothing, to show that it hears them:

```javascript
// signals.js: a program that says which signal it was sent.
console.log(`pid ${process.pid}: waiting`);
for (const sig of ["SIGINT", "SIGTERM", "SIGHUP"]) {
  process.on(sig, () => console.log(`got ${sig}, and carrying on`));
}
setInterval(() => {}, 1000);
```

Run it in one terminal and send it signals from a second one, with the pid it printed:

```
ana@dev:~/server/procs$ kill -INT 14529
ana@dev:~/server/procs$ kill -TERM 14529
ana@dev:~/server/procs$ kill -HUP 14529
ana@dev:~/server/procs$ kill -KILL 14529
```

```
ana@dev:~/server/procs$ node signals.js; echo "exit code $?"
pid 14529: waiting
got SIGINT, and carrying on
got SIGTERM, and carrying on
got SIGHUP, and carrying on
bash: line 1: 14529 Killed                  node signals.js
exit code 137
```

**`SIGKILL` cannot be heard**: the program never runs another line, and the shell reports it as exit
code 137, which is 128 plus the signal's number, 9. A program that ignored `SIGTERM` the way this one
does would be killed like that by every service manager after a wait, mid-write. The next section is
what a server does with `SIGTERM` instead.
