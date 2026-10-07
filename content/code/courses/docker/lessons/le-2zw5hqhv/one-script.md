---
title: The pipeline is a script
version: 2
---

**A CI system runs commands on a machine that is not yours, every time somebody pushes.** The
commands are the part worth getting right, and lessons 20 and 25 already wrote them. This lesson puts
them in one script that a laptop and a CI runner both run, so that a failure in the pipeline can be
reproduced by typing one line, and nothing in the CI system's own configuration needs testing on its
own.

## The Dockerfile, ready for two architectures

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/probe ./probe

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

Two changes from lesson 25. **`FROM --platform=$BUILDPLATFORM`** runs the build stage on the machine's
own architecture, whatever image is being made, and **`GOOS` and `GOARCH`** from BuildKit's
`TARGETOS` and `TARGETARCH` make Go cross-compile for the target. An `arm64` image is then built on an
`amd64` runner at full speed, with no emulation: only the final stage, which runs no commands, is the
`arm64` distroless image. Lesson 13 introduced these arguments.

The pipeline leaves files in the project as it runs, a saved image, a log and a build record, and
the CI configuration lives beside the code. None of them belongs in an image, so the `.dockerignore`
grows again:

```
.git
.github
.env
*.env
*.log
*.tar
build.json
ci/
compose*.yaml
testdata/
Dockerfile*
.dockerignore
```

## The script

```sh
#!/bin/sh
# Tests, scans, builds and publishes shelf. The CI workflow runs exactly this,
# and so can anybody with Docker and a registry to push to.
set -eu

: "${REGISTRY:?set REGISTRY, for example ghcr.io/ana}"
REF_NAME=${REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}
REV=$(git rev-parse --short HEAD)
IMAGE=$REGISTRY/shelf

echo "--- unit tests"
docker build --target test --quiet . > /dev/null

echo "--- integration tests"
status=0
docker compose -f compose.test.yaml run --rm tests > integration.log 2>&1 || status=$?
docker compose -f compose.test.yaml down > /dev/null 2>&1
if [ "$status" -ne 0 ]; then cat integration.log; exit "$status"; fi

echo "--- scan"
docker build --quiet -t shelf:ci . > /dev/null
docker save shelf:ci -o shelf-ci.tar
docker run --rm -v "$PWD":/work -w /work ${TRIVY_CACHE:+-v "$TRIVY_CACHE":/cache} \
  aquasec/trivy:0.75.0 image --input shelf-ci.tar --scanners vuln --quiet \
  --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed \
  ${TRIVY_CACHE:+--cache-dir /cache} ${TRIVY_FLAGS:-}

echo "--- build and push"
case $REF_NAME in
  v*.*.*) version=${REF_NAME#v}
          tags="-t $IMAGE:$version -t $IMAGE:${version%.*} -t $IMAGE:${version%%.*}" ;;
  *)      version=dev
          tags="-t $IMAGE:$REF_NAME" ;;
esac
docker build --platform linux/amd64,linux/arm64 --build-arg VERSION="$version" \
  --cache-from "type=registry,ref=$IMAGE:buildcache" \
  --cache-to "type=registry,ref=$IMAGE:buildcache,mode=max" \
  --sbom=true --provenance=mode=min --metadata-file build.json \
  -t "$IMAGE:sha-$REV" $tags --push . > build.log 2>&1 || { tail -20 build.log; exit 1; }

digest=$(jq -r '."containerimage.digest"' build.json)
echo "pushed $IMAGE@$digest"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "digest=$digest" >> "$GITHUB_OUTPUT"
fi
```

Four steps, in order of cost, and **`set -e` makes the first failure the last step**: the unit tests
as lesson 25's test stage, the integration tests with Compose, the scan with lesson 20's gate, and
the multi-platform build and push. Everything that differs between a laptop and CI arrives through
environment variables: where to push, which ref is being built, and, for the lab, where Trivy's
offline database is.

## The first run

The registry on her machine is one on `127.0.0.1:5000` without a password, the kind lesson 15
started; `docker run -d --name registry -p 127.0.0.1:5000:5000 registry:3` starts one if yours is
gone. `TRIVY_FLAGS` in her command is the lab's: it tells Trivy to use the database lesson 20
fetched rather than ask for a new one, which the lab's containers cannot do. On your machine, leave
it out, and Trivy keeps `~/trivy-cache` up to date itself:

```sh
REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache sh ci/pipeline.sh; echo "exit $?"
```

Ana commits the files and runs it, pushing to the registry on her machine:

```
ana@vm:~/shelf$ git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "ci: one pipeline, run anywhere" && git log --oneline -1
cf9d1cf ci: one pipeline, run anywhere
ana@vm:~/shelf$ REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        1        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


shelf (gobinary)
================
Total: 1 (HIGH: 1, CRITICAL: 0)

┌───────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
│      Library      │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                            │
├───────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ golang.org/x/text │ CVE-2026-56852 │ HIGH     │ fixed  │ v0.29.0           │ 0.39.0        │ golang.org/x/text: golang.org/x/text: Denial of Service via │
│                   │                │          │        │                   │               │ invalid UTF-8 input                                         │
│                   │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-56852                  │
└───────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
exit 1
```

**The pipeline stopped at the scan**, on the finding lesson 20 found: `golang.org/x/text` v0.29.0,
high, with a fix. Nothing was built for release and nothing was pushed, and the exit status, 1, is
what turns a CI run red.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The pipeline as four steps in a row, each run only if the one before passed. Unit tests: docker build --target test. Integration tests: Compose with a throwaway Postgres. Scan: Trivy on the image, failing on fixable high or critical findings. Build and push: amd64 and arm64, with the registry cache, SBOM and provenance, tagged by commit and, on a release tag, by version. The output is the pushed digest, which a deployment uses. In Ana&#x27;s first run, the scan stopped the pipeline on golang.org/x/text; after the fix, all four passed.\"><defs><marker id=\"l26flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26flow-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">unit tests</text><text x=\"82\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">--target test</text><path d=\"M145 80 L170 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"170\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"232\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">integration</text><text x=\"232\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">compose run</text><path d=\"M295 80 L320 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"320\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"382\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">scan</text><text x=\"382\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">trivy</text><path d=\"M445 80 L470 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"470\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"532\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">build and push</text><text x=\"532\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">amd64 + arm64</text><path d=\"M595 80 L620 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"620\" y=\"55\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">digest</text><text x=\"660\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to deploy</text><path d=\"M382 110 L382 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-amber)\"></path><text x=\"382\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">first run: stopped here, x/text v0.29.0</text><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">any step that fails ends the run with its status; the next ones never start</text></svg>", "caption": "Each step is a gate. Nothing reaches the registry that did not pass every gate before it."}
```

She applies lesson 20's fix and commits it. On your machine, the `go get` is the form lesson 20 gives
without `-v ~/gopkg:/go/pkg` and `-e GOPROXY=off`:

```
ana@vm:~/shelf$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"
go: upgraded golang.org/x/sync v0.17.0 => v0.21.0
go: upgraded golang.org/x/text v0.29.0 => v0.39.0
ana@vm:~/shelf$ git -c user.name=Ana -c user.email=ana@example.com commit -qam "deps: golang.org/x/text v0.39.0" && git log --oneline -1
cb7eee2 deps: golang.org/x/text v0.39.0
```

```
ana@vm:~/shelf$ REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        0        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

--- build and push
pushed localhost:5000/shelf@sha256:0e344483f788353d143a67b428907299e4b8f6443b882f3e29e3c73c4686b6fa
exit 0
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags
["buildcache","main","sha-cb7eee2"]
```

**All four steps passed, and the script printed the digest it pushed.** The registry now holds the
image under `main`, the branch, and `sha-cb7eee2`, the commit, plus `buildcache`, which the next
section is about.
