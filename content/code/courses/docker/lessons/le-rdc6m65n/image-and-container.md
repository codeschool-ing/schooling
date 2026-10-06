---
title: Image and container
version: 1
---

**An image is what a container is started from; a container is what is running.** The image is a
read-only bundle: a filesystem with everything the program needs, plus a little metadata, such as
which command to run by default. A container is one instance made from it: the image's files, a
thin layer of its own on top where it can write, a configuration, and the process that is running.

People mix the two words up all the time, and the mix-up hides real questions. "Delete the
container" and "delete the image" do different things, and "the container has the new version"
usually means "a new container was started from the new image".

## What the machine holds

`docker image ls` lists the images on Ana's machine:

```
ana@vm:~$ docker image ls
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
golang:1.25   699337d62055       1.26GB          316MB        
postgres:16   65b16a8b326e        642MB          166MB        
postgres:17   ae69c452f483        646MB          167MB   U    
```

Two size columns, and they answer different questions. **`CONTENT SIZE`** is what the image
weighs compressed, as it travels from a registry: 3.88MB for `alpine:3.22`. **`DISK USAGE`** is
what it takes unpacked on this disk: 12.8MB for the same image. `golang:1.25` is the heavy one,
1.26GB on disk, because a full compiler and its standard library are inside it. The `U` beside
`postgres:17` means "in use": a container made from it, the database from the previous section, is
running.

## Two containers, one image

Ana starts two containers from the same image, `one` and `two`, each running `sleep 600` so that it
stays up for ten minutes. Then she writes a file in `one` and looks for it in both:

```
ana@vm:~$ docker run -d --name one alpine:3.22 sleep 600
168d6c71af1bbf22a78b6993738ab93620a0fd5afaebbe3fe1f8ba0329cbc75f
ana@vm:~$ docker run -d --name two alpine:3.22 sleep 600
4d91949c1548c8c4488de0226a1ad1ba441df613ea281eec912208bb916c4c19
ana@vm:~$ docker exec one sh -c "echo from one > /note"
ana@vm:~$ docker exec one cat /note
from one
ana@vm:~$ docker exec two cat /note
cat: can't open '/note': No such file or directory
```

The file exists in `one` and nowhere else. **Each container gets its own writable layer on top of
the shared image**, and writes land there. The image underneath is never changed by a container,
which is why a hundred containers can start from the same image without stepping on each other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"At the bottom, the image alpine:3.22, read-only and shared. Above it, two containers, one and two, each with its own thin writable layer. The file /note exists in the writable layer of one and not in two.\"><defs><marker id=\"l1layers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"60\" y=\"190\" width=\"600\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">alpine:3.22</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">image: read-only, shared by both</text><rect x=\"60\" y=\"30\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"74\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container one</text><rect x=\"80\" y=\"70\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its writable layer</text><text x=\"200\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">/note</text><path d=\"M200 116 L200 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1layers-ah-wire)\"></path><text x=\"210\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads through</text><rect x=\"380\" y=\"30\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"394\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container two</text><rect x=\"400\" y=\"70\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its writable layer</text><text x=\"520\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">(empty)</text><path d=\"M520 116 L520 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1layers-ah-wire)\"></path><text x=\"530\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads through</text></svg>", "caption": "Both containers read the same image; each writes only into its own layer. The image underneath never changes, which is why any number of containers can start from it."}
```

`docker ps` shows the three containers now running, and which image each came from:

```
ana@vm:~$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES     IMAGE         STATUS
two       alpine:3.22   Up Less than a second
one       alpine:3.22   Up Less than a second
db        postgres:17   Up 5 seconds
```

## Removing a container leaves the image

`docker rm` removes containers; `-f` stops them first if they are running. The image they came
from stays:

```
ana@vm:~$ docker rm -f one two db
one
two
db
ana@vm:~$ docker image ls alpine
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
```

Three containers are gone, with the file `one` wrote and the database's tables, and the image is
still there to start the next one from. That is the whole of what lesson 7 is about: anything a
container writes into its own layer lives exactly as long as that container.

## The words the rest of the course uses

| word | what it is | where it is taught |
| --- | --- | --- |
| image | a read-only filesystem plus metadata, the thing you start containers from | here, and lesson 11 builds one |
| container | an image's files, a writable layer, a configuration and a running process | here |
| Dockerfile | the recipe an image is built from | lesson 11 |
| registry | a server that stores images and hands them out, like Docker Hub | lesson 15 |
| volume | storage that outlives the containers using it | lesson 8 |
