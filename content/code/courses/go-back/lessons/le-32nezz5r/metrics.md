---
title: Numbers a machine can collect
version: 1
---

A log line describes one event. **A metric is a number kept over time**: how many requests, how long they
took, how many connections are open. Metrics are what dashboards draw and alerts fire on, because asking
"how many 500s in the last five minutes" of a number is instant, and of a log means reading every line.

Prometheus is the common way to collect them. A server exposes its numbers as text at an HTTP endpoint,
Prometheus fetches it every few seconds, a scrape, and stores each number as a time series. The Go
library that serves the format is `github.com/prometheus/client_golang`; `go mod tidy` brought in v1.25.0
for this lesson.

```go
// boxoffice/metrics.go
package main

import (
	"net/http"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	requests = prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "boxoffice_http_requests_total",
		Help: "HTTP requests answered, by route and status.",
	}, []string{"route", "status"})
	latency = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "boxoffice_http_request_duration_seconds",
		Help:    "How long HTTP requests took to answer, by route.",
		Buckets: []float64{.001, .005, .01, .05, .1, .5, 1, 5, 30},
	}, []string{"route"})
)

// measure counts and times every request by the route that matched it. It
// sits next to the mux, which writes the route into the request it is given.
func measure(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}
		next.ServeHTTP(rec, r)
		route := r.Pattern
		if route == "" {
			route = "unmatched" // never the path: one label value per URL would be unbounded
		}
		if rec.status == 0 {
			rec.status = http.StatusOK
		}
		requests.WithLabelValues(route, strconv.Itoa(rec.status)).Inc()
		latency.WithLabelValues(route).Observe(time.Since(start).Seconds())
	})
}

// metricsHandler serves everything boxoffice measures, in Prometheus' text format.
func metricsHandler(pool *pgxpool.Pool, live *hub) http.Handler {
	reg := prometheus.NewRegistry()
	reg.MustRegister(
		requests, latency,
		collectors.NewGoCollector(),
		collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}),
		prometheus.NewGaugeFunc(prometheus.GaugeOpts{
			Name: "boxoffice_live_watchers",
			Help: "Open server-sent event streams and WebSockets.",
		}, func() float64 { return float64(live.count()) }),
		prometheus.NewGaugeFunc(prometheus.GaugeOpts{
			Name: "boxoffice_db_connections_in_use",
			Help: "Database connections taken from the pool right now.",
		}, func() float64 { return float64(pool.Stat().AcquiredConns()) }),
	)
	return promhttp.HandlerFor(reg, promhttp.HandlerOpts{})
}
```

Three kinds of number appear:

- **A counter** only goes up: `boxoffice_http_requests_total`, one per request, labelled by route and
  status. The rate of a counter is what is interesting, and Prometheus computes it from two scrapes.
- **A histogram** counts observations into buckets: `boxoffice_http_request_duration_seconds`, how many
  requests took under 1 ms, under 5 ms, and so on up to 30 seconds. Percentiles are estimated from the
  buckets.
- **A gauge** goes up and down: the two `GaugeFunc`s read the hub's open subscriptions and the pool's
  connections in use at the moment of each scrape, so the number is never stale.

The Go and process collectors add the runtime's own numbers: goroutines, memory, garbage collection, open
files. `metricsHandler` registers everything on a registry of its own rather than the library's global
one, so nothing that some imported package registers behind your back ends up on the page.

## The route, never the path

`measure` labels each request with `r.Pattern`, the pattern the mux matched, such as
`GET /events/{id}`, never with the path. **Every distinct label value is a separate time series**, and a
path label would make one per event id, per typo, per scanner probing `/wp-admin`: unbounded, until
Prometheus runs out of memory. The pattern is one per route, a number you wrote.

That is why `measure` sits last in the chain, next to the mux. The mux writes the pattern into the request
it is given, and every middleware that calls `WithContext` passes a copy along. `measure` hands the mux
its own request unchanged, so after the call the pattern is there to read. Routes behind `requireStaff`
show as `/admin/`, the outer pattern, for the same reason. A request no route matched has no pattern and
is counted as `unmatched`.

```go
// boxoffice/routes.go
package main

import (
	"net/http"
	"net/url"
)

func routes(store Store, cfg config, live *hub) http.Handler {
	site, _ := url.Parse(cfg.Origin) // load has refused an origin that does not parse

	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))
	mux.HandleFunc("GET /events/{id}/live", liveEvents(store, live))
	mux.HandleFunc("GET /events/{id}/ws", liveSocket(store, live, site.Host))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(cfg.Tokens)(admin))

	return chain(mux, requestID, logRequests, recoverPanics, cors(cfg.Origin), measure)
}
```

## Reading them

With a stream open in another terminal, three requests for event 1, one for event 9 and one for a path that
does not exist:

```
ana@vm:~/boxoffice$ for i in 1 2 3; do curl -s -o /dev/null localhost:8080/events/1; done; curl -s -o /dev/null localhost:8080/events/9; curl -s -o /dev/null localhost:8080/nowhere
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep "^boxoffice_http_requests_total"
boxoffice_http_requests_total{route="GET /events/{id}",status="200"} 3
boxoffice_http_requests_total{route="GET /events/{id}",status="404"} 1
boxoffice_http_requests_total{route="GET /events/{id}",status="500"} 1
boxoffice_http_requests_total{route="unmatched",status="404"} 1
```

The 404 for event 9 is counted under its route, which is correct: the route exists and answered 404. The
500 is left from the database outage of section 03. `/nowhere` is `unmatched`. And the gauges, with the
runtime's numbers beside them:

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep -e "^boxoffice_live" -e "^boxoffice_db" -e "^go_goroutines" -e "^process_resident"
boxoffice_db_connections_in_use 0
boxoffice_live_watchers 1
go_goroutines 14
process_resident_memory_bytes 2.1164032e+07
```

One open stream, no database connections in use between requests, 14 goroutines and about 21 MB of
memory. These are the numbers somebody watches during an incident.
