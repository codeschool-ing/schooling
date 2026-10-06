---
title: Images somebody else maintains
version: 1
---

**Most of the containers you run are not built by you.** A database, a cache, a message queue, a
web server: each is published as an image by somebody who knows how to configure it, and running it
is one command. The skill this lesson teaches is reading such an image well enough to trust it and
to configure it, because everything it does on start is decided by its author.

## Who published it

Docker Hub labels three kinds of publisher, and the label is the first thing to check:

- **Docker Official Images**: a curated set, `postgres`, `redis`, `python`, `alpine` and many
  more, maintained by Docker together with each project's maintainers. Their
  names have no slash, because they live in a namespace called `library`, which `docker` fills in
  for you.
- **Verified Publisher**: images from a company Docker has verified, under that company's
  namespace, such as a database vendor's own images or a cloud provider's tools.
- **Sponsored Open Source**: images from open-source projects in Docker's sponsorship programme.

Anything else is an image somebody uploaded. It may be excellent, and nobody has checked it. Lesson
20 shows how to look inside any image before trusting it; the label is the cheap first filter.

## Pulling one

The first run of an image downloads it. Ana pulls it on its own, to watch:

```
ana@vm:~$ docker pull postgres:17
17: Pulling from library/postgres
affbe3357b39: Pulling fs layer
b86134c2eeb6: Pulling fs layer
99ce35cabaf9: Pulling fs layer
c9432d362cca: Pulling fs layer
dc30f2779c66: Pulling fs layer
3be737420556: Pulling fs layer
d43ee31e40df: Pulling fs layer
e30751283c57: Pulling fs layer
8aebe6431dc8: Pulling fs layer
c5602f014e9e: Pulling fs layer
fcdd3a481359: Pulling fs layer
52fc2be321a4: Pulling fs layer
57644501a07f: Pulling fs layer
99ce35cabaf9: Download complete
affbe3357b39: Download complete
b86134c2eeb6: Download complete
57644501a07f: Download complete
e30751283c57: Download complete
c9432d362cca: Download complete
d43ee31e40df: Download complete
dc30f2779c66: Download complete
c5602f014e9e: Download complete
3be737420556: Download complete
fcdd3a481359: Download complete
8aebe6431dc8: Download complete
fcdd3a481359: Pull complete
52fc2be321a4: Download complete
b86134c2eeb6: Pull complete
57644501a07f: Pull complete
a7cb71218182: Download complete
affbe3357b39: Pull complete
e30751283c57: Pull complete
c5602f014e9e: Pull complete
3be737420556: Pull complete
3de48e9ae1ea: Download complete
c9432d362cca: Pull complete
d43ee31e40df: Pull complete
dc30f2779c66: Pull complete
8aebe6431dc8: Pull complete
99ce35cabaf9: Pull complete
52fc2be321a4: Pull complete
Digest: sha256:ae69c452f483507a6b99fb654cf93aad7fe156ffd2c56247707eef4e36d3c12b
Status: Downloaded newer image for postgres:17
docker.io/library/postgres:17
```

**Thirteen layers, each named by a short form of its digest**, downloaded in parallel, then
unpacked one by one, "Pull complete". The `Digest` line names the exact image she now has, and the
last line gives its full name: `docker.io/library/postgres:17`, registry, namespace, repository and
tag, the parts lesson 15 takes apart.

## What it will do when it starts

An image's configuration says what runs if `docker run` is given no command, and lesson 3 read it
from the raw JSON. `docker image inspect` reads the same fields:

```
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.Entrypoint}} {{json .Config.Cmd}}"
["docker-entrypoint.sh"] ["postgres"]
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.ExposedPorts}}"
{"5432/tcp":{}}
```

**`Entrypoint` is `docker-entrypoint.sh`, and `Cmd` is `postgres`**, which is passed to it as an
argument. The entrypoint is a shell script the image's authors wrote, and it is where everything the
next section relies on happens: on first start it creates the database files, sets the password,
runs your setup scripts, and only then starts the server. Every serious database image works this
way, and its documentation lists the environment variables its entrypoint reads.

`ExposedPorts` says the server listens on `5432`. That is documentation, not a door: lesson 17
shows that nothing is reachable from outside until a port is published.

## Choosing a tag

The image page lists its tags, and they follow a pattern worth knowing:

| tag | what it names |
| --- | --- |
| `17` | the newest 17.x release, which moves with every patch |
| `17.11` | exactly that minor release, which moves only for rebuilds of the same version |
| `17-alpine` | the same PostgreSQL on Alpine instead of Debian: smaller, with `musl` instead of `glibc` |
| `17-trixie` | the same PostgreSQL on Debian 13 explicitly |
| `latest` | whatever the authors chose to call latest, which for a database is a trap |

**Pick at least the major version**, because a database's data files belong to one major version,
as lesson 8 showed. Lesson 16 is about why `latest` is never a version.
