---
title: A smaller surface
version: 1
---

**Every file in an image is something to download, store, scan and keep patched, and every program
in it is something an attacker can use.** A smaller image is not about saving disk; it is about how
much there is to go wrong. Lesson 13 took `shelf` from 1.44GB to 28MB by leaving the compiler
behind. This section is about the base under it, and about a trap that keeps images large without
anybody noticing.

## What the common bases weigh

```
ana@vm:~/shelf$ docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "golang|debian|alpine|distroless"
debian:trixie-slim                          119MB
debian:trixie                               187MB
alpine:3.22                                 12.8MB
golang:1.25                                 1.26GB
gcr.io/distroless/static-debian12:nonroot   6.18MB
gcr.io/distroless/static-debian12:latest    6.67MB
```

**From 1.26GB to 6.18MB** for the bases this course has used. The two Debian images are the
interesting pair:

```
ana@vm:~/shelf$ docker run --rm debian:trixie sh -c "dpkg -l | grep -c ^ii"
78
ana@vm:~/shelf$ docker run --rm debian:trixie-slim sh -c "dpkg -l | grep -c ^ii"
78
ana@vm:~/shelf$ docker run --rm alpine:3.22 grep -c ^P: /lib/apk/db/installed
16
ana@vm:~/shelf$ docker run --rm debian:trixie-slim sh -c "ls /usr/bin | wc -l"
259
```

`debian:trixie` and `debian:trixie-slim` hold **the same 78 packages**. Slim is 68MB smaller because
it strips documentation, manual pages and locale files that a container never reads, not because it
has fewer programs. Both still have 259 programs in `/usr/bin` alone, a shell among them and `apt` to
install more. Alpine counts 16 packages. Distroless has no package manager to ask, and lesson 20's
scanner lists what is in it.

**What counts for security is not megabytes but what is inside.** A shell, a package manager,
`curl`: each is a tool an intruder would otherwise have to bring, and each is a package whose
vulnerabilities a scanner will report to you every week, whether your program uses it or not.

## Deleting in a later layer does not shrink anything

A Dockerfile that downloads an archive, unpacks it and deletes the archive looks tidy. Ana builds the
same thing two ways, with a 50 MB file standing in for the download:

```dockerfile
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50
RUN rm /tmp/download.tar
```

```dockerfile
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50 && rm /tmp/download.tar
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.layers -t layers:two .
sha256:e33a39afdeeb65a8dc7a3e3e21265f42e090b62b9d8fd92c6e3f7781a13cc71e
ana@vm:~/shelf$ docker build -q -f Dockerfile.onelayer -t layers:one .
sha256:c78a9b25f261d561b8369948a4b627faf0ebfe00ab8f7e5e7117b85f852b5404
ana@vm:~/shelf$ docker image ls layers
IMAGE        ID             DISK USAGE   CONTENT SIZE   EXTRA
layers:one   c78a9b25f261       12.8MB          3.8MB        
layers:two   e33a39afdeeb        118MB         56.2MB        
ana@vm:~/shelf$ docker history layers:two --format "{{.Size}}\t{{.CreatedBy}}" | head -3
8.19kB	RUN /bin/sh -c rm /tmp/download.tar # buildk…
52.4MB	RUN /bin/sh -c dd if=/dev/urandom of=/tmp/do…
0B	CMD ["/bin/sh"]
```

**`layers:two` is 56.2MB to download and `layers:one` 3.8MB**, though both end with the same files.
Lesson 4's layers explain it: the second `RUN` adds a layer containing a whiteout for
`/tmp/download.tar`, and the 52.4MB layer underneath still holds the file, so every pull still
carries it. Only removing the file in the same `RUN` that created it keeps it out of every layer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two images side by side, each a stack of layers. layers:two has alpine at the bottom, then a 52.4MB layer that holds /tmp/download.tar, then an 8.19kB layer with a whiteout that hides it; the download is 56.2MB. layers:one has alpine and one layer in which the file was created and deleted, so it holds nothing extra; the download is 3.8MB.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">layers:two</text><rect x=\"20\" y=\"136\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alpine:3.22</text><rect x=\"20\" y=\"84\" width=\"300\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">RUN dd …  52.4MB: download.tar</text><rect x=\"20\" y=\"50\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RUN rm …  whiteout, 8.19kB</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">to download: 56.2MB</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">layers:one</text><rect x=\"400\" y=\"136\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"412\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alpine:3.22</text><rect x=\"400\" y=\"102\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"412\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RUN dd … &amp;&amp; rm …  nothing left</text><text x=\"400\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">to download: 3.8MB</text></svg>", "caption": "A whiteout hides a file from the merged view; it does not remove it from the layer below, which every pull still downloads."}
```

That is why Dockerfiles join commands with `&&`:

```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
```

**That block was not built in the lab**, whose containers cannot reach Debian's package servers; it
is the standard shape, and hadolint asked for each of its parts in lesson 10. `--no-install-recommends`
skips packages that are suggested and not needed, and the `rm` deletes the package lists in the same
layer that downloaded them. The same reasoning applies to secrets: a file deleted in a later layer is
still in the earlier one, which is why lesson 11 kept `.env` out of the context altogether, and why
lesson 18 shows the right way to use a secret during a build.

## A checklist for the final stage

1. **Multi-stage**, so no compiler or source code is shipped (lesson 13).
2. **The smallest base the program runs on**: distroless or `scratch` for static binaries, `-slim`
   or Alpine when a shell or packages are genuinely needed.
3. **A numeric `USER`**, and only the directories it writes to handed over to it.
4. **Install, use and clean up in one `RUN`**, so nothing deleted remains in a layer.
5. **`.dockerignore`** with `.git` and every secret (lesson 11).
