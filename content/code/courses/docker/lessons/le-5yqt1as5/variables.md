---
title: Environment variables
version: 1
---

**The same image runs in development, in tests and in production, and what changes between them is
configuration.** Lesson 11 put a default into an image with `ENV`; `docker run -e` sets or overrides a variable for
one container, without a new build.

## `-e`, one at a time

`shelf` reads `PORT`. Ana sets it to 9090, and publishes the host's 8080 to that:

```
ana@vm:~$ docker run -d --name web -e PORT=9090 -p 127.0.0.1:8080:9090 shelf:1.0.0
d8bd3284d3bb0332df5beebc6dd01e18aeb11abf9e18ec03c0cb8c56a7cefd33
ana@vm:~$ docker logs web
2026/10/06 17:56:16 catalogue: built in, 3 books
2026/10/06 17:56:16 shelf 1.0.0 listening on :9090
ana@vm:~$ curl -s localhost:8080/version
1.0.0
```

The log says `:9090`, and `-p 127.0.0.1:8080:9090` connects the two. **The image is unchanged; the
container is configured.**

## `--env-file`, for several

For more than one or two, a file keeps them together and keeps the values out of the shell's
history. One `NAME=value` a line:

```
PORT=8080
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
```

```
ana@vm:~$ docker run -d --name web --env-file shelf.env shelf:1.0.0
e05f7d276ec8f1b2c0600257a2048e85514c7d6624dfe8ca280a4e0965187de6
ana@vm:~$ docker logs web
2026/10/06 17:56:18 database: failed to connect to `user=shelf database=shelf`:
	hostname resolving error: lookup db on 8.8.8.8:53: no such host
	lookup db on 8.8.8.8:53: no such host
ana@vm:~$ docker inspect web --format "{{json .Config.Env}}" | jq .
[
  "PORT=8080",
  "DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf",
  "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
]
```

`shelf` tried the database named in `DATABASE_URL`, could not find a host called `db`, and stopped.
That failure is useful later in this lesson. The command after it is the point here.

## Where a secret in a variable ends up

**`docker inspect` shows every environment variable of a container, password included**, and so does
anything else that can read the container's configuration. Lesson 6 established who that is: everyone
in the `docker` group, which is to say everyone with root on the machine. The process's own
environment is also readable inside the container, by the program and by anything it starts.

That makes environment variables fine for configuration, and a poor place for secrets on a machine
other people use. The improvements, in order of effort:

1. **Keep the env file out of everything else.** Ana's sits outside `~/shelf` altogether; one inside
   a project belongs in `.dockerignore` (lesson 11) and `.gitignore`, readable by its owner only.
2. **Mount the secret as a file** and have the program read the file. Compose does this with its
   `secrets:` key in lesson 19, and Kubernetes and Swarm have the same idea.
3. **Fetch it at start** from a secret manager, which the clouds in lesson 15's table each provide,
   with an identity the server already has.

And never `-e PASSWORD=…` typed on the command line: it lands in the shell's history file, and in the
process list of anyone looking while `docker run` runs.
