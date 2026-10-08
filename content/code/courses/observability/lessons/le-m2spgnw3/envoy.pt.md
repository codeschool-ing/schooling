---
title: Envoy, o proxy por baixo
version: 2
---

A maioria dos meshes é construída sobre o **Envoy**, um proxy escrito na Lyft e hoje um projeto da CNCF. O
Istio o usa como sidecar, e vários outros também. Antes de rodar um mesh vale rodar o Envoy sozinho,
porque tudo o que um mesh faz é o Envoy configurado por outra pessoa.

O perfil `mesh` do laboratório sobe um Envoy, e esta é a configuração dele. Salve-a inteira:

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

Depois inicie o laboratório de novo do zero com o perfil `mesh`, e ponha os clientes para rodar:

```sh
docker compose --profile '*' down -v
docker compose --profile mesh up -d
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
sleep 60
```

Esse Envoy tem dois listeners. O primeiro fica na frente da storefront,
na porta 10000:

```
ana@obs:~/shop$ sed -n '/^  listeners:/,/^      filter_chains:/p' envoy/envoy.yaml
  listeners:
    - name: storefront
      address: {socket_address: {address: 0.0.0.0, port_value: 10000}}
      filter_chains:
```

Um checkout por ele funciona como um mandado direto para a storefront:

```
ana@obs:~/shop$ curl -s -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}'
{"id":271,"qty":1,"sku":"kettle","status":"paid"}
```

E o Envoy já o registrou, no log de acesso, como uma linha JSON por requisição:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"storefront"' | tail -1 | jq -c .
{"attempts":1,"code":201,"flags":"-","listener":"storefront","method":"POST","ms":36,"path":"/checkout","upstream_ms":"35"}
```

Os campos são escolha do laboratório, definidos no `envoy.yaml`. `ms` é a requisição inteira como o Envoy a viu, 36 milissegundos, e `upstream_ms` são os 35 que a storefront levou para responder; a parte do próprio proxy foi de um. O `attempts` importa na próxima seção.

O Envoy mantém contadores para cada listener e cada upstream, na porta de administração. Mande antes
mais vinte checkouts por ele, com o `checkout.json` da aula 1, e dê a eles alguns segundos:

```sh
for i in $(seq 1 20); do curl -s -o /dev/null -X POST localhost:10000/checkout -H 'Content-Type: application/json' -d @checkout.json; done
```

Depois, os contadores:

```
ana@obs:~/shop$ curl -s localhost:9901/stats | grep -E '^http\.storefront\.downstream_rq_(total|2xx|4xx|5xx):'
http.storefront.downstream_rq_2xx: 21
http.storefront.downstream_rq_4xx: 0
http.storefront.downstream_rq_5xx: 0
http.storefront.downstream_rq_total: 21
```

Vinte e uma requisições, todas 2xx: a de cima e mais vinte mandadas pelo Envoy antes da leitura dos contadores. E mantém histogramas de latência no formato do Prometheus, prontos para a coleta:

```
ana@obs:~/shop$ curl -s localhost:9901/stats/prometheus | grep -E '^envoy_cluster_upstream_rq_time_bucket\{envoy_cluster_name="storefront",le="(25|50|100)"\}'
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="25"} 0
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="50"} 18
envoy_cluster_upstream_rq_time_bucket{envoy_cluster_name="storefront",le="100"} 21
```

Os buckets são cumulativos, como em todo histograma do Prometheus: nenhuma das 21 respondeu em até 25 milissegundos, 18 em até 50, e todas em até 100. O Prometheus pode coletar esse endpoint como qualquer outro alvo, o que dá um painel de latência para cada serviço atrás do proxy sem instrumentação nenhuma.

**Nada disso precisou de uma linha do código da storefront.** Essa é toda a promessa de um mesh, e também
o seu limite: o Envoy sabe o método, o caminho, o status e o tempo, e nada sobre a chaleira.
