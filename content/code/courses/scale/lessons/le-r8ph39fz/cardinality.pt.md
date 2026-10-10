---
title: Cardinalidade, o jeito de as métricas ficarem caras
version: 1
---

Toda combinação distinta dos rótulos de uma métrica é uma **série**, e o Prometheus guarda e indexa
cada série separadamente. Contá-las é uma consulta como qualquer outra:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'count by (__name__) ({__name__=~"tickets_.*"})'
tickets_requests_total => 7 @[1791612636.481]
tickets_request_seconds_bucket => 66 @[1791612636.481]
tickets_request_seconds_count => 6 @[1791612636.481]
tickets_request_seconds_sum => 6 @[1791612636.481]
tickets_in_flight => 3 @[1791612636.481]
```

Todo número se explica pelos rótulos:

- `tickets_in_flight` não tem rótulos, então uma série por cópia: **3**.
- `tickets_requests_total` tem `method`, `route` e `status`: cada cópia viu um `GET` que respondeu
  200 e um `POST` que respondeu 201, o que dá 6, e uma cópia ainda tem o 500 da última seção: **7**.
- `tickets_request_seconds_bucket` tem uma série por faixa, onze contando `+Inf`, para cada uma das
  duas rotas em cada uma das três cópias: **66**.

Cem séries não são nada. Um servidor Prometheus guarda milhões. O perigo é um rótulo com muitos
valores, porque **o número de séries é o produto do número de valores de todo rótulo**.

## O rótulo que teria custado um milhão de séries

O `observe` rotula cada pedido com `self.route`, o modelo `/events/{id}`. A alternativa óbvia é
`self.path`, o caminho como foi pedido. Ele teria produzido uma série por show para leituras, outra
por show para vendas, vezes onze faixas, vezes três cópias:

| rótulo | valores | séries de `tickets_request_seconds_bucket` |
|---|---|---|
| modelo da rota | 2 | 2 × 11 × 3 = **66** |
| caminho, com 100 shows | 200 | 200 × 11 × 3 = **6 600** |
| caminho, com 100 000 shows | 200 000 | 200 000 × 11 × 3 = **6 600 000** |

A última linha faria do sistema de monitoramento o maior problema da bilheteria: memória, disco,
consultas lentas, e uma conta proporcional se as métricas forem para um serviço hospedado. E nada
disso pareceria errado num teste com três shows.

**Rótulos são para dimensões com um conjunto pequeno e limitado de valores**: um modelo de rota, um
método, uma classe de status, uma região, uma cópia. Qualquer coisa por usuário, por pedido, por
ingresso ou por show pertence aos logs ou aos rastros, onde se espera que os detalhes de um evento
sejam únicos. A mesma regra apareceu como tags contra campos nas séries temporais da aula 4, porque
um sistema de monitoramento é uma.
