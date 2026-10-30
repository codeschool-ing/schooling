---
title: Um alerta sobre o qual um programa pode agir
version: 1
---

**Um e-mail aos 90% é lido por uma pessoa, uma hora. Uma mensagem do Pub/Sub aos 90% é lida por um
programa, na hora.** É para isso que serve o `all_updates_rule` do orçamento: a cada poucas horas, o Google
publica o estado do orçamento no tópico como uma mensagem JSON, e quem assina decide o que fazer. Esta é a
única parte do faturamento que o laboratório consegue rodar, porque o tópico é Pub/Sub, e o Pub/Sub é o que
o emulador responde.

## O tópico, a assinatura, e uma mensagem

Crie o tópico que o orçamento nomeia, e uma assinatura de onde lê-lo:

```
ana@laptop:~/gcp$ gcloud pubsub topics create budget-alerts
Created topic [projects/planner-dev/topics/budget-alerts].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create budget-alerts-sub --topic=budget-alerts
Created subscription [projects/planner-dev/subscriptions/budget-alerts-sub].
```

O Google publicaria agora no `budget-alerts`. No laboratório ninguém publica, então **as mensagens abaixo
foram escritas por este curso**, no formato que a documentação de faturamento do Google dá para as
notificações de orçamento, e publicadas com o `gcloud` no lugar do Google. Os campos e os atributos são do
Google; os números são o mês inventado do planner. Três momentos dele: o começo do mês, depois do limite de
90%, e depois do orçamento.

```
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "costAmount": 84.17, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '1'
```

## Um programa que as lê

O programa abaixo puxa da assinatura, lê cada mensagem e imprime o que faria. Ele usa a biblioteca cliente
do Google do ambiente virtual da lição 1, e como o `env.sh` define o `PUBSUB_EMULATOR_HOST`, a biblioteca
fala com o emulador sem que ninguém mande. Salve-o como `~/gcp/on_budget.py`:

```schooling-example
{"language": "python", "file": "on_budget.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Reads budget notifications and decides what to do about each one.\n\n    python3 on_budget.py\n\nPulls what is waiting on the subscription budget-alerts-sub, prints a\ndecision for each message and acknowledges it.\n\"\"\"\nimport json\n\nfrom google.cloud import pubsub_v1\n\nPROJECT = 'planner-dev'\nSUBSCRIPTION = 'budget-alerts-sub'\n\n", "note": "Para que serve o programa, e a assinatura a ler, pelo nome. Nada aqui diz onde está o Pub/Sub: a biblioteca lê o `PUBSUB_EMULATOR_HOST` do ambiente, e contra o Google o mesmo arquivo leria a assinatura real."}, {"code": "subscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path(PROJECT, SUBSCRIPTION)\nresponse = subscriber.pull(request={'subscription': path, 'max_messages': 10}, timeout=10)\n\n", "note": "Um pull síncrono: pedir até dez mensagens e pegar o que houver. Um serviço que roda o dia todo usaria o pull em streaming; um pull basta para ler uma mensagem de cada vez."}, {"code": "for received in response.received_messages:\n    data = json.loads(received.message.data)\n    spent, budget = data['costAmount'], data['budgetAmount']\n    share = spent / budget\n    print(f\"{data['budgetDisplayName']}: {spent:.2f} of {budget:.2f} {data['currencyCode']} ({share:.0%})\")\n", "note": "O corpo da mensagem é o JSON que o Google documenta. O `costAmount` é o gasto do mês até agora, o `budgetAmount` o orçamento, e a fração é calculada aqui em vez de confiada a um campo de limite, que falta até um ser ultrapassado."}, {"code": "    if share >= 1:\n        print('  over budget: this is where billing would be disabled')\n    elif 'alertThresholdExceeded' in data:\n        print(f\"  crossed {data['alertThresholdExceeded']:.0%}: tell the team\")\n    else:\n        print('  no threshold crossed: nothing to do')\n    subscriber.acknowledge(request={'subscription': path, 'ack_ids': [received.ack_id]})\n", "note": "A decisão. Depois do orçamento, uma versão real chamaria a API do Cloud Billing para desvincular o projeto, o interruptor da lição 11; esta diz isso e não faz nada. Confirmar diz ao Pub/Sub que a mensagem foi tratada, para ela não ser entregue de novo."}]}
```

Rode-o agora, e de novo depois de cada uma das próximas duas mensagens:

```
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 84.17 of 300.00 USD (28%)
  no threshold crossed: nothing to do
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "alertThresholdExceeded": 0.9, "costAmount": 273.40, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '2'
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 273.40 of 300.00 USD (91%)
  crossed 90%: tell the team
ana@laptop:~/gcp$ gcloud pubsub topics publish budget-alerts --attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0 --message='{"budgetDisplayName": "planner monthly", "alertThresholdExceeded": 1.0, "costAmount": 318.92, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}'
messageIds:
- '3'
ana@laptop:~/gcp$ python3 on_budget.py
planner monthly: 318.92 of 300.00 USD (106%)
  over budget: this is where billing would be disabled
```

Entre as execuções, a transcrição publica o momento seguinte do mês: 273,40 dólares, quando o Google
acrescentaria `alertThresholdExceeded: 0.9`, e depois 318,92, além do orçamento.

**A terceira mensagem é aquela de que um teto é feito.** Aos 106% o programa desligaria o faturamento dos
projetos do orçamento, e o gasto pararia: tudo que a seção da lição 11 sobre desvincular descreve
aconteceria com eles. A documentação de faturamento do Google dá exatamente esse arranjo como o jeito de
limitar custos, com uma função do Cloud Run no lugar do assinante, e avisa no mesmo fôlego que ele pode
apagar recursos. **Essa é a troca que um teto faz**, e é por isso que a maioria dos projetos de produção
para no e-mail e na pessoa.

Toda linha de saída acima é do laboratório: o emulador entregou as mensagens e o programa decidiu. O que o
laboratório não consegue mostrar é o Google publicando-as, nem o desvínculo que a terceira pede.
