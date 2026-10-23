---
title: Images for other machines
version: 1
---

Cloud providers often rent `arm64` servers for less than `amd64` ones, and a laptop with an Apple chip is
`arm64` too. An image built on this machine is `amd64` and runs on neither. Section 04 already produces the
binary; **the image needs nothing more than to copy it**, which is why the Dockerfile named the binary
with `TARGETARCH`:

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-arm64 . && docker buildx build -q --platform linux/arm64 -t boxoffice:v0.16.0-arm64 --load .
sha256:6ddf079a2a22ff325159b631e82e0c540e41ee3e886933638d34950e2dbe4c3c
ana@vm:~/boxoffice$ docker image inspect --format "{{.Os}}/{{.Architecture}}" boxoffice:v0.16.0 boxoffice:v0.16.0-arm64
linux/amd64
linux/arm64
```

`docker buildx build --platform linux/arm64` builds for that platform: it takes the `arm64` variant of
distroless, sets `TARGETARCH` to `arm64`, and copies `dist/boxoffice-linux-arm64`. **Nothing was emulated**,
because nothing in the Dockerfile runs; the only step that had to happen on `arm64` was compiling, and Go
did that on `amd64`. `--load` puts the result among the machine's images, where `inspect` shows the two
architectures side by side.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"The boxoffice source goes through go build twice on one amd64 machine, with CGO_ENABLED=0 and GOARCH amd64 or arm64. Each build gives a binary in dist. The same Dockerfile copies each binary onto the matching variant of distroless static, giving two images, linux/amd64 and linux/arm64.\"><defs><marker id=\"gb-l16-two-images-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"90\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">boxoffice</text><text x=\"70\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><path d=\"M 125 115 L 145 115 L 145 65 L 163 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"165\" y=\"40\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">go build</text><text x=\"240\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GOARCH=amd64</text><path d=\"M 315 65 L 343 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"345\" y=\"40\" width=\"165\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"427\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">boxoffice-linux-amd64</text><path d=\"M 510 65 L 538 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"540\" y=\"40\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linux/amd64</text><text x=\"612\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">distroless + COPY</text><path d=\"M 125 115 L 145 115 L 145 175 L 163 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"165\" y=\"150\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">go build</text><text x=\"240\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GOARCH=arm64</text><path d=\"M 315 175 L 343 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"345\" y=\"150\" width=\"165\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"427\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">boxoffice-linux-arm64</text><path d=\"M 510 175 L 538 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"540\" y=\"150\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linux/arm64</text><text x=\"612\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">distroless + COPY</text><text x=\"240\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">CGO_ENABLED=0, on amd64</text></svg>", "caption": "Go compiles for the other processor; the Dockerfile only copies. Nothing is emulated."}
```

This machine cannot run the second one:

```
ana@vm:~/boxoffice$ docker run --rm boxoffice:v0.16.0-arm64; echo "exit $?"
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64/v4) and no specific platform was requested
exec /boxoffice: exec format error
exit 255
```

The kernel was handed an `arm64` program on an `amd64` processor and said so: `exec format error`. On an
`arm64` server it runs as the other one runs here. With both images in a registry under one name, a
multi-platform image, each server pulls the variant for its own processor; `docker buildx build` with
`--platform linux/amd64,linux/arm64` and `--push` builds and publishes that in one command.

## Building inside the image instead

Building the binary on your machine and copying it in is fast and easy to read, and it ties the image to
how your machine is set up. The other common shape builds inside a container, in two stages, so that any
machine with Docker produces the same image from the source:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.27.1 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags "-s -w" -o /boxoffice .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /boxoffice /boxoffice
ENV BOXOFFICE_HTTP=:8080 BOXOFFICE_GRPC=:9090
EXPOSE 8080 9090
ENTRYPOINT ["/boxoffice"]
```

The first stage has the whole Go toolchain, about a gigabyte of it, and none of it reaches the image:
`COPY --from=build` takes the one file. `--platform=$BUILDPLATFORM` runs that stage on the builder's own
processor and lets Go cross-compile, instead of emulating the target's processor for the whole build,
which is many times slower. Copying `go.mod` and `go.sum` and downloading before copying the source lets
Docker's cache keep the downloaded modules while only the code changes. **This file was not run for this
course**: the lab could not pull `golang:1.27.1`, because Docker Hub refused it with `429 Too Many
Requests`, its limit for anonymous pulls. It also needs the code sqlc and protoc generated in lessons 8
and 10 to be in the directory, where boxoffice keeps it.
