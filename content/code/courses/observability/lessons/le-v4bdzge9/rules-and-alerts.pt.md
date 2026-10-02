---
title: Regras, e um alerta da regra ao pager
version: 1
---

As consultas até aqui foram feitas por uma pessoa. **Regras são consultas que o Prometheus faz a si
mesmo**, a cada quinze segundos, a partir de arquivos listados no `prometheus.yml`. Há dois tipos, e
o arquivo de regras do laboratório agora tem os dois:

```yaml
groups:
  - name: shop
    rules:
      - alert: TargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: ticket
        annotations:
          summary: "{{ $labels.job }} has not answered a scrape for a minute"

      - record: job:http_server_requests:rate1m
        expr: sum by (job, code) (rate(http_server_requests_total[1m]))

      - alert: PaymentsFailing
        expr: |
          sum(job:http_server_requests:rate1m{job="payments", code=~"5.."})
            / sum(job:http_server_requests:rate1m{job="payments"}) > 0.02
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "More than 2% of charges are failing"

      - alert: ReportNotRun
        expr: time() - report_last_success_timestamp_seconds > 26 * 3600
        labels:
          severity: ticket
        annotations:
          summary: "The nightly report has not finished for over 26 hours"
```

Uma **regra de gravação**, `record:`, avalia uma expressão e guarda o resultado como uma série
nova com o nome dado. `job:http_server_requests:rate1m` é a taxa por job e código, calculada uma vez
por avaliação em vez de uma vez por painel e por alerta que a queira; o nome segue a convenção
*nível:métrica:operação*. Uma **regra de alerta**, `alert:`, avalia uma expressão e, para cada série
que volta, mantém um alerta. `PaymentsFailing` é a proporção do começo desta aula, escrita sobre a
regra de gravação, e `ReportNotRun` é o timestamp do Pushgateway com vinte e seis horas em cima: um
dia, mais uma folga para uma execução que começou tarde.

O arquivo é verificado com o `promtool`, da própria imagem do Prometheus, e o Prometheus é avisado
para recarregar:

```
ana@obs:~/shop$ docker run --rm -v ./prometheus:/etc/prometheus --entrypoint promtool prom/prometheus:v3.15.0 check rules /etc/prometheus/rules/shop.yml
Checking /etc/prometheus/rules/shop.yml
  SUCCESS: 4 rules found

ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

Vinte segundos depois a série gravada existe, e o alerta começou:

```
ana@obs:~/shop$ ./promq 'job:http_server_requests:rate1m{job="payments"}'
__name__=job:http_server_requests:rate1m code=200 job=payments  4.266666666666666
__name__=job:http_server_requests:rate1m code=503 job=payments  0.2222222222222222
ana@obs:~/shop$ curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'
PaymentsFailing	pending	2026-10-02T10:07:39.145836091Z
```

**`pending`, não disparado.** A regra diz `for: 2m`: a condição tem de se manter em toda avaliação
por dois minutos antes de o alerta disparar. Dois minutos depois:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'
PaymentsFailing	firing	2026-10-02T10:07:39.145836091Z
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A vida do alerta PaymentsFailing, da esquerda para a direita. Inativo enquanto a condição é falsa. Pendente a partir de 10:07:39, quando a proporção de erros passou de 2 por cento pela primeira vez: o Prometheus espera, porque a regra diz for 2m. Disparado dois minutos depois, se a condição se manteve o tempo todo: o Prometheus o manda ao Alertmanager. O Alertmanager o agrupa, espera 10 segundos por outros, e o manda ao pager, que registrou uma linha PAGE.\"><defs><marker id=\"life-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">inativo</text><text x=\"65.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">condição falsa</text><rect x=\"155\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pendente</text><text x=\"210.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esperando o for: 2m</text><rect x=\"310\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">disparado</text><text x=\"365.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 minutos assim</text><rect x=\"470\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Alertmanager</text><text x=\"525.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group_wait 10s</text><rect x=\"610\" y=\"70\" width=\"90\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pager</text><text x=\"655.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha PAGE</text><path d=\"M122 100 L153 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M267 100 L308 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M422 100 L468 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M582 100 L608 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M210 132 L210 165 L70 165 L70 132\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#life-ah)\"></path><text x=\"140\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a condição some: volta a inativo, ninguém é chamado</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um alerta, da regra ao pager</text></svg>", "caption": "O for: 2m é a diferença entre um soluço e um chamado. Uma condição que some antes dos dois minutos volta a inativa, e ninguém é acordado.", "same": ["Alertmanager", "group_wait 10s", "pager"]}
```

O Prometheus só decide que um alerta está disparado. **Quem fica sabendo é trabalho do
Alertmanager**: ele recebe todo alerta disparado, agrupa os que andam juntos, segura os repetidos, e
manda cada grupo a um receptor. O do laboratório roteia tudo para o pager:

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -r '.[] | [.labels.alertname, .labels.severity, .status.state] | @tsv'
PaymentsFailing	page	active
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep PAGE | jq -c '{status, alertname, severity, summary}'
{"status":"firing","alertname":"PaymentsFailing","severity":"page","summary":"More than 2% of charges are failing"}
```

O Alertmanager mantém o alerta como `active`, e o pager registrou o chamado, com a severidade e o
resumo que a regra lhe deu. **Cada palavra dessa linha foi escrita na regra**, e é por isso que a
aula 16 gasta seu tempo com o que uma regra deve dizer e a quem. O arquivo de falhas foi removido
no fim da captura.
