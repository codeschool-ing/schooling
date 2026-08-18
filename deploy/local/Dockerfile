# One Dockerfile for both commands, picked by a build argument. They share
# every layer up to the build itself, so the second image costs a compile
# rather than a base image and a dependency download.
#
# This one is for local development. The production image arrives with the
# deploy pipeline and will differ in two ways that matter: the version stamped
# into the binary, and a base with no shell in it.

# The tag tracks go.mod's directive. Alpine's Go images carry no toolchain
# downloader worth relying on, so a base older than the directive fails the
# build here rather than in production.
FROM golang:1.25-alpine AS build

ARG COMMAND=api

WORKDIR /src

# Dependencies first, so editing a source file does not re-download them.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO off so the binary runs on a base image with no libc of its own.
RUN CGO_ENABLED=0 go build -o /out/app ./cmd/${COMMAND}

FROM alpine:3.22

# Certificates, because the process talks to a database over TLS in production
# and to the payment gateway later. Absent, both fail with an error that says
# nothing about certificates.
RUN apk add --no-cache ca-certificates

# Never root. There is nothing in this container that needs it, and the day
# something is wrong is the day that matters.
RUN adduser -D -u 65532 app
USER 65532:65532

COPY --from=build /out/app /usr/local/bin/app

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/app"]
