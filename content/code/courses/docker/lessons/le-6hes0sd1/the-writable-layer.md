---
title: What survives a stop, and what does not
version: 1
---

**A container's writable layer lives exactly as long as the container, not as long as its
process.** Stopping a container ends its process and keeps its layer; removing the container
deletes the layer and everything written into it. People say "containers are ephemeral" and mean
the second half, and then are surprised by the first.

Ana starts a container, writes a file into it, and asks Docker what changed compared with the
image:

```
ana@vm:~$ docker run -d --name notes alpine:3.22 sleep 3600
f5fb65e5afd4a63ffe25cb5e39df039c8d0b0215f57f555038d3359c0b4a5e6b
ana@vm:~$ docker exec notes sh -c "echo first note > /notes.txt"
ana@vm:~$ docker diff notes
A /notes.txt
```

`docker diff` lists the paths in the container's own layer: `A` for added, `C` for changed and `D`
for deleted. One line, the file she wrote. It is lesson 4's upper directory, read through Docker
instead of through the host's mounts.

## Stopping keeps the layer

```
ana@vm:~$ docker stop notes
notes
ana@vm:~$ docker ps -a --format "{{.Names}}: {{.Status}}"
notes: Exited (137) Less than a second ago
ana@vm:~$ docker start notes
notes
ana@vm:~$ docker exec notes cat /notes.txt
first note
```

The container stopped: `docker ps -a`, which also lists stopped containers, shows it as `Exited`.
Started again, it has its file. **A stopped container is not gone**; it is a writable layer and a
configuration waiting for its process to start again, and it keeps taking disk space until it is
removed. The `137` in its status is lesson 4's number again, `SIGKILL`: `sleep` ignored the polite
signal `docker stop` sent first, so Docker killed it after the default wait of ten seconds. Lesson
11 is about why that happens and how a program avoids it.

## Removing deletes it

```
ana@vm:~$ docker rm -f notes
notes
ana@vm:~$ docker run -d --name notes alpine:3.22 sleep 3600
39068d3197c9c5698fe2817700f7b6e999762aa71efc4ef50945cc90254705bc
ana@vm:~$ docker exec notes cat /notes.txt
cat: can't open '/notes.txt': No such file or directory
```

Same name, same image, a new container, and no file. **The name is not the container.** Once
`docker rm` ran, the old container and its layer were gone, and `docker run` made a brand new one
that happened to be called `notes` too.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The states of a container from left to right. docker create or docker run makes it: created. Started, it is running. docker stop takes it to exited, and docker start brings it back to running. docker rm takes an exited container to removed. A band underneath says the writable layer exists from created through exited, and is deleted at removed.\"><defs><marker id=\"l7life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7life-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">created</text><rect x=\"200\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">running</text><rect x=\"380\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">exited</text><rect x=\"570\" y=\"50\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">removed</text><path d=\"M152 75 L196 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"174\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start</text><path d=\"M332 66 L376 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"354\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">stop</text><path d=\"M376 86 L332 86\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-wire)\"></path><text x=\"354\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">start</text><path d=\"M512 75 L566 75\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7life-ah-amber)\"></path><text x=\"539\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">rm</text><rect x=\"20\" y=\"150\" width=\"490\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the writable layer exists, with everything written into it</text><rect x=\"570\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">deleted</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">docker run = create + start</text></svg>", "caption": "Stopping and starting move a container between running and exited, and its writable layer stays. Only removal deletes the layer."}
```

The difference matters in a habit everybody picks up quickly: to "restart" a container with a new
setting, people remove it and run it again, because most of a container's configuration cannot be
changed after it is created. Every time they do, the old writable layer goes with it. **Anything worth
keeping must never be only in a container's own layer.** The next section shows what that costs
when the thing worth keeping is a database.
