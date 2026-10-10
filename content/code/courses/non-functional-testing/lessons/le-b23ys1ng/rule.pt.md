---
title: Uma regra, e um teste para a regra
version: 1
---

A aula 1 deixou uma linha da sua tabela para esta aula: *um alerta chega a quem está de plantão em
até 5 minutos depois que a taxa de erro passa de 2%*. Aqui está essa linha como uma regra do
Prometheus. Crie o `alerts.yml` em `~/monitor`:

```yaml
# monitor/alerts.yml
# Page somebody when boxoffice fails its customers: more than 2% of requests
# answered with a 5xx over five minutes, or the process not answering at all.
groups:
  - name: boxoffice
    rules:
      - alert: BoxofficeErrorRatioHigh
        expr: |
          sum(rate(boxoffice_requests_total{status=~"5.."}[5m]))
            / sum(rate(boxoffice_requests_total[5m])) > 0.02
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "boxoffice is failing {{ $value | humanizePercentage }} of its requests"
          runbook_url: "https://wiki.example.com/runbooks/boxoffice-error-ratio"

      - alert: BoxofficeDown
        expr: up{job="boxoffice"} == 0
        for: 1m
        labels:
          severity: page
        annotations:
          summary: "Prometheus cannot reach boxoffice at {{ $labels.instance }}"
          runbook_url: "https://wiki.example.com/runbooks/boxoffice-down"
```

Cada regra tem quatro partes, e cada uma é uma decisão que alguém deveria saber explicar.

- **`expr`** é o sintoma, escrito em PromQL. A primeira é a razão de erro da aula 22 numa janela de
  cinco minutos, comparada com 0.02. A segunda é o `up`, que o Prometheus escreve para cada alvo que
  coleta: 0 quer dizer que ele não conseguiu alcançar a boxoffice, a falha que faz a razão de erro
  silenciar em vez de subir.
- **`for`** é quanto tempo a expressão tem de continuar verdadeira antes de o alerta disparar. Até
  lá ele fica *pending* (pendente). Dois minutos para a razão, um para o `up`, pelos motivos da
  seção anterior.
- **`labels`** são o que o encaminhamento lê. `severity: page` é a convenção deste curso para
  "acorde alguém"; nada no Prometheus conhece a palavra.
- **`annotations`** são o que a pessoa lê. O resumo leva o valor medido, formatado como porcentagem
  pelo `humanizePercentage`, e o `runbook_url` diz onde estão as instruções.

## Conferindo

O Prometheus vem com o `promtool`, que você instalou na aula 22 com o mesmo pacote. Primeiro, se o
arquivo é um conjunto válido de regras:

```
ana@nft:~/monitor$ promtool check rules alerts.yml
Checking alerts.yml
  SUCCESS: 2 rules found
```

Isso pega um erro de YAML, uma função desconhecida ou um erro de sintaxe de PromQL. **Não consegue
dizer se a regra dispara quando deve**, que é a única coisa que importa a alguém às 03:00. Para
isso, o `promtool` roda testes de unidade: séries inventadas, entregues às regras minuto a minuto,
com os alertas que você espera em momentos escolhidos. Crie o `alerts_test.yml` ao lado:

```yaml
# monitor/alerts_test.yml
# Made-up series, fed to alerts.yml one minute at a time by promtool.
rule_files:
  - alerts.yml
evaluation_interval: 1m

tests:
  # 100 good answers a minute throughout; from minute 10, 5 failures a minute too.
  - interval: 1m
    input_series:
      - series: 'boxoffice_requests_total{route="/bookings",status="201"}'
        values: '0+100x30'
      - series: 'boxoffice_requests_total{route="/bookings",status="500"}'
        values: '0x9 5+5x20'
    alert_rule_test:
      - eval_time: 9m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []
      - eval_time: 13m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []
      - eval_time: 14m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts:
          - exp_labels:
              severity: page
            exp_annotations:
              summary: "boxoffice is failing 4.762% of its requests"
              runbook_url: "https://wiki.example.com/runbooks/boxoffice-error-ratio"

  # 1% failing, for half an hour: annoying, and below the line.
  - interval: 1m
    input_series:
      - series: 'boxoffice_requests_total{route="/bookings",status="201"}'
        values: '0+99x30'
      - series: 'boxoffice_requests_total{route="/bookings",status="500"}'
        values: '0+1x30'
    alert_rule_test:
      - eval_time: 30m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []

  # The process stops answering at minute 3.
  - interval: 1m
    input_series:
      - series: 'up{job="boxoffice",instance="127.0.0.1:8000"}'
        values: '1 1 1 0 0 0 0'
    alert_rule_test:
      - eval_time: 3m
        alertname: BoxofficeDown
        exp_alerts: []
      - eval_time: 4m
        alertname: BoxofficeDown
        exp_alerts:
          - exp_labels:
              severity: page
              job: boxoffice
              instance: 127.0.0.1:8000
            exp_annotations:
              summary: "Prometheus cannot reach boxoffice at 127.0.0.1:8000"
              runbook_url: "https://wiki.example.com/runbooks/boxoffice-down"
```

A notação `'0+100x30'` quer dizer começar em 0 e somar 100 a cada passo, trinta vezes: um contador
de 100 respostas boas por minuto. `'0x9 5+5x20'` são dez zeros e depois um contador crescendo 5 por
minuto, as falhas começando no minuto 10. Nesse ponto a razão é 5 em 105, 4,76%, que é o que diz o
resumo esperado depois que o `humanizePercentage` arredonda. Rode:

```
ana@nft:~/monitor$ promtool test rules alerts_test.yml
Unit Testing:  alerts_test.yml
  SUCCESS
```

Os três testes sustentam quatro afirmações sobre as regras. Antes das falhas, nada dispara. As
falhas começam no minuto 10, mas nada dispara no 13 e o alerta está disparando no 14, porque a razão
de cinco minutos precisa até o minuto 12 para passar de 2% e depois tem de ficar lá pelos dois
minutos do `for`. Um 1% constante não dispara nada em meia hora. E uma boxoffice que para de
responder no minuto 3 dispara o seu alerta no minuto 4.

## Vendo um teste reprovar

Um teste que só passou prova pouco. Troque `for: 2m` por `for: 5m`, um valor que parece igualmente
razoável, e rode de novo:

```
ana@nft:~/monitor$ sed -i 's/for: 2m/for: 5m/' alerts.yml
ana@nft:~/monitor$ promtool test rules alerts_test.yml
Unit Testing:  alerts_test.yml
  FAILED:
    alertname: BoxofficeErrorRatioHigh, time: 14m, 
        exp:[
            0:
              Labels:{alertname="BoxofficeErrorRatioHigh", severity="page"}
              Annotations:{runbook_url="https://wiki.example.com/runbooks/boxoffice-error-ratio", summary="boxoffice is failing 4.762% of its requests"}
            ], 
        got:[]


ana@nft:~/monitor$ sed -i 's/for: 5m/for: 2m/' alerts.yml
```

**O teste reprovou e disse por quê**: no minuto 14 ele esperava um alerta e não recebeu nenhum,
porque com cinco minutos de `for` o alerta dispararia no minuto 17. São cinco minutos depois que a
razão passou de 2%, tudo o que o requisito da aula 1 permite, gastos antes de qualquer coisa ser
mandada a alguém. O arquivo de regras e o seu teste são dois arquivos no repositório, revisados
juntos, rodados pelo `promtool test rules` no mesmo pipeline de todos os outros testes. Uma mudança
num limite que quebra uma promessa agora quebra um build. O último comando acima pôs o `for: 2m` de
volta.
