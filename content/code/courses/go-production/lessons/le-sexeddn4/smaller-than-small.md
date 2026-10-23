---
title: Scratch, distroless and the files in between
version: 1
---

If 3.19 MB of base is good, no base must be better, and containers have a name for no base: `FROM
scratch`, an image that starts with no files at all. For `hits` it would work, because `hits` opens
nothing but the log. **For most programs, scratch removes files that the program reads without its
author ever thinking of them as dependencies**: the user database, the timezone rules, the
certificate authorities. Section 02's `probe` asks for exactly those three, which makes it the right
program to put on both bases.

## No shell to go into

First, what is missing from the distroless image on purpose:

```
ana@vm:~/ship$ podman run --rm --network=none --entrypoint sh hits:1; echo $?
Error: runc: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH: OCI runtime attempted to invoke a command that was not found
127
```

`--entrypoint` replaces the program the image starts, and there is no `sh` to start: **127 is the
shell's "no such command" from lesson 1's lab section, returned here by Podman.** No shell means no
`ls`, no `cat` and no `podman exec -it … sh` to look around a running container. It also means that
somebody who finds a hole in the program has no shell to run either. The files are still reachable
from outside, and the next listing comes from them. For the days when a shell is worth the risk,
distroless publishes `:debug` variants of each image with a BusyBox shell in `/busybox/sh`; they are
for a terminal, never for a deployment.

## The same program on two bases

`probe/Containerfile` takes the base as a build argument and copies in a binary built on the host,
which is the other way to fill an image when the build has already happened:

`probe/Containerfile`:

```dockerfile
# One binary built on the host, on top of whatever BASE names.
ARG BASE=scratch
FROM $BASE
COPY probe /probe
ENTRYPOINT ["/probe"]
```

`ARG` before `FROM` declares a value the `FROM` line can use, with `scratch` as the default and
`--build-arg` to change it. The `probe` in `~/ship/probe` is section 02's last build, with cgo off.
Built twice, run twice:

```
ana@vm:~/ship/probe$ podman build -q --cap-drop=all -t probe:scratch .
554647b21915ba63f0bfed6bdf56d802bddf8f3c591e116825594448482d3e71
ana@vm:~/ship/probe$ podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:distroless .
a404e0e86b59064ec1699b0ba238a34b7199c06b25663328e0a33e4786b9ad9d
ana@vm:~/ship/probe$ podman run --rm --network=none probe:scratch
user:  user: Current requires cgo or $USER set in environment
zone:  unknown time zone America/Sao_Paulo
certs: 0 authorities
ana@vm:~/ship/probe$ podman run --rm --network=none probe:distroless
user:  nonroot 65532 /home/nonroot
zone:  09:00 -03
certs: 150 authorities
ana@vm:~/ship/probe$ podman images --format 'table {{.Repository}} {{.Tag}} {{.Size}}' --filter reference=localhost/probe
REPOSITORY       TAG         SIZE
localhost/probe  distroless  7.71 MB
localhost/probe  scratch     4.52 MB
```

**On scratch, all three questions fail, and the third fails without an error.** `user.Current` found
no `/etc/passwd` and said what it would need instead. `time.LoadLocation` found no zone files.
`x509.SystemCertPool` found no bundle and returned an empty pool with a `nil` error, so `probe`
printed `0 authorities`. A real program would carry on, open its first HTTPS connection and fail
there, with a message about an unknown authority that seems to blame the server. **On distroless,
all three answer**, from the image's own files: the `nonroot` account, Debian's zone rules, and
Debian's bundle of 150 authorities, which is not the 127 of Ana's Ubuntu. The difference in size is
3.19 MB, the base, to the hundredth.

## What the 3.19 MB holds

The image has no shell to list itself with, so the listing is done from outside. `podman export`
writes a container's whole filesystem as a tar archive:

```
ana@vm:~/ship$ podman create --name peek hits:1 >/dev/null && podman export peek > peek.tar && podman rm peek >/dev/null
ana@vm:~/ship$ tar -tf peek.tar | wc -l; tar -tf peek.tar | grep -c zoneinfo/
1436
1308
ana@vm:~/ship$ tar -tf peek.tar | grep -E "^(etc/(passwd|group|nsswitch.conf)|etc/ssl/certs/.*|bin/.*|hits)$"
bin/
etc/group
etc/nsswitch.conf
etc/passwd
etc/ssl/certs/
etc/ssl/certs/ca-certificates.crt
hits
ana@vm:~/ship$ tar -xOf peek.tar etc/passwd
root:x:0:0:root:/root:/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin
nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
```

**1,436 entries, and 1,308 of them are the timezone database.** The rest is the handful of files a
program assumes: a three-line `/etc/passwd` naming the `nonroot` user that `podman image inspect`
reported as 65532, `/etc/group`, `nsswitch.conf`, one bundle of certificates, a few Debian files
such as the licences, and an empty `bin/`. Every login shell in it is `/sbin/nologin`, which is not
in the image either.

Each of those can be added to a scratch image by hand. **`-tags timetzdata` embeds the zone rules in
the binary**, through the standard library's `time/tzdata` package:

```
ana@vm:~/ship/probe$ CGO_ENABLED=0 go build -tags timetzdata -o probe-tz . && stat -c "%s bytes  %n" probe probe-tz
4518294 bytes  probe
4928878 bytes  probe-tz
```

410,584 bytes more, which the package documentation rounds to "about 450 KB". The certificate bundle
can be copied out of the `golang` build stage with a `COPY --from`, and a passwd file written by
hand. All three are then files you maintain: authorities are added to a bundle and others are
distrusted, and zone rules change whenever a government moves a clock. **Distroless is those same
files, kept current by somebody else**, for 3.19 MB, and that is the case for it over scratch in one
sentence.

## A dynamic binary on a static base

Section 02 promised a misleading message. Here is `probe` built with cgo on, dynamically linked
against the C library, put on the same distroless base:

```
ana@vm:~/ship/probe$ CGO_ENABLED=1 go build -o probe . && podman build -q --cap-drop=all --build-arg BASE=gcr.io/distroless/static-debian12:nonroot -t probe:dynamic .
9daf041528438993051de6f33e873c58a1472cef0681d45d1c5e5218e74d0159
ana@vm:~/ship/probe$ podman run --rm --network=none probe:dynamic; echo $?
exec /probe: no such file or directory
255
```

**`/probe` is there; the file that is missing is `/lib64/ld-linux-x86-64.so.2`**, the loader `ldd`
named in section 02, which the kernel needs before it can start a dynamically linked program. The
kernel reports that as "no such file" and does not say which file. The cure is `CGO_ENABLED=0`, or,
for a program that really needs the C library, `gcr.io/distroless/base-debian12`, which adds glibc.
`static` in the image's name means "for static binaries", which is exactly the condition this one
broke.

## Which image, exactly

`:nonroot` is a tag, and a tag is a name its owner can point at a different image tomorrow, when
Debian publishes a fix or the certificate bundle changes. **A digest is the SHA-256 of what the
registry served**, and it can only ever name those bytes:

```
ana@vm:~/ship$ podman image inspect --format "{{.Digest}}" gcr.io/distroless/static-debian12:nonroot
sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
ana@vm:~/ship$ podman manifest inspect gcr.io/distroless/static-debian12@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab | jq -r ".manifests[] | .platform.architecture + \" \" + .digest"
amd64 sha256:52dcfbabb7457ea47c82f6e13af8c8a4a1d9f7b0145142b3ecab20f2b888411d
arm64 sha256:06c3c14b7fa252d9f4285242d2d665ce3b51f74b02d3c529464f220f2912aecb
arm sha256:ed55430d277931fc5a82b9994d26933d21dca79b95f4e4290168c4d894da7b3a
s390x sha256:f8f7116c7de2f0c41b95a8dd068b9a0afb099c0663c9b75192e935d1b8ac4f15
ppc64le sha256:9154fe977c987d184361dcf0943da6a06505723bf9e9e25289407d434decd6d4
```

The digest Ana pulled names an index, and the index names one image per processor, five of them,
each with its own digest. Podman picked `amd64` for this machine, and on an ARM server the same
`FROM` line would pick the `arm64` one: lesson 16's cross-compilation, at the scale of a whole
image. **Pinning the index digest fixes every platform at once.** Written beside the tag, the tag
stays for people and the digest decides; replace `Containerfile` with this:

`Containerfile`:

```dockerfile
# Build hits in an image that has Go, then ship it in one that has
# almost nothing. Each base is named by digest; the tag is for people.
FROM docker.io/library/golang:1.27.1@sha256:162be5298a40ed317005c8339c6de4d10d3eef336d66dc8e9259b03ab9d3a6d2 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /src/hits /hits
ENTRYPOINT ["/hits"]
```

```
ana@vm:~/ship$ podman build --cap-drop=all --network=none -t hits:1 . | grep -e STEP -e COMMIT
[1/2] STEP 1/4: FROM docker.io/library/golang:1.27.1@sha256:162be5298a40ed317005c8339c6de4d10d3eef336d66dc8e9259b03ab9d3a6d2 AS build
[1/2] STEP 2/4: WORKDIR /src
[1/2] STEP 3/4: COPY . .
[1/2] STEP 4/4: RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits .
[2/2] STEP 1/3: FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
[2/2] STEP 2/3: COPY --from=build /src/hits /hits
[2/2] STEP 3/3: ENTRYPOINT ["/hits"]
[2/2] COMMIT hits:1
```

The build used the images already on this machine, because they are the ones those digests name. A
year from now the same file builds on the same bases, and moving to a newer distroless is an edit
somebody makes, reviews and can undo, not something that happened overnight. The price is that the
fixes do not arrive by themselves either, so a pinned base needs somebody, or a bot, to bump it on
purpose.
