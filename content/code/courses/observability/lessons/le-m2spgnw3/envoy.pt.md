---
title: Envoy, o proxy por baixo
version: 1
---

A maioria dos meshes é construída sobre o **Envoy**, um proxy escrito na Lyft e hoje um projeto da CNCF. O
Istio o usa como sidecar, e vários outros também. Antes de rodar um mesh vale rodar o Envoy sozinho,
porque tudo o que um mesh faz é o Envoy configurado por outra pessoa.

O perfil `mesh` do laboratório sobe um Envoy com dois listeners. O primeiro fica na frente da storefront,
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

O Envoy mantém contadores para cada listener e cada upstream, na porta de administração:

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
