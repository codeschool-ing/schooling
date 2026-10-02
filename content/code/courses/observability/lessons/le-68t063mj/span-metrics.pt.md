---
title: Contando antes de descartar
version: 1
---

Quando nove em dez rastros somem, os rastros não podem mais ser contados. Um painel de *checkouts por
segundo* construído a partir do armazenamento mostraria um décimo da verdade com amostragem na cabeça,
e algo mais estranho com amostragem na cauda: **quase todo erro e toda requisição lenta, e 5% do
resto**, então a taxa de erros calculada a partir dele sairia várias vezes alta demais.

A resposta é contar primeiro. O **conector `spanmetrics`** do Collector lê todo span antes de o
amostrador vê-lo e o transforma em métricas de taxa, erros e duração, uma série por serviço, nome de
span, tipo e status. Um conector é exportador de uma esteira e receptor de outra, e aqui ele termina
uma esteira que recebe todo span e começa uma que manda métricas ao Prometheus:

```
ana@obs:~/shop$ sed -n '/^connectors:/,/^processors:/p' otel/collector-sampling.yaml
connectors:
  # Rate, errors and duration per service and span name, computed from every
  # span before any of them is dropped.
  spanmetrics:
    metrics_flush_interval: 15s
    histogram:
      explicit:
        buckets: [10ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s]

processors:
```

A partir dessas métricas, os checkouts por segundo da vitrine, por status:

```
ana@obs:~/shop$ ./promq 'sum by (span_name, status_code) (rate(traces_span_metrics_calls_total{service_name="storefront"}[1m]))'
span_name=POST /checkout status_code=STATUS_CODE_ERROR  0.1111086420301771
span_name=POST /checkout status_code=STATUS_CODE_UNSET  4.399902224395013
```

Contra o contador da própria vitrine, medido no código dela:

```
ana@obs:~/shop$ ./promq 'sum by (code) (rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
code=201  4.155555555555555
code=402  0.2222222222222222
code=503  0
code=502  0.1111111111111111
```

Os dois concordam: 4,51 checkouts por segundo pelos spans, 4,49 pelo contador, e os 0,11 por
segundo que são erros são os 502 da vitrine. Os cartões recusados, 402, não são erro para um span,
porque a requisição foi respondida corretamente. E como o histograma é construído a partir de todo span, os percentis dele incluem todo
checkout lento:

```
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(traces_span_metrics_duration_milliseconds_bucket{service_name="storefront",span_name="POST /checkout"}[2m])))'
  2126.5789473684235
```

Uns 2,1 segundos, a vigésima quinta cobrança que espera 1,5 s a mais. O número está certo porque conta
todo checkout: os lentos são 4% do tráfego, e os rastros guardados, um terço deles lentos, poriam o
percentil 99 alto demais.

Duas consequências valem ser sabidas. **As séries são uma por nome de span**, então um span batizado
com o id de um pedido, o erro de que a aula 2 avisou, vira aqui uma série por pedido, e a conta que a
aula 6 descreveu. E os spans dão essas métricas de graça, o que as torna tentadoras como substitutas das
métricas escritas no código: elas servem para taxa, erros e duração do que é rastreado, e são cegas a
tudo que um span não carrega, como a profundidade de uma fila ou o tamanho de um pool.
