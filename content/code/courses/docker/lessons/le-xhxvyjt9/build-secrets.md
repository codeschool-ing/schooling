---
title: Secrets during a build
version: 1
---

**Some builds need a secret: a token for a private package registry, a key for a private Git
repository.** Lesson 14 showed that a file deleted in a later layer is still in the earlier one.
A secret passed as a build argument has a worse problem: it is never in a file at all, and it still
ends up in the image.

## A build argument leaks

The leaky way, written the way it often is: the token arrives as an `ARG`, is written to a
credentials file, used, and the file removed in the same `RUN`, which lesson 14 said is the right
way to clean up:

```dockerfile
FROM alpine:3.22
ARG REGISTRY_TOKEN
RUN printf 'machine git.example.com login ana password %s\n' "$REGISTRY_TOKEN" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.leak --build-arg REGISTRY_TOKEN=lab-only-token -t leak .
sha256:8359828ac1c7c56107d2b5740058490879b492fb05a3c039696f27c597ee6535
ana@vm:~/shelf$ docker history --no-trunc --format "{{.CreatedBy}}" leak | head -1
RUN |1 REGISTRY_TOKEN=lab-only-token /bin/sh -c printf 'machine git.example.com login ana password %s\n' "$REGISTRY_TOKEN" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc # buildkit
```

**`docker history` prints the token.** BuildKit records the build arguments a `RUN` used, with their
values, in the image's history: `|1 REGISTRY_TOKEN=lab-only-token`. The cleanup in the same layer kept
the file out; it could not keep the argument out. Anyone who can pull the image can read
the history, which, for an image pushed to a registry, is everyone with pull access.

The other usual mistakes leak the same way: `ENV` with a token stores it in the image's configuration,
and `COPY` of a credentials file stores it in a layer.

## A secret mount does not

BuildKit has a mount made for this. The secret is passed to `docker build` from a file, mounted
under `/run/secrets/` for the one `RUN` that asks for it, and written to no layer and no history:

```
lab-only-token
```

```dockerfile
FROM alpine:3.22
RUN --mount=type=secret,id=registry_token \
    printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
```

```
ana@vm:~/shelf$ docker build -f Dockerfile.secret --secret id=registry_token,src=token.txt -t no-leak . 2>&1 | grep -E "^#[0-9]+ \[2/2\]|fetched"
#5 [stage-0 2/2] RUN --mount=type=secret,id=registry_token     printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc
#5 0.156 fetched private dependencies
ana@vm:~/shelf$ docker history --no-trunc --format "{{.CreatedBy}}" no-leak | head -1
RUN /bin/sh -c printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc # buildkit
ana@vm:~/shelf$ docker run --rm no-leak ls /run/secrets /root
/root:
ls: /run/secrets: No such file or directory
```

**The `RUN` found the token and used it, the history shows the command with no value, and neither
`/run/secrets` nor the credentials file exists in the image.** `token.txt` itself stays on Ana's
machine, outside the image and, since `.dockerignore` does not cover it, worth adding there and to
`.gitignore` so that no `COPY . .` ever picks it up.

In a pipeline, the same flag takes the secret from an environment variable instead of a file,
`--secret id=registry_token,env=REGISTRY_TOKEN`, which is how lesson 26 would pass one from the CI
system's secret store.

**Runtime is a different problem.** A secret mount exists only while one `RUN` runs. A secret the
running program needs, like the database password of lesson 17, reaches the container when it
starts, through the options that lesson listed.
