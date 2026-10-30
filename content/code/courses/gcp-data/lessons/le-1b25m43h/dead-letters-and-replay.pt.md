---
title: Dead letters, retenção e seek
version: 1
---

**Uma mensagem que nunca pode ser processada não vai embora sozinha.** O consumidor dá nack, o Pub/Sub
a entrega de novo, o consumidor dá nack de novo, e o ciclo dura até a retenção da assinatura jogar a
mensagem fora, sete dias depois por padrão. Enquanto isso a mensagem custa uma entrega a cada vez e,
numa assinatura ordenada, segura a chave inteira. É uma **mensagem envenenada** (*poison message*), e a
resposta é um **tópico de dead letter**: depois de um número definido de tentativas de entrega, o
Pub/Sub para de entregar a mensagem à assinatura e a publica em outro tópico, onde alguém pode olhá-la.
A segunda metade desta seção é o problema oposto, uma mensagem que já foi processada e precisa ser
processada de novo.

## Um tópico de dead letter para a cobrança

O serviço de cobrança da Quitanda recebe um pagamento cujo valor alguém digitou como `"23,50"`, com
vírgula decimal, onde o serviço espera centavos inteiros. Primeiro a política de dead letter, que
indica um tópico que já precisa existir:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5
ERROR: (gcloud.pubsub.subscriptions.update) NOT_FOUND: Dead letter topic not found
ana@laptop:~/gcp$ gcloud pubsub topics create app-events-dead
Created topic [projects/planner-dev/topics/app-events-dead].
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=3 2>&1 | head -1
ERROR: (gcloud.pubsub.subscriptions.update) argument --max-delivery-attempts: Value must be greater than or equal to 5; received: 3
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5
Updated subscription [projects/planner-dev/subscriptions/billing].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing-dead --topic=app-events-dead
Created subscription [projects/planner-dev/subscriptions/billing-dead].
```

**O número de tentativas vai de 5 a 100**, diz a ajuda do `gcloud`, e a recusa do 3 veio do próprio
`gcloud`, antes de qualquer requisição sair. `billing-dead` é a assinatura de onde alguém lê as dead
letters; um tópico de dead letter é um tópico comum, e uma mensagem publicada nele sem assinatura não
seria guardada por ninguém, como a primeira seção mostrou.

**No Google há mais um passo, e o emulador não pede.** O Pub/Sub move as dead letters com uma conta de
serviço própria, o agente de serviço do Pub/Sub do projeto, e o Google documenta que ele precisa de
permissão para publicar no tópico de dead letter e para assinar a assinatura de origem. Sem as duas
concessões, a política é aceita e as dead letters não são encaminhadas. O emulador não confere
permissão nenhuma, então este laboratório não mostra essa falha.

O worker de cobrança, salvo como `~/gcp/billing_worker.py`:

```schooling-example
{"language": "python", "file": "billing_worker.py", "parts": [{"code": "import json\nfrom concurrent.futures import TimeoutError\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', 'billing')\n\n\n", "note": "O serviço de cobrança, reduzido à parte que pode falhar: ler um pagamento."}, {"code": "def callback(message):\n    try:\n        payment = json.loads(message.data)\n        cents = int(payment['cents'])\n    except (ValueError, KeyError) as e:\n        print(f'id {message.message_id:>3}  attempt {message.delivery_attempt}  nack: {e}', flush=True)\n        message.nack()\n        return\n", "note": "**Um pagamento que ele não consegue ler recebe nack, não ack, e não é descartado.** Dar ack perderia um pagamento em silêncio; o nack pede a mensagem de novo. `delivery_attempt` conta as entregas, e só vem preenchido numa assinatura com tópico de dead letter."}, {"code": "    print(f\"id {message.message_id:>3}  attempt {message.delivery_attempt}  billed {payment['order_id']} {cents}\", flush=True)\n    message.ack()\n\n\n", "note": "Um pagamento que ele consegue ler é cobrado e recebe ack."}, {"code": "future = subscriber.subscribe(path, callback=callback)\nwith subscriber:\n    try:\n        future.result(timeout=8)\n    except TimeoutError:\n        future.cancel()\n        future.result()\n", "note": "O mesmo streaming pull do `subscriber.py`, parado depois de oito segundos."}]}
```

```
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message='{"order_id": "o-304", "cents": "23,50"}' --attribute=type=payment,customer_id=c-05
messageIds:
- '26'
ana@laptop:~/gcp$ python3 billing_worker.py
id  12  attempt 1  billed o-301 4590
id  15  attempt 1  billed o-302 12800
id  17  attempt 1  billed o-303 990
id  26  attempt 1  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 2  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 3  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 4  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 5  nack: invalid literal for int() with base 10: '23,50'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull billing-dead --auto-ack --format='yaml(message.data.decode(base64).decode(utf-8),message.attributes)'
---
message:
  attributes:
    CloudPubSubDeadLetterSourceDeliveryCount: '5'
    CloudPubSubDeadLetterSourceSubscription: billing
    CloudPubSubDeadLetterSourceSubscriptionProject: planner-dev
    CloudPubSubDeadLetterSourceTopicPublishTime: '2026-10-30T19:00:51.837Z'
    customer_id: c-05
    type: payment
  data: '{"order_id": "o-304", "cents": "23,50"}'
```

**O worker cobrou os três pagamentos que esperavam em `billing` e tentou o quarto cinco vezes.** Os
pagamentos com ids 12 e 15 vieram da segunda execução do `events.py`, e o 17 do teste de push. Depois do
quinto nack o emulador parou de entregar a mensagem 26 e a publicou em `app-events-dead`, com os dados e
os atributos como estavam e quatro atributos novos que dizem de onde ela veio e quantas vezes foi
tentada. Este é um dos lugares em que o emulador faz o que o serviço faz: encaminha, com os nomes de
atributo do próprio serviço. `delivery_attempt` contou de 1 a 5 porque a assinatura tem política de
dead letter; sem ela o campo vem vazio, e a documentação da própria biblioteca chama a contagem de
melhor esforço e aproximada.

**Uma dead letter é uma pergunta para uma pessoa, não uma mensagem para tentar de novo.** O bug do
worker se corrige lendo valores com vírgula, e a dead letter então é publicada de novo em `app-events`,
à mão ou por um programinha que lê `billing-dead`. Republicá-la sem a correção a manda pelas mesmas
cinco tentativas. E numa assinatura ordenada uma dead letter sai da sequência da chave para sempre: as
mensagens depois dela são entregues como se ela nunca tivesse existido.

## Por quanto tempo uma mensagem fica guardada

Três configurações decidem por quanto tempo uma mensagem ainda pode ser lida, e cada uma mora num
lugar diferente:

| configuração | onde | padrão e faixa, pela ajuda do `gcloud` | guarda |
|---|---|---|---|
| `--message-retention-duration` | assinatura | 7 dias, de 10 minutos a 31 dias | mensagens sem ack |
| `--retain-acked-messages` | assinatura | desligada | também as confirmadas, pelo mesmo tempo |
| `--message-retention-duration` | tópico | desligada, de 10 minutos a 31 dias | toda mensagem publicada, para toda assinatura |

**A retenção é o tamanho da segunda chance.** Um consumidor publicado na sexta com um bug, descoberto
na segunda, só consegue reprocessar o fim de semana se as mensagens do fim de semana ainda existirem
depois de confirmadas. Por padrão não existem: uma mensagem confirmada some da sua assinatura.

## Seek: ler de novo

`seek` move a posição de uma assinatura. Para um **horário**, marca como confirmada toda mensagem
guardada publicada antes desse horário e como não confirmada toda mensagem depois dele, e estas são
entregues de novo. Para um **snapshot**, volta ao estado capturado quando o snapshot foi feito. O
analytics liga a retenção das mensagens confirmadas, lê, e depois volta dez minutos:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions update analytics --retain-acked-messages
Updated subscription [projects/planner-dev/subscriptions/analytics].
ana@laptop:~/gcp$ python3 events.py > /dev/null && python3 subscriber.py analytics
id  10  view         {"product": "tomate"}
id  17  payment      {"order_id": "o-303", "cents": 990}
id  26  payment      {"order_id": "o-304", "cents": "23,50"}
id  28  view         {"product": "banana-prata"}
id  29  view         {"product": "tomate"}
id  30  add_to_cart  {"product": "banana-prata", "qty": 6}
id  31  payment      {"order_id": "o-301", "cents": 4590}
id  32  search       {"text": "manga"}
id  33  add_to_cart  {"product": "tomate", "qty": 2}
id  34  payment      {"order_id": "o-302", "cents": 12800}
id  35  view         {"product": "manga-palmer"}
ana@laptop:~/gcp$ python3 subscriber.py analytics
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek analytics --time=$(date -d '10 minutes ago' -Iseconds)
subscriptionId: projects/planner-dev/subscriptions/analytics
time: '2026-10-30T18:51:13.000000Z'
ana@laptop:~/gcp$ python3 subscriber.py analytics | wc -l
11
```

**Onze mensagens lidas, nada sobrando, e depois do seek as mesmas onze de novo.** A primeira leitura
também limpou o que `analytics` vinha segurando: a mensagem 10, emprestada ao `gcloud` e nunca
confirmada na segunda seção, e os dois pagamentos publicados desde então. As onze são as mensagens
confirmadas depois que a retenção foi ligada. As confirmadas antes, ids 1 a 9 e 11 a 16, não foram
guardadas, e seek nenhum as traz de volta.

Um **snapshot** é a ferramenta mais segura antes de uma mudança, porque não depende de adivinhar um
horário. Antes de publicar uma versão nova do job de analytics, a posição antiga é salva:

```
ana@laptop:~/gcp$ gcloud pubsub snapshots create analytics-before-deploy --subscription=analytics
Created snapshot [projects/planner-dev/snapshots/analytics-before-deploy].
ana@laptop:~/gcp$ python3 events.py > /dev/null && python3 subscriber.py analytics | wc -l
8
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek analytics --snapshot=analytics-before-deploy
snapshotId: projects/planner-dev/snapshots/analytics-before-deploy
subscriptionId: projects/planner-dev/subscriptions/analytics
ana@laptop:~/gcp$ python3 subscriber.py analytics | wc -l
8
```

A versão nova leu oito eventos; o seek para o snapshot devolveu os mesmos oito para serem lidos de
novo. **Um snapshot guarda o que estava sem ack quando foi tirado e tudo o que foi publicado depois.**
O Google documenta que ele dura no máximo sete dias, menos a idade da mensagem mais antiga que guarda,
e a página de preços cobra o armazenamento dele como retenção. A aula 20 usa um snapshot para
reprocessar um fluxo de pagamentos por um consumidor que precisa chegar aos mesmos totais.

**A retenção no tópico é a configuração que não depende de nenhuma assinatura:**

```
ana@laptop:~/gcp$ gcloud pubsub topics update app-events --message-retention-duration=7d
Updated topic [projects/planner-dev/topics/app-events].
ana@laptop:~/gcp$ gcloud pubsub topics describe app-events
messageRetentionDuration: 604800s
name: projects/planner-dev/topics/app-events
```

Com ela, toda mensagem publicada em `app-events` fica guardada por sete dias, confirmada por quem
for, e a ajuda do `gcloud` diz que ela permite a qualquer assinatura ligada fazer seek até esse tempo
para trás. Isso inclui uma assinatura criada depois, como a checagem de fraude da primeira seção, que
pode ir para uma semana atrás e ler a semana. **É também o jeito mais barato de guardar histórico para
várias assinaturas**, porque o tópico guarda uma cópia onde reter mensagens confirmadas guarda uma por
assinatura. A última seção põe preço nisso.
