---
title: Keeping a service running
version: 1
---

**`npm start` in a terminal is not how a service runs on a server.** The terminal closes, the machine
restarts, the process crashes at three in the morning, and nothing starts it again. A **process
manager** is the program whose job that is: it starts the service at boot, restarts it when it
crashes, gives it its environment, sends it `SIGTERM` to stop it, and keeps its logs.

| process manager | where you meet it |
|---|---|
| **systemd** | every mainstream Linux server; nothing to install |
| the platform | a container platform or a hosting service restarts what it runs |
| **pm2** | a Node package, popular on servers without either |

## Run node, not npm

One detail first, because it can decide whether the graceful shutdown ever runs. **A service
manager stops what it started**, and `npm start` starts npm, which starts a shell, which starts
Node. The links service running under `npm start` in the first terminal, and in the second:

```
ana@dev:~/server/links$ pgrep -a 'npm|node'
15469 npm start
15484 node --env-file-if-exists=.env server.js
ana@dev:~/server/links$ kill -TERM 15469
ana@dev:~/server/links$ sleep 1; pgrep -a 'npm|node'
15469 [npm start] <defunct>
15484 node --env-file-if-exists=.env server.js
ana@dev:~/server/links$ kill -TERM 15484
```

**`SIGTERM` stopped npm and Node never heard it.** npm is `<defunct>`: it has ended, and its parent has
not yet collected its exit code. Node is still running, with nobody left to stop it, and with every
open request it had still open; the last `kill` above was sent to Node by hand, and only then did the
first terminal print its graceful shutdown. In a terminal Ctrl-C does reach it, because the terminal
sends the signal to every process in the group. Whether a service manager does depends on the
manager: systemd, by default, signals every process the service started, and Docker signals only the
first one, which here is npm. **A service runs `node` directly**, with the same options the `start`
script has, and then the question does not arise.

## A systemd unit

A **unit file** describes the service to systemd. This one is the links service on a Linux server, in a
folder `/srv/links` that a user `links` owns:

```schooling-example
{"language": "ini", "file": "/etc/systemd/system/links.service", "parts": [
 {"code": "[Unit]\nDescription=links, the link shortener\nAfter=network.target", "note": "What the service is, and that it starts after the network is up."},
 {"code": "[Service]\nUser=links\nWorkingDirectory=/srv/links\nEnvironment=NODE_ENV=production HOST=127.0.0.1 PORT=3000\nEnvironmentFile=/etc/links/secrets.env\nExecStart=/usr/bin/node server.js", "note": "**The environment, and the secret apart from it.** `EnvironmentFile` is lesson 9's protected file: readable by root only, and systemd reads it before the service starts. `ExecStart` is `node`, not `npm`, by its full path: `/usr/bin/node` is where a distribution's package puts it, and a Node unpacked from the tarball as in lesson 1 is wherever it was unpacked."},
 {"code": "Restart=on-failure\nRestartSec=2\nKillSignal=SIGTERM\nTimeoutStopSec=15", "note": "**Restart after a crash**, two seconds later. Stop with `SIGTERM`, and wait 15 seconds, longer than the service's own ten, before `SIGKILL`."},
 {"code": "[Install]\nWantedBy=multi-user.target", "note": "Start it at boot, once enabled."}
]}
```

And the commands that load it, start it, and read its log:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now links
systemctl status links
journalctl -u links -f
```

**This unit was not run for this course.** It is the standard form and every line is in systemd's own
manual, `man systemd.service`, but the course's practice machine is not a server booted by systemd,
and a unit that was never started is not a capture. What it adds to everything in this lesson is no
new code: the service already reads its environment, refuses a bad configuration, and stops cleanly
on `SIGTERM`, which is all a process manager needs from it.

**pm2** does the same from npm, with `pm2 start server.js`, and adds a cluster mode of its own. It was
not run here either; on a machine with systemd it is a second process manager, and one is enough.
