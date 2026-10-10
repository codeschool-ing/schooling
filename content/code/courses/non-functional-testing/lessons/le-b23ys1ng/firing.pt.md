---
title: Disparando de verdade, e para onde vai um alerta
version: 1
---

Um teste de unidade prova a regra contra números inventados. O próximo passo é vê-la disparar contra
a bilheteria, sob um tráfego que produz falhas reais. Isso pede três coisas: o Prometheus avaliando
as regras, uma bilheteria que falha, e algum tráfego.

## O Prometheus com regras

Substitua o `~/monitor/prometheus.yml` por esta versão. É a da aula 22, com dois blocos a mais:

```yaml
# monitor/prometheus.yml
# Lesson 24's version: lesson 22's scrapes, plus the rules to evaluate
# and the Alertmanager to tell when one of them fires.
global:
  scrape_interval: 5s
  evaluation_interval: 5s

rule_files:
  - alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["127.0.0.1:9093"]

scrape_configs:
  - job_name: boxoffice
    static_configs:
      - targets: ["127.0.0.1:8000"]
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

O `rule_files` faz o Prometheus avaliar o `alerts.yml` a cada `evaluation_interval`, cinco segundos
aqui. O `alerting` diz para onde mandar um alerta quando ele dispara: um **Alertmanager**, um
programa separado que escuta na porta 9093 por padrão e ao qual esta seção volta mais abaixo. Nada
está escutando lá ainda, e isso é de propósito.

## Uma bilheteria que falha

As falhas precisam vir de algum lugar, e a boxoffice como foi escrita nunca responde 5xx. O
`flaky.py` é o `observed.py` com um provedor de pagamento que estoura o tempo em uma chamada de cada
três. Como o `slow.py` da aula 23, ele não muda nada no `app.py`; ele substitui a função `pay`
depois de importá-lo. Crie-o em `~/boxoffice`:

```python
# boxoffice/flaky.py
# observed.py with a payment provider that times out on one call in three.
import random, time
import app, observed

def pay(customer, cents):
    time.sleep(app.PAYMENT_SECONDS)
    if random.random() < 0.33:
        raise TimeoutError("payment provider did not answer")

app.pay = pay
observed.serve()
```

A exceção é levantada dentro da reserva, depois que o lock é pego e antes de a linha ser escrita,
então o assento continua livre, e o `guarded` do `observed.py` a transforma num 500 com a exceção na
linha de log.

Suba tudo, um terminal para cada, como na aula 22: `python3 flaky.py > requests.log` em
`~/boxoffice`, depois `prometheus --config.file=prometheus.yml --storage.tsdb.path=data` em
`~/monitor`, depois o tráfego da aula 22 por quatro minutos, com a própria opção do k6 passando por
cima da duração do script:

```sh
k6 run --duration 4m traffic.js
```

## Pendente, depois disparando

O `/api/v1/alerts` da API lista todo alerta pendente ou disparando. Uns cinquenta segundos depois do
início do tráfego:

```
ana@nft:~/monitor$ curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alert: .labels.alertname, state, activeAt, value}'
{"alert":"BoxofficeErrorRatioHigh","state":"pending","activeAt":"2026-10-10T19:41:19.559363395Z","value":"3.6391060761412984e-02"}
```

**Pendente quer dizer que a expressão é verdadeira e o `for` ainda não acabou.** O `activeAt` é
quando ela ficou verdadeira pela primeira vez, e `value` é a razão na última avaliação, 3,6%. Cerca
de um minuto e meio depois:

```
ana@nft:~/monitor$ curl -s localhost:9090/api/v1/alerts | jq '.data.alerts[]'
{
  "labels": {
    "alertname": "BoxofficeErrorRatioHigh",
    "severity": "page"
  },
  "annotations": {
    "runbook_url": "https://wiki.example.com/runbooks/boxoffice-error-ratio",
    "summary": "boxoffice is failing 3.331% of its requests"
  },
  "state": "firing",
  "activeAt": "2026-10-10T19:41:19.559363395Z",
  "value": "3.3307772791676904e-02"
}
```

Disparando, com o mesmo `activeAt` e as anotações preenchidas a partir do valor medido, 3.331%. O
resumo é a frase que um telefone mostraria, e o link do runbook é a primeira coisa que a pessoa que o
segura abre.

Compare o número do resumo com o que está falhando. **Um pagamento em três está falhando, e o alerta
diz cerca de 3%.** A razão é sobre todas as requisições, e as reservas são só uma parte delas:

```
ana@nft:~/monitor$ sh promql.sh 'sum by (route) (rate(boxoffice_requests_total{status=~"5.."}[5m])) / sum by (route) (rate(boxoffice_requests_total[5m]))'
{"route":"/bookings"}  0.2465155477571352
ana@nft:~/monitor$ sh promql.sh 'sum(rate(boxoffice_requests_total{route="/bookings"}[5m])) / sum(rate(boxoffice_requests_total[5m]))'
{}  0.1351142956128609
```

Por rota, 24,7% de tudo o que foi mandado para `/bookings` falhou; um 409 nunca chega ao pagamento,
então conta no denominador dessa razão e não no numerador, e é por isso que ela fica abaixo de um
terço. E as reservas foram 13,5% de todas as requisições. Se o provedor falhasse uma chamada em dez,
a razão geral teria ficado em cerca de 1%, abaixo da linha, enquanto um décimo das pessoas tentando
pagar era recusado. **Um alerta sobre o serviço inteiro esconde uma jornada quebrada dentro de uma
média saudável**, que é o argumento para uma segunda regra na rota que traz o dinheiro, com o seu
próprio limite.

O log diz qual falha foi, com os ids de requisição para seguir:

```
ana@nft:~/boxoffice$ jq -c 'select(.level == "error")' requests.log | head -2
{"ts":"2026-10-10T19:41:05.980+00:00","level":"error","request_id":"51ac36cf319940d9","method":"POST","route":"/bookings","path":"/bookings","status":500,"ms":52.8,"error":"TimeoutError('payment provider did not answer')"}
{"ts":"2026-10-10T19:41:06.157+00:00","level":"error","request_id":"14db6ab7e09044b3","method":"POST","route":"/bookings","path":"/bookings","status":500,"ms":53.5,"error":"TimeoutError('payment provider did not answer')"}
```

## O alerta que ninguém recebeu

O alerta disparou, e ninguém foi avisado. O Prometheus disse isso no próprio terminal, às 19:43:19,
dois minutos depois do `activeAt`, o momento em que o `for` acabou:

```
ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data
…
ts=2026-10-10T19:43:19.568Z caller=notifier.go:529 level=error component=notifier alertmanager=http://127.0.0.1:9093/api/v2/alerts count=1 msg="Error sending alert" err="Post \"http://127.0.0.1:9093/api/v2/alerts\": dial tcp 127.0.0.1:9093: connect: connection refused"
```

**O Prometheus decide quando um alerta dispara; ele não decide quem fica sabendo.** Ele entrega o
alerta ao Alertmanager, e sem Alertmanager escutando o alerta não vai a lugar nenhum, em voz alta num
log que ninguém lê de madrugada e em silêncio em todo o resto. É um jeito comum de um esquema de
alertas falhar, e a solução é vigiar o vigia: o Prometheus tem métricas próprias para isso, como
`prometheus_notifications_errors_total`, e a resposta de costume é um *dead man's switch*, um alerta
que dispara o tempo todo e aciona alguém quando ele *para* de chegar.

## O Alertmanager

O Alertmanager está no repositório do Ubuntu como `prometheus-alertmanager`. **Ele não está
instalado na máquina em que estas transcrições foram gravadas, então nada abaixo foi executado
aqui.** Na sua VM, `sudo apt-get install -y prometheus-alertmanager` o instala e o sobe como serviço
na porta 9093, lendo `/etc/prometheus/alertmanager.yml`. Uma configuração para a boxoffice fica
assim:

```yaml
# monitor/alertmanager.yml
# Where alerts go: anything labelled severity=page to the person on call,
# everything else to the team's queue, and nothing twice in four hours.
global:
  smtp_smarthost: "mail.example.com:587"
  smtp_from: "alertmanager@example.com"

route:
  receiver: team-queue
  group_by: [alertname]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - matchers: ['severity="page"']
      receiver: on-call

receivers:
  - name: on-call
    pagerduty_configs:
      - routing_key: "the-integration-key-pagerduty-gives-you"
  - name: team-queue
    email_configs:
      - to: "boxoffice-team@example.com"

inhibit_rules:
  - source_matchers: ['alertname="BoxofficeDown"']
    target_matchers: ['alertname="BoxofficeErrorRatioHigh"']
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l24-routing\" aria-label=\"O Prometheus, à esquerda, manda os alertas que disparam para o Alertmanager, no meio. O Alertmanager os agrupa, segura o alerta da razão de erro enquanto o BoxofficeDown está disparando, e encaminha pelo rótulo: alertas com severity page vão para o PagerDuty, que liga para quem está de plantão e, se ninguém confirmar, para o reserva. Todo o resto vai para a fila da equipe por e-mail, lida em horário de trabalho.\"><defs><marker id=\"l24-routing-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l24-routing-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"120.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Prometheus</text><text x=\"85.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decide que dispara</text><path d=\"M152.0 150.0 L226.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"80.0\" width=\"170.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Alertmanager</text><text x=\"315.0\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agrupa</text><text x=\"315.0\" y=\"151.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inibe</text><text x=\"315.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encaminha pelo rótulo</text><text x=\"315.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">repete a cada 4h</text><path d=\"M402.0 120.0 L476.0 80.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-amber)\"></path><text x=\"440.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">severity=&quot;page&quot;</text><path d=\"M402.0 190.0 L476.0 228.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-paper-dim)\"></path><text x=\"446.0\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o resto</text><rect x=\"480.0\" y=\"50.0\" width=\"220.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PagerDuty, Opsgenie</text><text x=\"590.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">liga para quem está de plantão,</text><text x=\"590.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois para o reserva</text><rect x=\"480.0\" y=\"200.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"221.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a fila da equipe, por e-mail</text><text x=\"590.0\" y=\"234.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lida em horário de trabalho</text></svg>", "caption": "O Prometheus decide que um alerta dispara. O Alertmanager decide quem fica sabendo, e quando.", "same": ["Alertmanager", "PagerDuty, Opsgenie", "Prometheus"]}
```

Ele faz quatro trabalhos, e cada um é um jeito de mandar menos avisos, e melhores.

- **Encaminhamento.** A árvore sob `route` manda todo alerta com rótulo `severity="page"` para quem
  está de plantão, aqui pelo PagerDuty, e todo o resto para uma fila de e-mail que a equipe lê em
  horário de trabalho. Os rótulos que uma regra põe são o que isso lê, e é por isso que `severity` é
  um rótulo e não uma anotação.
- **Agrupamento.** O `group_by: [alertname]` faz de vinte instâncias do mesmo alerta um aviso só, e o
  `group_wait: 30s` espera meio minuto pelo resto de um grupo antes de mandar o primeiro. Esses 30
  segundos fazem parte dos cinco minutos da aula 1.
- **Repetição.** O `repeat_interval: 4h` manda de novo um alerta que continua disparando a cada
  quatro horas, e não a cada avaliação.
- **Inibição.** Enquanto o `BoxofficeDown` dispara, o `BoxofficeErrorRatioHigh` fica retido: a
  pessoa já sabe que a bilheteria caiu, e um segundo acionamento sobre a razão de erro dela não diz
  nada de novo. Num sistema maior, essa é a regra que impede um banco de dados caído de acionar
  alguém uma vez para cada um dos vinte serviços que o usam.

Os dois endereços de exemplo e a chave do PagerDuty são marcadores. O pacote também instala o
`amtool`, que confere um arquivo como este com `amtool check-config alertmanager.yml`, do mesmo jeito
que o `promtool` confere regras.

**PagerDuty e Opsgenie** são dois dos serviços que as equipes costumam pôr no fim dessa rota. Eles
são a parte que sabe quem está de plantão nesta semana, liga para o telefone dessa pessoa até ela
confirmar, e liga para a próxima da lista se ela não confirmar. O Alertmanager consegue mandar para os
dois, e para Slack, e-mail ou qualquer endereço que aceite um webhook. Nenhum deles foi usado aqui.
