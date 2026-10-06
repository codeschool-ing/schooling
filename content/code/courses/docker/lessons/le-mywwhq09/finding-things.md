---
title: Finding things
version: 1
---

**A machine that has run Docker for a week has more containers, images and volumes than anyone
remembers starting.** Three habits keep that manageable: filter instead of scrolling, format instead
of reading whole tables, and ask the right command for the field you want.

## `ps` with filters and a format

```
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES     IMAGE         STATUS
once      alpine:3.22   Exited (0) 4 seconds ago
web-old   shelf:1.0.0   Up 4 seconds
web       shelf:1.0.1   Up 5 seconds
ana@vm:~$ docker ps -a --filter status=exited --format "{{.Names}}"
once
ana@vm:~$ docker ps --filter ancestor=shelf:1.0.0 --format "{{.Names}}"
web-old
ana@vm:~$ docker ps -q
84626c4c1aa9
b0176fabef01
```

**`--format` with a Go template picks the columns**, the same syntax as `docker inspect --format` since
lesson 3. `--filter` narrows the rows: `status=exited` for what has stopped, `ancestor=` for every
container started from an image, which is the question to ask before deleting one. **`-q` prints
only ids**, one a line, which is what other commands take as input: `docker rm $(docker ps -aq --filter
status=exited)` removes exactly the stopped ones.

## `inspect` for one field

```
ana@vm:~$ docker inspect web --format "{{.State.Status}} since {{.State.StartedAt}}"
running since 2026-10-06T20:41:29.902926698Z
ana@vm:~$ docker inspect web --format "{{json .NetworkSettings.Ports}}" | jq -c
{"8080/tcp":[{"HostIp":"127.0.0.1","HostPort":"8080"}]}
ana@vm:~$ docker inspect web --format "{{.Config.User}} {{json .Config.Cmd}}"
65532:65532 ["/shelf"]
```

`docker inspect` prints everything Docker knows about an object as JSON, hundreds of lines.
**`--format` with a path picks one field**, and `{{json …}}` keeps a structure as JSON for `jq`. The
three above answer questions that come up every day: since when it has run, where it is published,
and which user and command it runs. `StartedAt` is in UTC, whatever the machine's time zone.

## `logs` and the two streams

```
ana@vm:~$ docker logs --timestamps --tail 2 web
2026-10-06T20:41:30.030172671Z 2026/10/06 20:41:30 catalogue: built in, 3 books
2026-10-06T20:41:30.031007731Z 2026/10/06 20:41:30 shelf 1.0.1 listening on :8080
ana@vm:~$ docker logs --since 1h web | wc -l
2026/10/06 20:41:30 catalogue: built in, 3 books
2026/10/06 20:41:30 shelf 1.0.1 listening on :8080
0
ana@vm:~$ docker logs --since 1h web 2>&1 | wc -l
2
```

`--timestamps` prefixes each line with the time the daemon received it, and `--tail` and `--since` cut
the history down. **And the count is 0, then 2.** `docker logs` replays a container's standard output
to standard output and its standard error to standard error, and Go's `log` package, which `shelf`
uses, writes to standard error. So the lines went past `wc` straight to the terminal. `2>&1` merges the
two before the pipe; any `grep` on a container's log needs it for the same reason.
