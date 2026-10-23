---
title: Números que uma máquina consegue coletar
version: 1
---

Uma linha de log descreve um evento. **Uma métrica é um número mantido ao longo do tempo**: quantas
requisições, quanto tempo levaram, quantas conexões estão abertas. Métricas são o que os painéis desenham e
o que dispara alertas, porque perguntar "quantos 500 nos últimos cinco minutos" a um número é instantâneo, e
a um log significa ler cada linha.

O Prometheus é o jeito comum de coletá-las. Um servidor expõe seus números como texto num endpoint HTTP, o
Prometheus o busca a cada poucos segundos, uma coleta (scrape), e guarda cada número como uma série
temporal. A biblioteca Go que serve o formato é a `github.com/prometheus/client_golang`; o `go mod tidy`
trouxe a v1.25.0 para esta aula.

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

Aparecem três tipos de número:

- **Um contador** só sobe: `boxoffice_http_requests_total`, um por requisição, rotulado por rota e status.
  O que interessa num contador é a taxa, e o Prometheus a calcula a partir de duas coletas.
- **Um histograma** conta observações em buckets: `boxoffice_http_request_duration_seconds`, quantas
  requisições levaram menos de 1 ms, menos de 5 ms, e assim por diante até 30 segundos. Os percentis são
  estimados a partir dos buckets.
- **Um gauge** sobe e desce: os dois `GaugeFunc`s leem as inscrições abertas do hub e as conexões em uso do
  pool no momento de cada coleta, então o número nunca está velho.

Os coletores de Go e de processo acrescentam os números do próprio runtime: goroutines, memória, coleta de
lixo, arquivos abertos. O `metricsHandler` registra tudo num registro próprio, e não no global da
biblioteca, para nada que algum pacote importado registre pelas suas costas aparecer na página.

## A rota, nunca o caminho

O `measure` rotula cada requisição com `r.Pattern`, o padrão que o mux casou, como `GET /events/{id}`,
nunca com o caminho. **Cada valor distinto de rótulo é uma série temporal separada**, e um rótulo de
caminho criaria uma por id de evento, por erro de digitação, por varredura procurando `/wp-admin`: sem
limite, até o Prometheus ficar sem memória. O padrão é um por rota, um número que você escreveu.

É por isso que o `measure` fica por último na cadeia, junto ao mux. O mux escreve o padrão na requisição
que recebe, e todo middleware que chama `WithContext` passa uma cópia adiante. O `measure` entrega ao mux a
sua própria requisição, sem mudança, então depois da chamada o padrão está lá para ler. As rotas atrás do
`requireStaff` aparecem como `/admin/`, o padrão de fora, pelo mesmo motivo. Uma requisição que nenhuma rota
casou não tem padrão e é contada como `unmatched`.

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

## Lendo

Com um stream aberto em outro terminal, três requisições para o evento 1, uma para o evento 9 e uma para um
caminho que não existe:

```
ana@vm:~/boxoffice$ for i in 1 2 3; do curl -s -o /dev/null localhost:8080/events/1; done; curl -s -o /dev/null localhost:8080/events/9; curl -s -o /dev/null localhost:8080/nowhere
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep "^boxoffice_http_requests_total"
boxoffice_http_requests_total{route="GET /events/{id}",status="200"} 3
boxoffice_http_requests_total{route="GET /events/{id}",status="404"} 1
boxoffice_http_requests_total{route="GET /events/{id}",status="500"} 1
boxoffice_http_requests_total{route="unmatched",status="404"} 1
```

O 404 do evento 9 é contado sob a rota dele, o que está certo: a rota existe e respondeu 404. O 500 sobrou
da queda do banco da seção 03. O `/nowhere` é `unmatched`. E os gauges, com os números do runtime ao lado:

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep -e "^boxoffice_live" -e "^boxoffice_db" -e "^go_goroutines" -e "^process_resident"
boxoffice_db_connections_in_use 0
boxoffice_live_watchers 1
go_goroutines 14
process_resident_memory_bytes 2.1164032e+07
```

Um stream aberto, nenhuma conexão com o banco em uso entre requisições, 14 goroutines e uns 21 MB de
memória. São os números que alguém observa durante um incidente.
