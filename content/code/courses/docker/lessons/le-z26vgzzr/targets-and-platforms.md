---
title: Targets and platforms
version: 1
---

**A multi-stage Dockerfile is several images in one file, and two options pick which one you get and
for which processor.** `--target` stops at a named stage; `--platform` builds the result for other
architectures. Both come up as soon as a project has tests or a colleague with a different laptop.

## `--target`: an image for every purpose

The build stage has the compiler, the sources and the test files. Building only that stage gives an
image to run the tests in, from the same Dockerfile that builds the release:

```
ana@vm:~/shelf$ docker build -q --target build -t shelf:build .
sha256:52a2640724799ee551c6a1b0f13065b2b17b1366c4aa1dc6773df4f9cbff5e85
ana@vm:~/shelf$ docker run --rm shelf:build go test ./...
ok  	example.com/shelf	0.004s
```

The unit tests ran inside the build stage and passed. **One Dockerfile, two images**: the build
stage for checking the code, the last stage for shipping it. Lesson 25 builds a pipeline on
exactly this, including a stage whose only job is to run the tests.

## `--platform`: one tag for two processors

Lesson 3 showed that `alpine:3.22` is an index of images, one per platform, and lesson 5 that an
Apple silicon Mac wants `arm64`. Ana's images so far are `amd64` only. To publish both, she changes
two things in the Dockerfile:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
```

**`FROM --platform=$BUILDPLATFORM`** runs the build stage on the machine's own architecture, so the
compiler runs natively instead of under emulation; **`TARGETOS` and `TARGETARCH`**, set by the
builder for each requested platform, tell Go which binary to produce. Go cross-compiles by itself,
which is why the lab, with no emulator, can build an `arm64` binary at all:

```
ana@vm:~/shelf$ docker build -q --platform linux/amd64,linux/arm64 -t shelf:multi .
sha256:66f9e6d8778b3f48d483041f3d8ad512e67c0c9b6ef0b7378d1d1411ffebd5d0
ana@vm:~/shelf$ docker image ls --tree shelf:multi
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:multi          66f9e6d8778b       35.3MB         15.1MB   U    
├─ linux/amd64       942837d936de         28MB         7.84MB   U    
└─ linux/arm64       079f7bafb934        7.3MB          7.3MB        
```

**One tag, two images**, as `--tree` shows: `linux/amd64`, 28MB, unpacked because it is in use, and
`linux/arm64`, 7.3MB, stored but never unpacked on this machine. The final stage's base,
distroless, is itself published for both, so each platform got its own base too. Docker runs the
one matching the machine, and asking for the other gives lesson 2's error:

```
ana@vm:~/shelf$ docker run --rm -d --name multi-amd64 shelf:multi
510ab13d4a0e4c68b9d7d926defd52b40613ce357d2967bfa479ea1defabbbe7
ana@vm:~/shelf$ docker logs multi-amd64
2026/10/06 17:24:15 catalogue: built in, 3 books
2026/10/06 17:24:15 shelf dev listening on :8080
ana@vm:~/shelf$ docker run --rm --platform linux/arm64 shelf:multi
exec /shelf: exec format error
```

The `arm64` image is correct; this processor simply cannot run it. A Mac with Apple silicon pulling
`shelf:multi` from a registry gets that variant and runs it natively, and lesson 26 pushes such an
image from a pipeline. Languages that do not cross-compile as easily as Go build the other
platform's stage under QEMU emulation, which works and is much slower.
