---
title: Conduzindo pelo ambiente
version: 1
---

Uma instrumentação automática é configurada do jeito que foi instalada: de fora do código. Cada
ajuste é uma variável de ambiente, e a maioria começa com `OTEL_`. As que importam primeiro:

| variável | o que ela decide |
|---|---|
| `OTEL_SERVICE_NAME` | o `service.name` que todo span carrega |
| `OTEL_RESOURCE_ATTRIBUTES` | mais atributos de resource, como `chave=valor,chave=valor` |
| `OTEL_TRACES_EXPORTER` | `otlp`, `console` ou `none` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | para onde o exporter envia |
| `OTEL_TRACES_SAMPLER` | que rastros são guardados; aula 12 |
| `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` | instrumentações a pular, pelo nome |
| `OTEL_PYTHON_FLASK_EXCLUDED_URLS` | rotas do Flask que não ganham span |

**A última já está em uso.** O Prometheus pede `/metrics` a cada serviço a cada quinze segundos, e
um health check pede `/health` no seu próprio ritmo. Rastreado, cada um desses seria um rastro que
ninguém quer, num ritmo constante, abafando os checkouts. O `orders` exclui os dois, e três chamadas
ao health check dele não deixam rastro:

```
ana@obs:~/shop$ docker compose exec orders python -c 'import urllib.request as u; print([u.urlopen("http://localhost:8081/health").status for i in range(3)])'
[200, 200, 200]
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=orders' | jq -r '.operations[].name' | sort
INSERT
POST
POST /orders
UPDATE
```

Quatro operações, e nenhum `GET /health` entre elas. **Desligar uma instrumentação inteira** é o
mesmo tipo de mudança. Aqui a camada do banco é desligada, o `orders` é recriado com a variável nova,
e um checkout é enviado:

```
ana@obs:~/shop$ cp compose.yaml compose.yaml.orig
ana@obs:~/shop$ sed -i 's/      OTEL_PYTHON_FLASK_EXCLUDED_URLS: health,metrics/&\n      OTEL_PYTHON_DISABLED_INSTRUMENTATIONS: psycopg/' compose.yaml
ana@obs:~/shop$ docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
ana@obs:~/shop$ curl -s localhost:16686/api/traces/09839a6961d8e8d4b0f0c10ba65e358c | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | select($t.processes[.processID].serviceName == "orders") | .operationName'
POST /orders
POST
ana@obs:~/shop$ mv compose.yaml.orig compose.yaml && docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

`INSERT` e `UPDATE` sumiram, e nada mais mudou: o banco ainda foi chamado, só não foi vigiado. É
assim que uma instrumentação barulhenta ou com defeito é silenciada em produção enquanto alguém
decide o que fazer com ela, sem uma nova versão do serviço. O `mv` devolveu o `compose.yaml`
original, e o `orders` foi recriado de novo com os seus spans de banco.
