---
title: Labels, e o experimento
version: 1
---

Um label é o que permite a uma métrica responder *por rota* ou *por código de status*, e a aula 5 se
apoiou nisso em toda consulta. **O preço é que cada combinação distinta de valores de label é uma
série à parte**, guardada, indexada e mantida em memória pelo Prometheus por conta própria. O
contador da vitrine tem um punhado porque rotas, métodos e códigos de status são poucos. O perigo é
um label cujos valores não são poucos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Labels se multiplicam. O contador de requisições da vitrine tem três labels que ele define, route com 3 valores, method com 2, code com 4 vistos, e o Prometheus acrescenta job e instance. O número de séries é o produto dos valores que de fato ocorrem juntos. Acrescentar um label com 20000 valores, um id de usuário, multiplica o que havia por 20000.\"><defs><marker id=\"mul-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">route</text><text x=\"100.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 valores</text><text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"200\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">method</text><text x=\"260.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 valores</text><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"360\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">code</text><text x=\"420.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 valores</text><text x=\"500\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper)\">×</text><rect x=\"520\" y=\"80\" width=\"120\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">user_id</text><text x=\"580.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20000 valores</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">séries = o produto dos valores que ocorrem juntos</text><text x=\"280\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no máximo 3 × 2 × 4 = 24 sem o último label</text><text x=\"560\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">× 20000 com ele</text></svg>", "caption": "Um label não é uma coluna numa linha; é um multiplicador do número de linhas. O custo de um label é o número de valores distintos, não o comprimento.", "same": ["code", "method", "route", "user_id"]}
```

O experimento mede isso. O `logins.py` conta vinte mil logins com um contador e um label escolhido na
linha de comando: `plan`, com três valores possíveis, ou `user_id`, com um valor por usuário. Ele
serve o resultado na porta 8000 e continua no ar para o Prometheus coletá-lo:

```python
import random
import sys
import time

from prometheus_client import Counter, start_http_server

label = sys.argv[1]
LOGINS = Counter("demo_logins", "Logins, labelled the way the first argument says.", [label])
random.seed(7)
start_http_server(8000)
plans = ["free", "monthly", "yearly"]
for user_id in range(1, 20001):
    value = str(user_id) if label == "user_id" else random.choice(plans)
    LOGINS.labels(value).inc()
print(f"20000 logins counted by {label}", flush=True)
time.sleep(3600)
```

O Prometheus ganha mais dois jobs de coleta: ele mesmo, para que a própria memória e a contagem de
séries virem métricas, e o experimento:

```
ana@obs:~/shop$ tail -6 prometheus/prometheus.yml
  - job_name: prometheus
    static_configs:
      - targets: [localhost:9090]
  - job_name: logins
    static_configs:
      - targets: [logins:8000]
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

Antes de qualquer outra coisa rodar, as séries que o Prometheus mantém em memória e a memória que
usa:

```
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  3760
ana@obs:~/shop$ ./promq 'process_resident_memory_bytes{job="prometheus"}'
__name__=process_resident_memory_bytes instance=localhost:9090 job=prometheus  96370688
```

**3760 séries e 96 MB**, para a loja inteira e tudo o que a vigia. Então os logins, contados por
plano:

```
ana@obs:~/shop$ docker compose run -d --rm --name logins sandbox python logins.py plan
 Container shop-otel-collector-1 Running 
 Container logins Creating 
 Container logins Created 
507e2ae26979678decc89d4d47f625ca0be16788587617ee231fbd9501d750ce
ana@obs:~/shop$ curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == "logins") | [.health, .lastScrapeDuration] | @tsv'
up	0.003508293
ana@obs:~/shop$ ./promq 'demo_logins_total'
__name__=demo_logins_total instance=logins:8000 job=logins plan=monthly  6639
__name__=demo_logins_total instance=logins:8000 job=logins plan=free  6758
__name__=demo_logins_total instance=logins:8000 job=logins plan=yearly  6603
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  3782
```

**Três séries**, uma por plano, somando 20000, e a memória ativa (head) cresceu 22: seis para os
logins, porque todo counter traz o seu gauge `_created`, e o resto para o próprio alvo novo, o `up`
dele, as estatísticas de coleta e as métricas de processo que a biblioteca cliente publica. Nada a
ver.
