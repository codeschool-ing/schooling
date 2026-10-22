---
title: O que medir, e o que não
version: 1
---

Um serviço consegue expor milhares de números, e ninguém lê milhares de números. **Para qualquer coisa que
responde requisições, três cobrem quase tudo o que importa**, um conjunto que muitos chamam de RED:

| | a pergunta | no boxoffice |
|---|---|---|
| **R**ate, a taxa | quantas requisições por segundo | `rate(boxoffice_http_requests_total[5m])` |
| **E**rrors, os erros | quantas delas falharam | o mesmo contador, com `status=~"5.."` |
| **D**uration, a duração | quanto tempo levaram | `boxoffice_http_request_duration_seconds` |

As expressões da última coluna são PromQL, a linguagem de consulta do Prometheus. Este curso não instalou o
Prometheus, então elas não foram executadas; o curso `observability` monta um servidor Prometheus na sua
aula 5. O que o servidor guarda é o que o endpoint mostra, e isso dá para ler aqui.

## Um histograma, como é guardado

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | grep "duration_seconds.*GET /events/{id}\""
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.001"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.005"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.01"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.05"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.1"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="0.5"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="1"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="5"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="30"} 5
boxoffice_http_request_duration_seconds_bucket{route="GET /events/{id}",le="+Inf"} 5
boxoffice_http_request_duration_seconds_sum{route="GET /events/{id}"} 0.0017760939999999998
boxoffice_http_request_duration_seconds_count{route="GET /events/{id}"} 5
```

Cada linha `bucket` é uma contagem acumulada: requisições que levaram no máximo `le` segundos. As cinco
levaram menos de um milissegundo, então todo bucket diz 5, e `_sum` e `_count` dão a média, menos de meio
milissegundo. **Um histograma guarda a forma que uma média esconde.** Se cem requisições levam 2 ms e uma
leva 4 segundos, a média é 42 ms e não descreve nenhuma delas; os buckets mostram cem requisições rápidas e
uma lenta, e o percentil 99, estimado a partir deles, é o que sente um usuário esperando na fila atrás da
lenta.

Os buckets são escolhidos uma vez, no código, e devem cercar o que importa para o serviço: aqui de um
milissegundo, uma leitura rápida, a trinta segundos, um stream fechado cedo. **Streams longos caem nos
buckets de cima**, outro motivo para rotular por rota: os streams ao vivo não puxam para cima os números da
rota de compra, porque são contados sob a sua própria.

## O que não pôr num rótulo

A regra da seção 04 se generaliza: **um valor de rótulo tem de vir de um conjunto pequeno que você conhece
de antemão.** Rota, status, método, a categoria de um evento: sim. Um id de usuário, um e-mail, um id de
ingresso, um request id: nunca. Cada um não tem limite, e o e-mail é de novo o dado pessoal da aula 12,
agora copiado para um sistema de monitoramento guardado por meses. O request id pertence ao log, que é para
onde você vai depois que a métrica disse quando e onde procurar.

```
ana@vm:~/boxoffice$ curl -s localhost:9100/metrics | wc -l
158
```

158 linhas para um serviço pequeno, a maioria do runtime do Go. É um tamanho normal; alguns milhares é
normal para um grande, e dezenas de milhares quer dizer que um rótulo escapou.
