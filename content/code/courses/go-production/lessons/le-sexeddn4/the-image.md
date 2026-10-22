---
title: An image with one program in it
version: 1
---

A container image is often pictured as a small virtual machine, with an operating system inside that
the program runs on. **An image is a stack of file archives and a few lines of configuration**:
unpacked one over another, the archives make the only files a process can see, and the configuration
says which program to start and as which user. There is no second kernel. The process runs on the
kernel of the machine like any other, fenced off from the rest of it.

So the question an image answers is which files the program gets to see. For section 02's static
`hits` the honest answer is almost none, and the job of this section is an image that holds the
binary and very little else. Lesson 17 installed Podman, rootless, so every command here runs as Ana
and needs no `sudo`.

## Two images to start from

Two base images, pulled once from their registries:

```
ana@vm:~/ship$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=docker.io/library/golang --filter reference=gcr.io/distroless/static-debian12
REPOSITORY                         TAG         SIZE
docker.io/library/golang           1.27.1      912 MB
gcr.io/distroless/static-debian12  nonroot     3.19 MB
```

**`golang:1.27.1` is a workshop of 912 MB**: Debian 13, `gcc`, `git` and the Go toolchain at exactly
the version this course uses. **`distroless/static-debian12` is 3.19 MB** and has no shell, no
package manager and no toolchain; section 04 opens it and counts what it does have. Building in the
first and shipping in the second is what a multi-stage build is for.

## The Containerfile

`Containerfile` is Podman's name for what Docker calls a `Dockerfile`, and Podman reads either. Put
this one at the top of `~/ship`, beside `go.mod`:

```schooling-example
{
  "language": "dockerfile",
  "file": "Containerfile",
  "parts": [
    {
      "code": "# Build hits in an image that has Go, then ship it in one that has\n# almost nothing.\nFROM docker.io/library/golang:1.27.1 AS build",
      "note": "**The first stage is a workshop.** The official `golang` image at exactly the Go this course uses, named `build` so the second stage can refer to it."
    },
    {
      "code": "WORKDIR /src\nCOPY . .",
      "note": "`WORKDIR` creates `/src` and makes it the current directory. `COPY . .` copies the build context into it: what `.containerignore` lets through, and nothing else."
    },
    {
      "code": "RUN CGO_ENABLED=0 go build -trimpath -ldflags=\"-s -w\" -o hits .",
      "note": "Section 02's release build, run inside the workshop. `hits` has no dependencies, so the step needs no network: nothing is downloaded."
    },
    {
      "code": "\nFROM gcr.io/distroless/static-debian12:nonroot",
      "note": "**The second stage is what ships.** Google's distroless image for static binaries, Debian 12 underneath, in the variant whose default user is not root."
    },
    {
      "code": "COPY --from=build /src/hits /hits",
      "note": "One file crosses from the workshop: the binary. The toolchain, the source and the build cache stay behind and are not in the image."
    },
    {
      "code": "ENTRYPOINT [\"/hits\"]",
      "note": "The program the image runs. Whatever follows the image name in `podman run` becomes its arguments, so `podman run hits:1 top -n 3` runs `/hits top -n 3`."
    }
  ]
}
```

**Each stage starts from its own `FROM`, and only the last stage becomes the image.** The first
exists to produce one file, and nothing from it travels unless a `COPY --from` asks for it by name.
With dependencies, a Go Containerfile usually copies `go.mod` and `go.sum` and runs `go mod
download` before copying the rest. The downloads then sit in a layer of their own and survive a
change to the code. `hits` has no dependencies, so that step would have nothing to do.

`COPY . .` copies the build context, the directory named at the end of `podman build`, and in
`~/ship` that directory holds `access.log`, two binaries, and, by section 05, a private signing key.
**A `.containerignore` file decides what enters the build**, and this one is a list of what may
rather than what may not. Save it as `.containerignore`:

```
# Nothing enters the build that the build does not need.
*
!go.mod
!*.go
!internal/
```

`*` excludes everything, and each `!` line lets one pattern back in: `go.mod`, the `.go` files at
the top, and the `internal` directory with everything under it. A file added to `~/ship` next month
stays out until somebody names it, which is the safe direction for a list like this to fail in.

## Building it

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 .
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1 AS build
[1/2] STEP 2/4: WORKDIR /src
--> c2a45fd9cbae
[1/2] STEP 3/4: COPY . .
--> e7ebcfe093bd
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
--> c1850bac5989
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
--> 446d8378012a
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
[2/2] COMMIT hits:1
--> db40eb60e402
Successfully tagged localhost/hits:1
db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
```

Two flags are doing work. **`--network=none` gives every `RUN` step no network at all**, and `hits`
builds anyway because there is nothing to download. This lab could not offer a network in any case:
its rootless Podman has no `/dev/net/tun` to build one from, and every `podman run` in this lesson
carries the same flag for the same reason. A build that does need modules needs a network for that
step, or the modules vendored into the context first. **`--cap-drop=all` takes away the powers root
normally has inside the build container**, which `go build` never uses. Two things followed from it.
Without the flag, this lab's Podman prints a warning for each of eleven capabilities it cannot
grant, which says nothing about the build. With it, root can no longer write to `/`, whose mode is
555 in the `golang` image. The first draft of this file built to `-o /hits` and stopped with `open
/hits: permission denied`, which is why the binary is built in `/src` and copied from there.

The lines starting `-->` are the id of each layer as it is committed, and they will differ on your
machine. What is left is a tag, `localhost/hits:1`, the name Podman gives an image that came from no
registry:

```
ana@vm:~/ship$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=localhost/hits
REPOSITORY      TAG         SIZE
localhost/hits  1           5.84 MB
```

**5.84 MB: the 3.19 MB base and the 2.65 MB binary**, against a workshop of 912 MB that never leaves
this machine.

## Running it

The program inside sees only the image's files, so the log has to be handed in. Two ways:

```
ana@vm:~/ship$ podman run --rm --network=none -i hits:1 top -n 3 < access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
ana@vm:~/ship$ podman run --rm --network=none -v "$PWD/access.log:/data/access.log:ro" hits:1 count /data/access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
```

**Lesson 1's numbers, to the request, from inside a container.** The first run uses the contract
lesson 1 built in: no file means standard input, `-i` keeps the container's standard input open, and
the shell feeds it the log. The second mounts the one file at `/data/access.log`, read-only because
of `:ro`, and names it as an argument. Everything after the image name became the arguments of
`/hits`, because the image's entry point is the program and not a shell. `--rm` deletes the
container when it exits, so nothing piles up.

As which user did it run?

```
ana@vm:~/ship$ podman image inspect --format "{{.Config.User}} {{.Config.Entrypoint}}" hits:1
65532 [/hits]
ana@vm:~/ship$ install -m 600 access.log private.log && podman run --rm --network=none -v "$PWD/private.log:/data/access.log:ro" hits:1 count /data/access.log; echo $?
hits: open /data/access.log: permission denied
1
ana@vm:~/ship$ podman run --rm --network=none -i hits:1 top -n 1 < private.log
path    requests
/login  2576
```

**User 65532, the `nonroot` of the image's tag**, set by the base image and inherited by `hits:1`.
It is nobody on Ana's machine either: rootless Podman maps the container's users onto a range of ids
set aside for Ana, and 65532 lands on one of those, which is not Ana. So a log that only Ana can
read, mode 600, cannot be opened through the mount, and `hits` says so and exits with 1, the status
lesson 1 gave a failed run. Through standard input it works, because the shell opening `private.log`
is Ana's. A program that breaks into the container it runs in finds itself an unprivileged user with
no shell to run, which is what the `nonroot` variant is for.

## The layers

```
ana@vm:~/ship$ podman history --format "{{.Size}}\t{{.CreatedBy}}" hits:1
0B	/bin/sh -c #(nop) ENTRYPOINT ["/hits"]
2.65MB	/bin/sh -c #(nop) COPY file:dc30b927acd5c4...
276kB	bazel build //common:cacerts_debian12_amd6...
3.07kB	bazel build //common:os_release_debian12
2.05kB	bazel build //static:nsswitch
1.54kB	bazel build //common:tmp
2.56kB	bazel build //common:group
2.56kB	bazel build //common:home
2.56kB	bazel build //common:passwd
1.54kB	bazel build //common:rootfs
102kB	bazel build @bookworm//media-types/amd64:d...
2.42MB	bazel build @bookworm//tzdata/amd64:data_s...
41kB	bazel build @bookworm//netbase/amd64:data_...
328kB	bazel build @bookworm//base-files/amd64:da...
```

Newest first. The top line is the configuration and has no files; the next is the binary; the twelve
below came with the base, built by Google with Bazel out of Debian 12 ("bookworm") packages. Drawn
to scale:

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" aria-label=\"The image hits:1 is a stack of 13 layers totalling 5.84 MB. The top layer, added by the second stage, is the hits binary at 2.65 MB. Below it are the 12 layers of the distroless base, 3.19 MB, of which the timezone data at 2.42 MB is nearly all; the certificate authorities take 276 kB, base-files 328 kB, media-types 102 kB, netbase 41 kB, and seven small layers such as passwd and group take about 2 to 3 kB each. Beside the stack, the build stage, the golang image of 912 MB, is never shipped; only one file crosses from it.\"><defs><marker id=\"l18a\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"115\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the build stage</text><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker.io/library/golang:1.27.1</text><text x=\"115\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">912 MB</text><text x=\"115\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">never shipped</text><text x=\"250\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the image hits:1: 13 layers, 5.84 MB</text><rect x=\"242\" y=\"104\" width=\"468\" height=\"342\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the base, distroless static-debian12:nonroot: 12 layers, 3.19 MB</text><text x=\"250\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">added by COPY --from=build</text><text x=\"350\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/hits</text><rect x=\"360\" y=\"73\" width=\"250.0\" height=\"16\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"618.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.65MB</text><text x=\"350\" y=\"141.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cacerts</text><rect x=\"360\" y=\"133\" width=\"26.0\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"394.0377358490566\" y=\"141.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">276kB</text><text x=\"350\" y=\"167.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">os_release</text><rect x=\"360\" y=\"159\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3.07kB</text><text x=\"350\" y=\"193.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nsswitch</text><rect x=\"360\" y=\"185\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.05kB</text><text x=\"350\" y=\"219.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tmp</text><rect x=\"360\" y=\"211\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.54kB</text><text x=\"350\" y=\"245.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">group</text><rect x=\"360\" y=\"237\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"271.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home</text><rect x=\"360\" y=\"263\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"297.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">passwd</text><rect x=\"360\" y=\"289\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"297.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.56kB</text><text x=\"350\" y=\"323.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rootfs</text><rect x=\"360\" y=\"315\" width=\"2.5\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"370.5\" y=\"323.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.54kB</text><text x=\"350\" y=\"349.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">media-types</text><rect x=\"360\" y=\"341\" width=\"9.6\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"377.62264150943395\" y=\"349.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">102kB</text><text x=\"350\" y=\"375.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tzdata</text><rect x=\"360\" y=\"367\" width=\"228.3\" height=\"16\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"596.3018867924528\" y=\"375.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.42MB</text><text x=\"350\" y=\"401.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">netbase</text><rect x=\"360\" y=\"393\" width=\"3.9\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"371.8679245283019\" y=\"401.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41kB</text><text x=\"350\" y=\"427.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">base-files</text><rect x=\"360\" y=\"419\" width=\"30.9\" height=\"16\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"398.9433962264151\" y=\"427.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">328kB</text><path d=\"M150,100 L150,91.0 Q150,81.0 160,81.0 L252,81.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l18a)\"></path><text x=\"200\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one file crosses</text><text x=\"360.0\" y=\"456\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ENTRYPOINT and USER are configuration, not layers</text></svg>",
  "caption": "The layers of hits:1, as podman history measured them, drawn to scale. Two layers are almost the whole image: the program and the timezone database."
}
```

**One layer is the program and one is the timezone database; the other eleven together weigh less
than a megabyte.** Layers are also the unit of reuse. Two images on the same base share those twelve
archives, on disk and in a registry. A second build reuses every layer whose instruction and inputs
have not changed:

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 .
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1 AS build
[1/2] STEP 2/4: WORKDIR /src
--> Using cache c2a45fd9cbae79191467b4f14c1201b4793135d395b5fb7e7445fcdf9da550af
--> c2a45fd9cbae
[1/2] STEP 3/4: COPY . .
--> Using cache e7ebcfe093bde879c89298633a2feec17339b9dda4eb313f9f0103b40c08e867
--> e7ebcfe093bd
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
--> Using cache c1850bac59892487e995b8e74275cd0a089be54d1a252b3932e111cf53d3e8e6
--> c1850bac5989
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
--> Using cache 446d8378012ab338929bd0ab7e685f5d84843a3574155b987c0b1a57df327e38
--> 446d8378012a
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
--> Using cache db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
[2/2] COMMIT hits:1
--> db40eb60e402
Successfully tagged localhost/hits:1
db40eb60e402aa2db03cf700ef07e6dc8529da79fb1491e15f9721ac096534ce
```

**Every step came from the cache and nothing was compiled.** Edit any `.go` file and `COPY . .` sees
different inputs, so it and every step after it run again; the two lines above it stay cached.
