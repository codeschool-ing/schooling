---
title: Entrega exatamente uma vez, e o que ela cobre
version: 1
---

**O Pub/Sub tem uma configuração chamada entrega exatamente uma vez, e ela é mais estreita que o
nome.** A ajuda do `gcloud` para `--enable-exactly-once-delivery` diz o que ela promete, para um dado id
de mensagem naquela assinatura: a mensagem não é mandada de novo antes de o prazo de ack expirar, e uma
mensagem confirmada não é mandada de novo. As duas são promessas sobre **a nova entrega de um id de
mensagem**. Nenhuma cobre as cópias do publicador, que têm ids próprios, e nenhuma cobre o que o
trabalho do consumidor fez antes do ack.

## Duas assinaturas lado a lado

Um tópico, uma assinatura comum e uma com a configuração, e um recibo publicado para as duas:

```
ana@laptop:~/gcp$ gcloud pubsub topics create receipts
Created topic [projects/planner-dev/topics/receipts].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create receipts-plain --topic=receipts
Created subscription [projects/planner-dev/subscriptions/receipts-plain].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create receipts-once --topic=receipts --enable-exactly-once-delivery
Created subscription [projects/planner-dev/subscriptions/receipts-once].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe receipts-once --format='value(enableExactlyOnceDelivery)'
True
ana@laptop:~/gcp$ gcloud pubsub topics publish receipts --message='{"order_id": "o-307", "cents": 3100}'
messageIds:
- '10'
```

A checagem, salva como `~/gcp/eo_check.py`, segura uma mensagem além do prazo, como faz um consumidor
lento, e depois dá ack com o ack id que recebeu primeiro:

```schooling-example
{"language": "python", "file": "eo_check.py", "parts": [{"code": "import sys\nimport time\n\nfrom google.api_core.exceptions import InvalidArgument\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\n\n\ndef pull():\n    return subscriber.pull(subscription=path, max_messages=1, timeout=5).received_messages\n\n\n", "note": "A mesma checagem contra a assinatura que for indicada, para que os dois tipos possam ser comparados linha a linha."}, {"code": "first = pull()[0]\nprint(f'pulled id {first.message.message_id}, not acked; waiting 12 s')\ntime.sleep(12)\nsecond = pull()[0]\nprint(f'pulled id {second.message.message_id} again, with a new ack id')\n", "note": "**Um consumidor lento demais**: ele segura uma mensagem além do prazo de 10 segundos, então a mensagem é entregue de novo, com um ack id novo."}, {"code": "try:\n    subscriber.acknowledge(subscription=path, ack_ids=[first.ack_id])\n    print('ack with the first, expired ack id: accepted')\nexcept InvalidArgument as e:\n    print(f'ack with the first, expired ack id: refused, {e.reason}')\n", "note": "Depois ele termina o trabalho e dá ack com o ack id que recebeu primeiro, que já expirou. **Esta é a linha em que os dois tipos de assinatura se separam.**"}, {"code": "subscriber.acknowledge(subscription=path, ack_ids=[second.ack_id])\nprint('ack with the second: accepted')\ntime.sleep(12)\nprint(f'after another 12 s: {len(pull())} message(s)')\n", "note": "O ack com o ack id atual, e um último pull depois do prazo para ver se a mensagem ainda está lá."}]}
```

```
ana@laptop:~/gcp$ python3 eo_check.py receipts-plain
pulled id 10, not acked; waiting 12 s
pulled id 10 again, with a new ack id
ack with the first, expired ack id: accepted
ack with the second: accepted
after another 12 s: 0 message(s)
ana@laptop:~/gcp$ python3 eo_check.py receipts-once
pulled id 10, not acked; waiting 12 s
pulled id 10 again, with a new ack id
ack with the first, expired ack id: refused, EXACTLY_ONCE_ACKID_FAILURE
ack with the second: accepted
after another 12 s: 0 message(s)
```

**As duas assinaturas se comportaram igual em todas as linhas menos uma.** As duas entregaram de novo a
mensagem 10 quando o prazo acabou: a entrega exatamente uma vez não impede uma nova entrega depois do
prazo, só promete nenhuma antes dele. A diferença é o ack com o id expirado. A assinatura comum o aceitou
e não disse nada, então um consumidor não consegue distinguir um ack que funcionou de um que não fez
nada. A assinatura exatamente uma vez **o recusou, com o motivo `EXACTLY_ONCE_ACKID_FAILURE`**, que é o
erro do próprio serviço, e o emulador o reproduz. É nessa recusa que a garantia se apoia: um consumidor
que recebe resposta de sucesso ao ack sabe que a mensagem não volta, e um que recebe falha sabe que o
trabalho dele pode ser repetido por quem tem a entrega mais nova.

**No cliente de streaming, a resposta vem de `message.ack_with_response()`**, que devolve um future. A
documentação da biblioteca diz que numa assinatura exatamente uma vez o future dar certo garante que a
mensagem não será entregue de novo, e falhar significa que ela pode ser; numa assinatura comum ele dá
certo na hora, aconteça o que acontecer, porque o ack é de melhor esforço. Um consumidor que quer a
garantia espera esse future antes de tratar a mensagem como terminada.

## O que ela não tira

A nova tentativa do publicador da segunda seção, na assinatura exatamente uma vez:

```
ana@laptop:~/gcp$ gcloud pubsub topics publish receipts --message='{"order_id": "o-308", "cents": 2750}' && gcloud pubsub topics publish receipts --message='{"order_id": "o-308", "cents": 2750}'
messageIds:
- '11'
messageIds:
- '12'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull receipts-once --auto-ack --limit=10 --format='table(message.messageId:label=ID,message.data.decode(base64).decode(utf-8):label=DATA)'
ID  DATA
11  {"order_id": "o-308", "cents": 2750}
12  {"order_id": "o-308", "cents": 2750}
```

**Dois ids de mensagem, um pagamento, os dois entregues.** A entrega exatamente uma vez é sobre um id de
cada vez, e estes são dois. A chave de idempotência nos dados continua sendo a única coisa que os pega,
que é a deduplicação pelo id do pedido da seção do reprocessamento.

Mais quatro limites vêm da documentação do Google sobre o recurso,
cloud.google.com/pubsub/docs/exactly-once-delivery, e nenhum deles aparece no emulador:

- **Só pull.** Assinaturas de push e as assinaturas do BigQuery e do Cloud Storage da aula 19 não a
  oferecem.
- **Dentro de uma região.** A garantia vale para consumidores que se conectam à mesma região; um
  consumidor em outra região recebe o comportamento comum.
- **Mais lenta.** Todo ack vira uma ida e volta cuja resposta o consumidor espera, e o Google documenta
  uma latência maior entre publicação e assinatura nessas assinaturas.
- **Nada além do ack.** Um consumidor que soma um pagamento e depois não dá ack o soma de novo quando a
  nova entrega chega, exatamente como o `totals.py` fez no modo `plain`. A garantia é sobre o lado do
  Pub/Sub no aperto de mão, e o efeito continua sendo do consumidor.

## Ordem e duplicados são dois problemas

**Um consumidor pode ver cada mensagem uma vez na ordem errada, ou na ordem certa duas vezes**, e
resolver um não faz nada pelo outro. As ferramentas também são diferentes:

| o problema | o que o resolve |
|---|---|
| uma nova tentativa do publicador: dois ids, um evento | uma chave de idempotência nos dados, registrada junto com o efeito |
| uma nova entrega: um id, entregue duas vezes | a mesma chave, ou a entrega exatamente uma vez com acks esperados |
| um reprocessamento com seek | a mesma chave, ou um destino idempotente |
| um status que não pode andar para trás | uma versão ou timestamp no evento, e uma escrita aplicada só se for mais nova |
| a ordem de uma chave depois de uma falha | uma chave de ordenação, com os duplicados que a nova entrega dela traz |

**As duas últimas linhas precisam de um campo que o publicador escreve.** Quando os eventos do mesmo
pedido podem chegar fora de ordem, o evento carrega uma versão ou um horário do momento em que
aconteceu, e o destino aplica uma escrita só se ela for mais nova que o que ele guarda: em SQL, um
`UPDATE ... WHERE version < ?`; no Firestore, uma transação que lê a versão primeiro. É a mesma ideia da
deduplicação, comparando um número em vez de testar existência.

**Exatamente uma vez é de ponta a ponta ou nada, e a ponta é onde o efeito cai.** O Dataflow, na aula
21, lê o Pub/Sub e oferece processamento exatamente uma vez dentro do pipeline, registrando o que já
aplicou no seu próprio estado durável; a aula 21 diz o que isso cobre e onde fica a borda. Depois da
borda, uma linha num banco, um objeto num bucket, uma cobrança num cartão, o destino precisa ser
idempotente ou ter chave como o desta aula. O que rodou aqui, a queda e o reprocessamento, é o que todo
pipeline faz nessa borda, seja qual for o fluxo que ele lê.
