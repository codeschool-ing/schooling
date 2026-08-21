# The production image. One binary, chosen by a build argument, on a base with
# no shell in it.
#
# WHAT MAKES IT DIFFERENT FROM deploy/local/Dockerfile is written in that file:
# the version stamped into the binary, and a base nobody can get a prompt on.
# The local one exists to be convenient; this one exists to be small and to say
# what it is.
#
# THE GO VERSION IS PASSED IN, NOT WRITTEN HERE. `go.mod` is the only place this
# project names one — it has already paid once for three places naming a Go
# version, two of them agreeing. The workflow reads it from `go.mod` and passes
# it, so a directive that moves cannot leave a Dockerfile behind.
ARG GO_VERSION=1.25

FROM golang:${GO_VERSION}-alpine AS build

ARG COMMAND=api
ARG VERSION=dev
ARG COMMIT=""
ARG BUILT=""

WORKDIR /src

# Dependencies first, so editing a source file does not re-download them.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# THE SAME STAMP THE RELEASE JOB CHECKS. `-trimpath` so the binary carries no
# path from the machine that built it, and `-s -w` because a symbol table is
# several megabytes of something nothing here reads.
RUN CGO_ENABLED=0 go build \
      -trimpath \
      -ldflags "-s -w \
        -X github.com/codeschool-ing/schooling/internal/platform/build.Version=${VERSION} \
        -X github.com/codeschool-ing/schooling/internal/platform/build.Commit=${COMMIT} \
        -X github.com/codeschool-ing/schooling/internal/platform/build.Built=${BUILT}" \
      -o /out/app ./cmd/${COMMAND}

# NO SHELL, NO PACKAGE MANAGER, NO libc. Whatever gets into this container finds
# a single static binary and nothing to run beside it — and `nonroot` means it
# is not root while finding out.
#
# It carries certificates, which is not optional: the process speaks TLS to the
# database, and without them that fails with an error about the handshake rather
# than about the certificates.
FROM gcr.io/distroless/static-debian12:nonroot AS binary

COPY --from=build /out/app /app

EXPOSE 8080
ENTRYPOINT ["/app"]

# AND ONE OF THEM CARRIES THE CATALOGUE.
#
# `cmd/load` reads `content/` off a filesystem — the files are the source of
# truth and the database is a mirror (C-01), so the thing that writes the mirror
# has to be able to read the files. 2.7 MB of Markdown, JSON and diagrams.
#
# IT IS A SEPARATE TARGET RATHER THAN A COPY IN EVERY IMAGE. The API never
# opens `content/`: it reads the mirror, which is the whole point of there being
# one. An image carrying a directory it cannot use is a reader wondering what
# reads it, and eventually somebody making it true.
FROM binary AS with-content

COPY --from=build /src/content /content
