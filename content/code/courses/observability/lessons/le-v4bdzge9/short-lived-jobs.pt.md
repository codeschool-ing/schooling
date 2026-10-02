---
title: A tarefa que some antes da coleta
version: 1
---

O pull supõe que o alvo ainda estará lá daqui a quinze segundos. **O relatório noturno não está**:
ele começa, conta, escreve e sai em cerca de um segundo, e uma coleta que chegue depois não encontra
nada a perguntar. A aula 4 prometeu uma métrica que diz se o relatório rodou, e é aqui que ela mora.

A resposta que o Prometheus oferece é o **Pushgateway**: um pequeno servidor que aceita métricas
empurradas para ele e guarda o último valor de cada uma. O Prometheus pode então coletá-lo como
qualquer alvo. O relatório empurra dois gauges na saída, usando o `push_to_gateway` da biblioteca
cliente:

```python
    registry = CollectorRegistry()
    Gauge("report_orders", "Orders the last report counted.", registry=registry).set(len(orders))
    Gauge("report_last_success_timestamp_seconds", "When the report last finished.",
          registry=registry).set_to_current_time()
    push_to_gateway(os.environ.get("PUSHGATEWAY", "pushgateway:9091"), job="report", registry=registry)
```

Antes da primeira execução não há nada a achar. A consulta não imprimiu linha nenhuma, e o `echo`
depois dela é quem diz isso. Então o relatório roda, e uma coleta depois o timestamp está lá:

```
ana@obs:~/shop$ ./promq 'report_last_success_timestamp_seconds' ; echo '(nothing yet)'
(nothing yet)
ana@obs:~/shop$ docker compose run --rm report 2>&1 | grep -v Container | jq -c '{message, orders}'
{"message":"report written","orders":963}
ana@obs:~/shop$ ./promq 'report_last_success_timestamp_seconds'
__name__=report_last_success_timestamp_seconds job=report  1790935620.3108528
ana@obs:~/shop$ ./promq 'time() - report_last_success_timestamp_seconds'
job=report  20.560147285461426
```

**A métrica é um timestamp, não uma contagem de execuções**, e a subtração é o ponto principal:
`time() - report_last_success_timestamp_seconds` é *segundos desde que o relatório terminou pela
última vez*, cerca de 20 aqui. Ela cresce um a cada segundo aconteça o que acontecer, então um
alerta sobre ela dispara na noite em que o relatório não roda. É o caso que a aula 4 mostrou que um
rastro nunca vê. O empurrão só acontece depois de o relatório terminar, então uma execução que
quebra no meio deixa o timestamp antigo no lugar, e isso está certo.

O Pushgateway é para exatamente isto, **uma tarefa que termina**, e é mal usado para qualquer outra
coisa. Ele guarda o último valor para sempre, então um serviço que empurrou e depois morreu parece
vivo nele. Ele também apaga o `up` por instância que faz o pull valer a pena. Um serviço de longa
duração é coletado, nunca empurrado.
