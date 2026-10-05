---
title: Exemplares, de uma métrica para um rastro
version: 1
---

A aula 1 deixou uma ligação para esta aula. Um histograma de latência diz que alguns checkouts levaram
entre 0,25 e 0,5 segundo, e nada sobre quais. **Um exemplar é o id de uma requisição real, guardado ao
lado da contagem de um bucket**, para que um ponto num gráfico possa ser aberto como um rastro.

Três peças precisam concordar para um deles chegar a uma tela. A primeira está no código que observa a
duração, o `web.py` compartilhado da loja:

```schooling-example
{
  "language": "python",
  "file": "common/web.py",
  "parts": [
    {
      "code": "    @app.after_request\n    def finish(response):\n        route = request.url_rule.rule if request.url_rule else \"unmatched\"\n        if route != \"/metrics\":\n            REQUESTS.labels(route, request.method, str(response.status_code)).inc()\n"
    },
    {
      "code": "            ctx = trace.get_current_span().get_span_context()\n            exemplar = {\"trace_id\": format(ctx.trace_id, \"032x\")} if ctx.is_valid else None\n            DURATION.labels(route, request.method).observe(time.perf_counter() - g.started, exemplar)\n",
      "note": "**O trace id do span atual vira o exemplar**, mas só quando há um span válido. Fora de um rastro não há para onde apontar, e a observação é feita sem ele."
    },
    {
      "code": "        return response\n\n    @app.get(\"/metrics\")\n    def metrics():\n        # OpenMetrics, which carries exemplars, for a scraper that asks for it\n        encoder, content_type = choose_encoder(request.headers.get(\"Accept\"))\n        return Response(encoder(REGISTRY), content_type=content_type)\n",
      "note": "`choose_encoder` lê o cabeçalho `Accept` de quem faz o scrape e responde OpenMetrics a quem pede, o formato de texto clássico a qualquer outro. Só o OpenMetrics carrega exemplares."
    }
  ]
}
```

A segunda é o Prometheus, que descarta exemplares a não ser que uma flag de recurso o mande guardá-los.
O Prometheus do laboratório é reiniciado com um override:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage]
```

A terceira é o formato no fio. O formato de texto que a aula 5 leu não carrega exemplar; **o OpenMetrics
carrega**, e o Prometheus o pede quando faz o scrape. Pedir à mão, de dentro da rede do laboratório,
mostra o que o scrape recebe do `orders`:

```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- --header 'Accept: application/openmetrics-text' orders:8081/metrics | grep -m2 'duration_seconds_bucket{.* # '
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/orders"} 1071.0 # {trace_id="ae16afa43924732d71156920f9e3b5d1"} 0.42349258400008694 1790959284.789409
```

Depois do `#` fica um trace id com o valor que ele mediu e quando. Um bucket guarda o último exemplar
observado nele, então cada bucket aponta para uma requisição recente da sua própria faixa. O Prometheus
os recolhe a cada scrape e responde por eles numa consulta:

```
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query_exemplars --data-urlencode 'query=http_server_request_duration_seconds_bucket{job="orders",route="/orders"}' --data-urlencode start=$(date -d '-2 min' +%s) --data-urlencode end=$(date +%s) | jq -r '.data[].exemplars[:3][] | [.labels.trace_id, .value] | @tsv'
f9c0ac383b95bb01439b49c86b90a087	0.42279977799989865
9198ac701d96e56d0fa89f8a3ff26156	0.42294279299949267
687836b422656ee663235dcf6f7e81fb	0.4306990329996552
```

E um desses ids, aberto no Jaeger, é o rastro daquela requisição:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f9c0ac383b95bb01439b49c86b90a087 | jq -r -f selftime.jq | head -3
storefront	POST /checkout	426 ms	self 3 ms
orders	POST /orders	423 ms	self 16 ms
orders	INSERT	2 ms	self 2 ms
```

No Grafana os mesmos exemplares aparecem como pontos sobre o painel do histograma. A fonte de dados da
aula 7 precisa de mais uma configuração, `exemplarTraceIdDestinations`, nomeando a fonte de dados do
Jaeger, e um clique num ponto abre o rastro. **O ponto do bucket lento é uma requisição lenta**, que é o
que ninguém conseguia tirar de um gráfico antes.

A vitrine não tem exemplares, e vale saber o motivo. O span `POST /checkout` dela é escrito à mão, e ele
já terminou quando o `after_request` mede a duração, então não há span atual para nomear. **Um exemplar
só pode apontar para um span que ainda está aberto no momento da medição**. A instrumentação automática
no `orders` mantém o span do Flask aberto em volta da requisição inteira, e é por isso que o `orders`
os tem.
