---
title: De uma linha de log ao seu rastro
version: 1
---

A aula 7 disse que uma métrica mostra que algo está errado, um rastro mostra onde, e um log mostra o
que exatamente. Os três só funcionam juntos se de um se chega ao outro, e o elo entre uma linha de
log e o seu rastro é o **id do rastro**.

Toda linha de log que a bilheteria escreve dentro de um pedido agora leva um. Da captura da seção
anterior:

```
{"time": "2026-10-10T06:22:21.113+00:00", "level": "info", "message": "request", "host": "dd4bf75a071b", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 46.2, "trace_id": "5bd86167ca0ed7a647e37c1ebe501aac"}
```

Esse `trace_id` é o do `traceparent` do payments, e aquele com que o Jaeger guarda o rastro. Na
prática o movimento vai nos dois sentidos:

- **de uma linha de log a um rastro**: um erro no log, e você quer ver o que mais aquele pedido estava
  fazendo, em qual serviço, e quanto levou cada parte. O id do rastro o acha no Jaeger, cuja página
  tem uma caixa de busca exatamente para isso, e cuja API recebe o id no endereço,
  `/api/v3/traces/<trace id>`;
- **de um rastro às suas linhas de log**: um span lento num rastro, e você quer saber o que o código
  registrou enquanto ele rodava. O id do rastro, buscado nos logs, devolve toda linha daquele pedido,
  de todo serviço que tenha escrito uma.

## Exemplares

As métricas também podem levar o elo. Um **exemplar** (*exemplar*) é um id de rastro preso a uma
observação de um histograma: dos pedidos na faixa de 100 a 250 ms, aqui está um, e aqui está o
rastro dele. O Prometheus guarda exemplares quando o cliente os manda e o armazenamento de exemplares
está ligado, e um painel pode então mostrar, ao lado de um percentil lento, um botão para o rastro de
um pedido que foi lento. Isso fecha o ciclo da aula 7: **a métrica que diz que algo está lento aponta
para um pedido que esteve.**

As métricas da bilheteria não mandam exemplares; o `prometheus_client` consegue, dado um id de rastro
por observação, e o próprio SDK de métricas do OpenTelemetry faz isso sozinho quando há um span
atual.
