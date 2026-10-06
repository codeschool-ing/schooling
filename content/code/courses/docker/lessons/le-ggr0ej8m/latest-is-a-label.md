---
title: "`latest` is only a name"
version: 1
---

**`latest` is not the newest version of anything. It is the tag Docker writes when you do not write
one**, and it points wherever the last push that used it left it. Ana builds `shelf` with no tag:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.0.0 -t shelf .
sha256:acc588659f39257c1d2805c138b68988e6cb895fde9fd373266bf4f33ba3e3ac
ana@vm:~/shelf$ docker image ls shelf
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:latest   acc588659f39         28MB         7.84MB        
```

`shelf:latest`, because the build had to call it something. Nothing about the image is "late"; it
could be the oldest build on the machine.

## Two containers, both "latest"

Ana pushes that image as `localhost:5000/shelf`, which is `localhost:5000/shelf:latest`, and starts a
container from it. Then she builds version 1.1.0, pushes it under the same name, and starts a second
container from the same name:

```
ana@vm:~/shelf$ docker tag shelf localhost:5000/shelf && docker push -q localhost:5000/shelf
localhost:5000/shelf:latest
ana@vm:~/shelf$ docker run -d --name web-a localhost:5000/shelf
3d67ba4fa2862650b043b6db0c3ea8d006d595b98becb17d03ea1c3492934f60
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.1.0 -t localhost:5000/shelf .
sha256:613066b36b4cd80c6be9a17d5be8d248c2e6dd515562060ee54310e00fb5681f
ana@vm:~/shelf$ docker push -q localhost:5000/shelf
localhost:5000/shelf:latest
ana@vm:~/shelf$ docker run -d --name web-b localhost:5000/shelf
82d44aaeeef5b15a4d1152287f478adacb07f2db63bf13337e0227a82530aa0c
ana@vm:~/shelf$ docker ps --format "{{.Names}}\t{{.Image}}"
web-b	localhost:5000/shelf
web-a	acc588659f39
registry	registry:3
ana@vm:~/shelf$ docker logs web-a 2>&1 | tail -1; docker logs web-b 2>&1 | tail -1
2026/10/06 17:47:25 shelf 1.0.0 listening on :8080
2026/10/06 17:47:33 shelf 1.1.0 listening on :8080
ana@vm:~/shelf$ docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}"
localhost:5000/shelf:latest	613066b36b4c
shelf:latest	acc588659f39
registry:3	ddf754342cfc
golang:1.25	699337d62055
gcr.io/distroless/static-debian12:nonroot	afa5c872c891
```

**Two containers started from the same image name, running two different programs.** `docker ps`
already gives it away: `web-b` shows the name, but `web-a` shows a bare id, because the name it was
started from now belongs to another image. On one machine that is a curiosity. On three servers
that each pulled `latest` on a different day, it is three versions of `shelf` answering the same
users, and nobody's deployment file says which.

**`docker run` does not check the registry for a newer image.** It pulls only when the name is
missing on the machine, so a server that pulled `latest` in March runs March's build until somebody
removes it or pulls again. `docker run --pull always` asks every time, which trades the stale image
for a different surprise: a restart at three in the morning that quietly changes the version.

## What `latest` costs

- **No rollback.** To go back, you need the name of what was running before; `latest` only ever
  names what is there now.
- **No answer to "what is running".** A bug report against `latest` is a report against whatever
  the tag pointed at that day.
- **Builds that change by themselves.** `FROM golang:latest` in a Dockerfile gets a new compiler
  whenever Go releases one. Hadolint's `DL3007`, in lesson 10, refuses it for that reason.

`latest` is fine for one thing: trying an image out by hand. Anything written down, a `FROM` or a
deployment, names a version, and the next section is about which ones.
