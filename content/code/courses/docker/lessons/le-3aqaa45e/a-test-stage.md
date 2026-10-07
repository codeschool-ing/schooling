---
title: A test stage in the Dockerfile
version: 1
---

**A multi-stage Dockerfile (lesson 13) can carry its tests as one more stage.** The stage starts
from the build stage, so it has the source, the modules and the compiler, and runs the checks:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 go build -o /out/probe ./probe

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

`--target test` asks for that stage by name:

```
ana@vm:~/shelf$ docker build --target test . 2>&1 | grep -E "^#[0-9]+ [0-9.]+ (=== RUN|--- |PASS|ok)|\[test" | awk '!seen[$0]++'
#13 [test 1/1] RUN go vet ./... && go test -v ./...
#13 5.819 === RUN   TestBooksAnswersWithTheCatalogue
#13 5.819 --- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
#13 5.819 === RUN   TestHealthIsOK
#13 5.819 --- PASS: TestHealthIsOK (0.00s)
#13 5.819 PASS
#13 5.819 ok  	example.com/shelf	0.004s
```

**`go vet` and both tests ran inside the build**, with the build stage's cache behind them. A plain
build of the image does something else:

```
ana@vm:~/shelf$ docker build -t shelf:1.7.0 . 2>&1 | grep -oE "\[(build|test|stage-2) [0-9]+/[0-9]+\]" | sort -u
[build 1/8]
[build 2/8]
[build 3/8]
[build 4/8]
[build 5/8]
[build 6/8]
[build 7/8]
[build 8/8]
[stage-2 1/2]
[stage-2 2/2]
```

**No `[test …]` step at all.** BuildKit works backwards from the stage it is asked for, and the final
stage copies only from `build`, so `test` is never needed and never runs. The tests cost nothing when
nobody asks for them, and none of their files reach the image.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The three stages of Ana&#x27;s Dockerfile as a graph. build, from golang:1.25, compiles shelf and probe. test starts FROM build and runs go vet and go test. The final stage, from distroless, copies the two binaries out of build. docker build --target test runs build and then test. A plain docker build runs build and the final stage, and skips test, because nothing the final stage needs comes from it.\"><defs><marker id=\"l25stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"80\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">build</text><text x=\"115\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compiles shelf, probe</text><rect x=\"300\" y=\"20\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">test</text><text x=\"385\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">go vet, go test</text><rect x=\"300\" y=\"140\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">final stage</text><text x=\"385\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">distroless and two binaries</text><path d=\"M200 100 L300 55\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l25stages-ah-amber)\"></path><text x=\"232\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">FROM build</text><path d=\"M200 120 L300 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l25stages-ah-phosphor)\"></path><text x=\"250\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">COPY --from</text><text x=\"500\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--target test</text><text x=\"500\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs build, then test</text><text x=\"500\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">plain docker build</text><text x=\"500\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs build, then this; skips test</text></svg>", "caption": "BuildKit runs only the stages the target needs. The tests run when asked for, and never ship."}
```

## When a test fails

A change to the code that breaks a test, the response to `/health` in capitals:

```
ana@vm:~/shelf$ sed -i "s/\"ok/\"OK/" main.go && git diff --stat
 main.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/shelf$ docker build --target test . > build.log 2>&1; echo "exit $?"
exit 1
ana@vm:~/shelf$ grep -E "main_test.go|FAIL" build.log | head -4
#13 5.646     main_test.go:29: got 200 "OK\n"
#13 5.646 --- FAIL: TestHealthIsOK (0.00s)
#13 5.646 FAIL
#13 5.646 FAIL	example.com/shelf	0.005s
ana@vm:~/shelf$ git checkout main.go
Updated 1 path from the index
```

**The build exits with status 1, and the log carries the test's own message**: `got 200 "OK\n"`. A
pipeline that runs `docker build --target test` stops right there, which is the point: the failing
code never becomes an image. `git checkout` restores the file.

One property of running tests in a build is worth knowing: **the step is cached like any other.** If
nothing it depends on has changed, the next build prints `CACHED` and does not run the tests again.
That is correct for unit tests, whose result depends only on the code; it is the reason a test that
talks to a database belongs in the next section instead.
