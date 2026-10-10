---
title: Contadores, taxas e o que está acontecendo agora
version: 1
---

Com o Prometheus coletando três cópias, a bilheteria pode ser posta sob carga e perguntada sobre
ela **enquanto acontece**, pelos próprios números. Dois geradores de carga rodam por quarenta
segundos, um vendendo ingressos com 16 trabalhadores e um lendo páginas de show com 4; aos trinta
segundos, quatro perguntas em **PromQL**, a linguagem de consulta do Prometheus.

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum by (route, status) (rate(tickets_requests_total[30s]))'
{route="/events/{id}", status="200"} => 479.32289066666664 @[1791612608.076]
{route="/events/{id}/tickets", status="201"} => 337.5599133333333 @[1791612608.076]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum(tickets_in_flight)'
{} => 17 @[1791612608.539]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'rate(process_cpu_seconds_total[30s])'
{instance="172.18.0.5:8000", job="tickets"} => 0.7752 @[1791612608.875]
{instance="172.18.0.7:8000", job="tickets"} => 0.7855999999999999 @[1791612608.875]
{instance="172.18.0.8:8000", job="tickets"} => 0.7888 @[1791612608.875]
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'histogram_quantile(0.95, sum by (le, route) (rate(tickets_request_seconds_bucket[30s])))'
{route="/events/{id}"} => 0.019730909090909073 @[1791612609.274]
{route="/events/{id}/tickets"} => 0.1203033472803349 @[1791612609.274]
```

E o que os dois geradores imprimiram ao terminar:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 40 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  13250 in 40.0 s = 331.0 per second
latency   p50 38.7 ms  p95 118.0 ms  p99 179.3 ms  max 412.5 ms
status    201: 13250
```

```
ana@lab:~/tickets$ python3 load.py -c 4 -d 40 --events 100 'http://localhost:8080/events/{event}'
requests  18814 in 40.0 s = 470.3 per second
latency   p50 4.0 ms  p95 29.9 ms  p99 61.8 ms  max 285.8 ms
status    200: 18814
```

## A taxa: quão rápido um contador cresce

`rate(tickets_requests_total[30s])` é o aumento por segundo de cada contador nos últimos trinta
segundos, o que transforma "13 000 pedidos desde que a cópia começou" em **"pedidos por segundo
agora"**. `sum by (route, status)` soma as três cópias e mantém uma linha por rota e status.

A bilheteria diz **479 leituras e 338 vendas por segundo**. Os geradores dizem 470 e 331. A pequena
diferença é o que cada um mediu: os geradores tiraram a média de quarenta segundos incluindo os
primeiros instantes, enquanto a taxa cobre os últimos trinta, em velocidade plena. **Duas medidas
independentes da mesma coisa que concordam são a primeira conferência de que a instrumentação está
certa**, e vale fazê-la uma vez em qualquer sistema.

O `rate` lida com a propriedade incômoda dos contadores: quando uma cópia reinicia, o contador dela
volta a zero, e o `rate` trata a queda como um recomeço e não como uma taxa negativa. **Nunca faça
gráfico do valor cru de um contador**; faça da taxa.

## Saturação e utilização

`sum(tickets_in_flight)` é **17 pedidos em andamento** nas cópias naquele instante: os dezesseis
trabalhadores de venda e os quatro de leitura, menos os que estavam com a resposta a caminho. É a
saturação da bilheteria, o trabalho esperando ou sendo feito, e sob uma carga crescente é o número
que cresce primeiro.

`rate(process_cpu_seconds_total[30s])` é o uso de processador de cada cópia: **0,78 de um processador
cada**, três vezes. Cada cópia está limitada a um, e as três dividem os quatro do laboratório com o
nginx, o PostgreSQL, o Prometheus e os geradores, que é a medida horizontal da aula 1 vista por
dentro.

## O percentil, por dentro

A última consulta pede o percentil 95 da latência por rota, calculado a partir dos histogramas:
**120 ms para uma venda e 20 ms para uma leitura**. Os geradores mediram 118 ms e 30 ms. Por que eles
concordam nas vendas e não nas leituras, e por que nenhum dos dois números é exato, é a próxima
seção.
