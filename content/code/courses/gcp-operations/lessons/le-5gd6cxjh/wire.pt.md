---
title: Ligando o orçamento a uma função
version: 1
---

**Cada mensagem no tópico do orçamento tem três atributos e um corpo JSON.** Os atributos são `billingAccountId`,
`budgetId` e `schemaVersion`. O corpo traz, entre outros campos, `costAmount` (o gasto até agora no período),
`budgetAmount` e `currencyCode`, e `alertThresholdExceeded` depois que uma regra de limite foi ultrapassada. Os
próprios exemplos do Google para funções de orçamento leem só `costAmount` e `budgetAmount`, e a função daqui também.

O que roda no seu computador é o caminho inteiro menos o primeiro passo. **O Billing não publica num emulador**, então
você mesmo publica as mensagens, nesse formato, no emulador do Pub/Sub; dali em diante tudo é o que rodaria no Google
Cloud: uma assinatura push entregando cada mensagem a uma função, e a função publicando o que decidiu.

## A função

Ela roda com o **Functions Framework**, a biblioteca que as funções do Cloud Run usam para chamar o seu código, e que
serve uma função por HTTP no seu computador. Instale-a, junto com a biblioteca cliente do Pub/Sub com que a função
publica, no ambiente virtual do laboratório:

```sh
pip install -q 'functions-framework==3.10.2' 'google-cloud-pubsub==2.43.0'
```

A função, em `~/gcp/budget/main.py`:

```python
# budget/main.py
"""main.py: what the shop does when a budget notification arrives.

Billing publishes to the topic at regular intervals, whether or not a
threshold was crossed, so the same state arrives many times. This acts once
per budget, per band, per month, and records what it did in seen.json; on
Google Cloud that record would be a Firestore document, since a function's
disk does not outlive it.
"""
import base64
import datetime as dt
import json
import pathlib

import functions_framework
from google.cloud import pubsub_v1

# budget id -> (name, [(share of the budget, action)]), highest share first
POLICY = {
    "b-shop": ("shop", [(1.0, "page"), (0.8, "ticket")]),
    "b-sandbox": ("sandbox", [(1.0, "stop-sandbox")]),
}
SEEN = pathlib.Path("seen.json")
ACTIONS = "projects/planner-dev/topics/ops-actions"
publisher = pubsub_v1.PublisherClient()


def month():
    # budget periods start at midnight Pacific Time, UTC-8
    return dt.datetime.now(dt.timezone(dt.timedelta(hours=-8))).strftime("%Y-%m")


@functions_framework.cloud_event
def on_budget(event):
    message = event.data["message"]
    budget_id = message["attributes"]["budgetId"]
    data = json.loads(base64.b64decode(message["data"]))
    share = data["costAmount"] / data["budgetAmount"]
    name, bands = POLICY.get(budget_id, (budget_id, []))
    print(f"{name}: {data['costAmount']} of {data['budgetAmount']} {data['currencyCode']} ({share:.0%})")

    action = next((a for limit, a in bands if share >= limit), None)
    if action is None:
        return
    seen = json.loads(SEEN.read_text()) if SEEN.exists() else {}
    key = f"{budget_id}/{month()}/{action}"
    if key in seen:
        print(f"{name}: {action} already done this month")
        return
    publisher.publish(ACTIONS, json.dumps(data).encode(), action=action, budget=name).result()
    seen[key] = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    SEEN.write_text(json.dumps(seen, indent=1))
    print(f"{name}: {action}")
```

Ela carrega três decisões:

- **Qual orçamento é qual** vem do atributo `budgetId`. No Google Cloud é um id que o Google atribui, e que o Terraform
  informa depois de um apply; aqui os dois são `b-shop` e `b-sandbox`.
- **O orçamento da loja nunca para nada.** Em 80% ele abre um chamado e em 100% aciona alguém. Só o orçamento do
  sandbox tem uma ação que muda recursos, e a próxima etapa é sobre o porquê.
- **Ela age uma vez por faixa por mês**, porque o mesmo estado chega muitas vezes. Sem o `seen.json`, a mensagem de 82%
  abriria um segundo chamado, e cada atualização até o dia 1º abriria outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O Billing publica o estado do orçamento no tópico budget-alerts. Uma assinatura push entrega cada mensagem à função, que escolhe uma faixa, confere o seen.json, e publica no máximo uma decisão por faixa por mês no ops-actions: ticket, page ou stop-sandbox.\"><defs><marker id=\"ah11\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"80\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Billing</text><text x=\"80\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">você, no lab</text><rect x=\"180\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">budget-alerts</text><rect x=\"360\" y=\"30\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">função</text><text x=\"440\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">on_budget</text><text x=\"440\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seen.json</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ops-actions</text><line x1=\"142\" y1=\"65\" x2=\"178\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah11)\"></line><line x1=\"322\" y1=\"65\" x2=\"358\" y2=\"65\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah11)\"></line><line x1=\"522\" y1=\"65\" x2=\"558\" y2=\"65\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah11)\"></line><text x=\"340\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">push</text><rect x=\"560\" y=\"120\" width=\"140\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ticket</text><rect x=\"560\" y=\"154\" width=\"140\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">page</text><rect x=\"560\" y=\"188\" width=\"140\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stop-sandbox</text><line x1=\"630\" y1=\"92\" x2=\"630\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line></svg>", "caption": "Aqui você faz o papel da primeira caixa à mão; tudo depois dela é o que rodaria no Google Cloud.", "same": ["Billing"]}
```

## Rodando

Suba a função em `~/gcp/budget`, num terminal onde as oito linhas da lição 1 foram digitadas, já que ela lê
`PUBSUB_EMULATOR_HOST` para achar o emulador. O `&` a roda em segundo plano, e o que ela imprime vai para `ff.log`:

```sh
functions-framework --target on_budget --port 8080 > ff.log 2>&1 &
```

O emulador roda num contêiner, então ele alcança o seu computador pela ponte do Docker, e o endpoint de push precisa
nomear esse endereço em vez de `localhost`. Depois, dois tópicos, uma assinatura push que entrega as mensagens do
orçamento à função, e uma assinatura pull para ler o que ela fez:

```
ana@laptop:~/gcp/budget$ docker network inspect bridge --format "{{(index .IPAM.Config 0).Gateway}}"
172.17.0.1
ana@laptop:~/gcp/budget$ gcloud pubsub topics create budget-alerts ops-actions
Created topic [projects/planner-dev/topics/budget-alerts].
Created topic [projects/planner-dev/topics/ops-actions].
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions create budget-act --topic budget-alerts --push-endpoint http://172.17.0.1:8080/
Created subscription [projects/planner-dev/subscriptions/budget-act].
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions create ops-read --topic ops-actions
Created subscription [projects/planner-dev/subscriptions/ops-read].
```

Agora cinco atualizações, como o Billing as mandaria ao longo de um mês, a terceira só alguns dólares acima da
segunda. Cada publicação imprime um id de mensagem, que fica de fora aqui:

```
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 385.12, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 566.40, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 571.93, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-sandbox,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 40.85, "budgetAmount": 40, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ gcloud pubsub topics publish budget-alerts --attribute budgetId=b-shop,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{"costAmount": 703.18, "budgetAmount": 700, "currencyCode": "USD"}' > /dev/null
ana@laptop:~/gcp/budget$ cat ff.log
shop: 385.12 of 700 USD (55%)
shop: 566.4 of 700 USD (81%)
shop: ticket
shop: 571.93 of 700 USD (82%)
shop: ticket already done this month
sandbox: 40.85 of 40 USD (102%)
sandbox: stop-sandbox
shop: 703.18 of 700 USD (100%)
shop: page
ana@laptop:~/gcp/budget$ gcloud pubsub subscriptions pull ops-read --auto-ack --limit 10 --format "table(message.attributes.budget, message.attributes.action)"
BUDGET   ACTION
shop     ticket
sandbox  stop-sandbox
shop     page
ana@laptop:~/gcp/budget$ cat seen.json
{
 "b-shop/2026-10/ticket": "2026-10-30T21:54:38+00:00",
 "b-sandbox/2026-10/stop-sandbox": "2026-10-30T21:54:44+00:00",
 "b-shop/2026-10/page": "2026-10-30T21:54:47+00:00"
}
```

**Cinco mensagens, três ações.** Os 55% estavam abaixo de todas as faixas. Os 82% estavam na mesma faixa dos 81%
anteriores, e o `seen.json` impediu um segundo chamado. No Google Cloud as mesmas linhas vão para o Cloud Logging, onde
as métricas de log da lição 10 podem contá-las.
