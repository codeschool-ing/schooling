---
title: A noite em que não se recuperou
version: 1
---

O laboratório não pode esperar as três da manhã, então a noite é encenada: a API de preços cai com `sudo shop outage on`, e a
Ana dispara à mão a execução das 03:00 de 10 de março, com essa data lógica, e a deixa em paz.

```
ana@vm:~/etl$ airflow dags trigger prices_daily --logical-date 2026-03-10T03:00:00-03:00 -o plain >/dev/null; airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T08:41:45.770719+00:00  running  2026-10-07T08:41:45.770719+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-night\" aria-label=\"A execução das 03:00 de 10 de março numa linha do tempo de alguns minutos. Cinco tentativas, todas falhas, com as esperas entre elas crescendo: uns quinze segundos, depois trinta, sessenta e cento e vinte. Dois minutos depois de a execução entrar na fila, o prazo passa e uma linha LATE é escrita enquanto a execução ainda tenta. Depois da quinta tentativa a tarefa falhou de vez e uma linha FAILED é escrita.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 200.0 L690.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M90.0 196.0 L90.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 min</text><path d=\"M197.3 196.0 L197.3 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"197.3\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 min</text><path d=\"M304.5 196.0 L304.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"304.5\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 min</text><path d=\"M411.8 196.0 L411.8 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"411.8\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 min</text><path d=\"M519.1 196.0 L519.1 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"519.1\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 min</text><path d=\"M626.4 196.0 L626.4 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"626.4\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 min</text><text x=\"80.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativas</text><text x=\"80.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperas</text><circle cx=\"97.2\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"97.2\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M105.2 150.0 L133.8 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"119.5\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 s</text><circle cx=\"141.8\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"141.8\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M149.8 150.0 L219.7 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"184.8\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><circle cx=\"227.7\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"227.7\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M235.7 150.0 L385.9 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"348.4\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 s</text><circle cx=\"393.9\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"393.9\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><path d=\"M401.9 150.0 L659.5 150.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.7\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120 s</text><circle cx=\"667.5\" cy=\"110.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"667.5\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><path d=\"M304.5 40.0 L304.5 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"310.5\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prazo: 2 min depois da fila</text><text x=\"310.5\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">LATE</text><text x=\"667.5\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">FAILED</text></svg>", "caption": "O prazo fala enquanto a execução ainda tenta; o callback de falha só quando as tentativas acabaram.", "same": ["0 min", "1 min", "120 s", "15 s", "2 min", "3 min", "30 s", "4 min", "5 min", "60 s"]}
```

De manhã há duas linhas no `alerts.log`:

```
ana@vm:~/etl$ cat alerts.log
2026-10-07 05:43:47 LATE prices_daily run=manual__2026-10-07T08:41:45.770719+00:00 state=running
2026-10-07 05:47:31 FAILED prices_daily.fetch run=manual__2026-10-07T08:41:45.770719+00:00 try=5 error=HTTPError('503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200')
```

**O prazo falou primeiro, enquanto a execução ainda tentava**: dois minutos depois de entrar na fila
ela não tinha terminado, e o `state=running` diz isso. **O callback de falha falou por último, quando
não havia mais nada a tentar**: a quinta tentativa, a exceção que a encerrou e a execução a que ela
pertencia. Numa noite de verdade, a primeira linha é a que acorda alguém antes de o relatório da
manhã sair; a segunda é a que diz onde olhar.

## Lendo de manhã

A ordem da Ana é sempre a mesma: o que o Airflow viu, depois o que a fonte diz agora.

```
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T08:41:45.770719+00:00  failed   2026-10-07T08:41:45.770719+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
ana@vm:~/etl$ RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch
try 1 failed 08:41:46 to 08:41:46
try 2 failed 08:42:09 to 08:42:09
try 3 failed 08:43:00 to 08:43:00
try 4 failed 08:44:35 to 08:44:35
try 5 failed 08:47:31 to 08:47:31
ana@vm:~/etl$ grep -ho "\"exc_type\":\"[A-Za-z]*\",\"exc_value\":\"[^\"]*\"" ~/airflow/logs/dag_id=prices_daily/run_id=manual__*/task_id=fetch/attempt=*.log | sort | uniq -c
      5 "exc_type":"HTTPError","exc_value":"503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200"
ana@vm:~/etl$ curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices
503
```

Cinco tentativas, todas falhas, os intervalos entre elas crescendo como o backoff disse que
cresceriam. O log de cada tentativa nomeia a mesma exceção, então é uma causa e não cinco. E a API,
consultada à mão, ainda responde `503`: **o problema não está no código da Ana nem no Airflow, e nada
que ela rode de novo agora pode dar certo.** O certo é esperar a fonte — ou, em produção, avisar quem
cuida dela — em vez de sair limpando tarefas contra a mesma parede.

Mais tarde, de manhã, a API volta a responder:

```
ana@vm:~/etl$ curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices
200
```

Agora rodar de novo pode funcionar, e a próxima seção faz isso.

Desta transcrição, vale lembrar duas coisas. **Um alerta de falha é o começo de uma
investigação, não o fim**: a linha dizia `503`, mas se a API continuava fora do ar era uma pergunta
que só um pedido novo podia responder. E **a ordem importa**: primeiro as tentativas da
execução, depois os logs, depois a fonte — e, quando um DAG parece não ter feito nada, os erros de
importação antes de tudo isso. Cada passo descarta um tipo
inteiro de falha antes de o próximo ser olhado.
