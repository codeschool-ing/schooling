---
title: Envoy, the proxy underneath
version: 2
---

Most meshes are built on **Envoy**, a proxy written at Lyft and now a CNCF project. Istio uses it as its
sidecar, and so do several others. Before running a mesh it is worth running Envoy alone, because
everything a mesh does is Envoy configured by somebody else.

The lab's `mesh` profile starts one Envoy, and this is its configuration. Save it whole:

`~/shop/envoy/envoy.yaml`

```yaml
# Envoy for lesson 19: one proxy, two listeners, playing the part a mesh's
# sidecars play. :10000 sits in front of the storefront; :10001 sits between
# orders and payments, with a timeout and retries. :9901 is Envoy's admin page.
static_resources:
  listeners:
    - name: storefront
      address: {socket_address: {address: 0.0.0.0, port_value: 10000}}
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: storefront
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                      log_format:
                        json_format:
                          listener: storefront
                          method: "%REQ(:METHOD)%"
                          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                          code: "%RESPONSE_CODE%"
                          ms: "%DURATION%"
                          upstream_ms: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
                          attempts: "%UPSTREAM_REQUEST_ATTEMPT_COUNT%"
                          flags: "%RESPONSE_FLAGS%"
                route_config:
                  virtual_hosts:
                    - name: storefront
                      domains: ["*"]
                      routes:
                        - match: {prefix: /}
                          route: {cluster: storefront, timeout: 5s}
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
    - name: payments
      address: {socket_address: {address: 0.0.0.0, port_value: 10001}}
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: payments
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                      log_format:
                        json_format:
                          listener: payments
                          method: "%REQ(:METHOD)%"
                          path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                          code: "%RESPONSE_CODE%"
                          ms: "%DURATION%"
                          attempts: "%UPSTREAM_REQUEST_ATTEMPT_COUNT%"
                          flags: "%RESPONSE_FLAGS%"
                route_config:
                  virtual_hosts:
                    - name: payments
                      domains: ["*"]
                      routes:
                        - match: {prefix: /}
                          route:
                            cluster: payments
                            timeout: 2s
                            retry_policy:
                              retry_on: 5xx
                              num_retries: 2
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
  clusters:
    - name: storefront
      type: STRICT_DNS
      load_assignment:
        cluster_name: storefront
        endpoints: [{lb_endpoints: [{endpoint: {address: {socket_address: {address: storefront, port_value: 8080}}}}]}]
    - name: payments
      type: STRICT_DNS
      load_assignment:
        cluster_name: payments
        endpoints: [{lb_endpoints: [{endpoint: {address: {socket_address: {address: payments, port_value: 8082}}}}]}]
admin:
  address: {socket_address: {address: 0.0.0.0, port_value: 9901}}
```

Then start the lab again from nothing with the `mesh` profile, and set the customers going:

```sh
docker compose --profile '*' down -v
docker compose --profile mesh up -d
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
sleep 60
```

That Envoy has two listeners. The first sits in front of the storefront
on port 10000:

```
ana@obs:~/shop$ sed -n '/^  listeners:/,/^      filter_chains:/p' envoy/envoy.yaml
  listeners:
    - name: storefront
      address: {socket_address: {address: 0.0.0.0, port_value: 10000}}
      filter_chains:
```

A checkout through it works like one sent straight to the storefront:

```
ana@obs:~/shop$ curl -s -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}'
{"id":271,"qty":1,"sku":"kettle","status":"paid"}
```

And Envoy has already recorded it, in its access log, as one JSON line per request:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"storefront"' | tail -1 | jq -c .
{"attempts":1,"code":201,"flags":"-","listener":"storefront","method":"POST","ms":36,"path":"/checkout","upstream_ms":"35"}
```

The fields are the lab's choice, set in `envoy.yaml`. `ms` is the whole request as Envoy saw it, 36 milliseconds, and `upstream_ms` is the 35 the storefront took to answer, so the proxy's own share was one. `attempts` matters in the next section.

Envoy keeps counters for every listener and every upstream, on its admin port. Send twenty more
checkouts through it first, with lesson 1's `checkout.json`, and give them a few seconds:

```sh
for i in $(seq 1 20); do curl -s -o /dev/null -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d @checkout.json; done
```

Then the counters:

```
ana@obs:~/shop$ curl -s localhost:9901/stats | grep -E '^http\.storefront\.downstream_rq_(total|2xx|4xx|5xx):'
http.storefront.downstream_rq_2xx: 21
http.storefront.downstream_rq_4xx: 0
http.storefront.downstream_rq_5xx: 0
http.storefront.downstream_rq_total: 21
```

Twenty-one requests, all 2xx: the one above and twenty more sent through Envoy before the counters
were read. And it keeps latency histograms in Prometheus's format, ready to be scraped:

```
ana@obs:~/shop$ curl -s localhost:9901/stats/prometheus | grep -E '^envoy_cluster_upstream_rq_time_bucket\{envoy_cluster_name="storefront",le="(25|50|100)"\}'
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="25"} 0
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="50"} 18
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="100"} 21
```

The buckets are cumulative, like every Prometheus histogram: none of the 21 answered within 25 milliseconds, 18 within 50, and all of them within 100. Prometheus can scrape this endpoint like any other target, which gives a latency panel for every service behind the proxy with no instrumentation at all.

**None of this needed a line of the storefront's code.** That is the whole promise of a mesh, and also
its limit: Envoy knows the method, the path, the status and the time, and nothing about the kettle.
