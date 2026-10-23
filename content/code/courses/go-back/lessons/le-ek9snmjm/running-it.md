---
title: boxoffice in a container
version: 1
---

Run the image with nothing around it:

```
ana@vm:~$ docker run --rm boxoffice:v0.16.0; echo "exit $?"
boxoffice: DATABASE_URL: not set
BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in
exit 2
```

**Lesson 14's refusal, from inside a container**: no database, no token, exit status 2, and `docker run`
passes the status on. Everything boxoffice needs from outside has to be handed in, and `docker run` has a
flag for each kind:

| boxoffice needs | the flag | here |
|---|---|---|
| to be reachable | `-p 8080:8080` | the host's port 8080 forwarded to the container's, where `BOXOFFICE_HTTP=:8080` listens |
| the database's socket | `-v /var/run/postgresql:/var/run/postgresql` | the host's socket directory mounted into the container, so lesson 6's URL works unchanged |
| to be the database user | `--user "$(id -u):$(id -g)"` | PostgreSQL's peer authentication accepts the connection when the process's uid is yours |
| the token | `-v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro` and `-e BOXOFFICE_MANAGER_TOKEN_FILE=…` | lesson 14's file, mounted read-only, and the variable naming where it is |
| the database's address | `-e DATABASE_URL=…` | the value from `~/.profile` |

```
ana@vm:~$ docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="$DATABASE_URL" boxoffice:v0.16.0
3ada0d2cf0d3a143693eed29ab26d3039e5f7bc2aa2031c5e92dbbe2e28fd294
ana@vm:~$ docker logs boxoffice
{"time":"2026-10-22T23:01:17.965182027Z","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":":8080","grpc":":9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
{"time":"2026-10-22T23:01:17.966783473Z","level":"INFO","msg":"database: migrating: failed to initialize: failed to connect to `user= database=boxoffice`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: no PostgreSQL user name specified in startup packet (SQLSTATE 28000)"}
```

`-d` runs it in the background and prints the container's id; `docker logs` prints what it wrote. The
configuration arrived: `:8080`, `:9090`, one staff token, the version. **Then the connection failed with
`user=` empty.** pgx takes the database user from the URL, and when the URL has none, from the operating
system's user name for the process's uid. In the container that uid is yours, and the image's
`/etc/passwd` has never heard of it, so there is no name to send. Two more things show in those
lines: the timestamps end in `Z`, because the image has no local time zone and Go falls back to UTC; and
`log.Fatalf`'s line came out as `INFO`, because lesson 12's `slog.SetDefault` turns every old `log` call
into a line at that level.

Remove the container that failed:

```
ana@vm:~$ docker rm boxoffice
boxoffice
```

Then run it again with the user named in the URL and the container given the time zone:

```
ana@vm:~$ docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="postgres://$USER@/boxoffice?host=/var/run/postgresql" -e TZ=America/Sao_Paulo boxoffice:v0.16.0
6ebd15d66036cc1bb9ecc404b0ffb974d1cfee3e7794f41f1af7c346afe73af1
ana@vm:~$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
ana@vm:~$ docker logs boxoffice
{"time":"2026-10-22T20:01:20.23046045-03:00","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":":8080","grpc":":9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
{"time":"2026-10-22T20:01:20.241474634-03:00","level":"INFO","msg":"boxoffice listening on :8080"}
{"time":"2026-10-22T20:01:20.241614259-03:00","level":"INFO","msg":"grpc listening on 0.0.0.0:9090"}
{"time":"2026-10-22T20:01:22.259173441-03:00","level":"INFO","msg":"request","request_id":"4f9400389f45a42c","method":"GET","path":"/events/1","status":200,"bytes":73,"duration_ms":3.755}
```

It serves. The log is the same JSON lesson 12 designed, now read with `docker logs`, which is where a
container platform collects it. The gRPC port listens on every interface too, and nothing reaches it,
because no `-p` published it.

## Stopping it

```
ana@vm:~$ time docker stop boxoffice
boxoffice

real	0m0.201s
user	0m0.015s
sys	0m0.008s
```

**A fifth of a second.** `docker stop` sends the main process `SIGTERM`, waits up to ten seconds, then
sends `SIGKILL`. boxoffice does nothing about `SIGTERM`, so Go's default applies and the process ends on
the spot, with whatever requests were in flight cut off mid-answer. That is quick, and wrong for a server
with customers buying tickets. Lesson 17 makes boxoffice finish what it started before it exits.
