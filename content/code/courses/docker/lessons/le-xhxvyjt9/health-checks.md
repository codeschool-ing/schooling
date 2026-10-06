---
title: Health checks
version: 1
---

**`docker ps` says `Up` when the process is running. It cannot say whether the program is doing its
job.** A web server that is deadlocked, or listening on the wrong port, is `Up` all the same. A
**health check** is a command Docker runs inside the container at intervals: exit status 0 means
healthy, anything else means not.

## A check for an image with no shell

The usual example is `curl -f http://localhost/health`, and distroless has no `curl`, no `wget` and no
shell to run them in, on purpose (lesson 14). So `shelf` gets a check of its own: a second, tiny Go
program built in the same stage and copied next to it.

```go
// probe exits 0 when a GET of its one argument answers 200, and 1 otherwise.
// It is the health check for an image that has no shell and no curl.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	c := http.Client{Timeout: 2 * time.Second}
	r, err := c.Get(os.Args[1])
	if err != nil || r.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
```

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

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

**The options say how impatient to be.** Every 5 seconds, run `/probe`, give up on it after 2, ignore
failures during the first 5 while the program starts, and call the container unhealthy after 3
failures in a row. Docker's defaults are 30 seconds for both the interval and the timeout, no start
period and 3 retries; `shelf` starts in milliseconds, so shorter numbers cost nothing here.

```
ana@vm:~/shelf$ docker run -d --name web shelf:1.4.0
ca80a22cedbe6b4c1dd540e238384efc19e54d9a502cf1958fc7a7b06d3240ed
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Up Less than a second (health: starting)
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Up 8 seconds (healthy)
ana@vm:~/shelf$ docker inspect web --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"
{
  "Status": "healthy",
  "FailingStreak": 0,
  "last": {
    "Start": "2026-10-06T18:06:14.52663257Z",
    "End": "2026-10-06T18:06:14.583389803Z",
    "ExitCode": 0,
    "Output": ""
  }
}
```

`health: starting` on the first look, `healthy` eight seconds later, and `.State.Health` keeps the
last results with their exit codes.

## What unhealthy looks like

Ana starts a second container with `PORT=9090`, so `shelf` listens on 9090 while the check asks 8080:

```
ana@vm:~/shelf$ docker run -d --name web-9090 -e PORT=9090 shelf:1.4.0
d97bc4897c4d2e94e20b60bcb1226de4ffdf894deddadae78ffab4a4250941d7
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES      STATUS
web-9090   Up 25 seconds (unhealthy)
web        Up 33 seconds (healthy)
ana@vm:~/shelf$ docker inspect web-9090 --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"
{
  "Status": "unhealthy",
  "FailingStreak": 4,
  "last": {
    "Start": "2026-10-06T18:06:38.018910328Z",
    "End": "2026-10-06T18:06:38.078279822Z",
    "ExitCode": 1,
    "Output": ""
  }
}
```

**`Up 25 seconds (unhealthy)`, four failures in a row.** Without the check, this container would look
exactly like the healthy one, and only a user would find out. That is the value of the check: it
tests what the program is for, from inside, on a schedule.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The three health states of a container with a HEALTHCHECK. It starts in starting. The check runs every interval, five seconds for shelf; failures during the start period of five seconds do not count. One passing check moves it to healthy. From healthy, three failing checks in a row, the retries, move it to unhealthy, and one passing check moves it back to healthy. Docker itself takes no action on unhealthy: the container keeps running, and an orchestrator or a person has to act on the state.\"><defs><marker id=\"l18health-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18health-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.8\"></rect><text x=\"100\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">starting</text><rect x=\"290\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">healthy</text><rect x=\"550\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"620\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">unhealthy</text><path d=\"M170 105 L290 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-phosphor)\"></path><text x=\"230\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one check passes</text><path d=\"M430 95 L550 95\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-amber)\"></path><text x=\"490\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">retries=3 fail</text><path d=\"M550 118 L430 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-phosphor)\"></path><text x=\"490\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one passes</text><text x=\"100\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">start-period=5s:</text><text x=\"100\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">failures do not count</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked every</text><text x=\"360\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">interval=5s</text><text x=\"620\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">still running:</text><text x=\"620\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Docker does nothing</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each check: /probe http://127.0.0.1:8080/health, exit 0 passes, anything else fails, timeout=2s</text></svg>", "caption": "A health check reports; it does not repair. The state is something else's cue."}
```

**And Docker, on its own, does nothing about it.** The container keeps running, unhealthy, until
something acts on the state. Compose can wait for a service to be healthy before starting the ones
that depend on it, which lesson 19 uses for the database. Swarm replaces unhealthy containers.
Kubernetes ignores `HEALTHCHECK` entirely and has its own probes, which lesson 22 of the
`kubernetes` course covers; the `/health` endpoint is what they call, so the work carries over.
