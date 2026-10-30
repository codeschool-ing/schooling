---
title: Onde o emulador é mais fraco, e a conta
version: 1
---

**O emulador atende toda chamada que o Pub/Sub tem e implementa só parte do que as chamadas
significam.** É fácil ler uma execução verde contra ele como uma execução contra o Google, e esta seção
existe para que ninguém faça isso. Algumas coisas ele faz exatamente como o serviço documenta, algumas
ele aceita e depois ignora, e de algumas ele não tem noção nenhuma. Tudo abaixo foi rodado nesta aula,
a não ser onde diz o contrário.

## O que ele fez como o serviço faz

- **Espalhamento e filtros.** Cada assinatura recebeu a própria cópia, e `billing` recebeu só o que o
  filtro dela selecionou.
- **Nova entrega.** Um nack, ou um 5xx de um endpoint de push, trouxe de volta o mesmo id de mensagem.
- **Dead letters.** Depois de cinco tentativas ele encaminhou a mensagem, com os atributos
  `CloudPubSubDeadLetterSource…` do próprio serviço, e recusou uma política que indicava um tópico
  inexistente.
- **Seek e snapshots.** O seek para um horário reprocessou as mensagens confirmadas que ele guardava, e
  o seek para um snapshot reprocessou o que veio depois dele.
- **Alguns limites.** Ele recusou uma retenção abaixo de dez minutos ou acima de 31 dias, e um prazo de
  ack acima de 600 segundos.
- **O ack da entrega exatamente uma vez**, que a aula 20 mostra: ele recusa um ack id expirado numa
  assinatura com entrega exatamente uma vez, com o motivo do próprio serviço.

## O que ele aceitou e fez diferente

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe billing
ackDeadlineSeconds: 10
deadLetterPolicy:
  deadLetterTopic: projects/planner-dev/topics/app-events-dead
  maxDeliveryAttempts: 5
filter: attributes.type = "payment"
messageRetentionDuration: 604800s
name: projects/planner-dev/subscriptions/billing
pushConfig: {}
topic: projects/planner-dev/topics/app-events
ana@laptop:~/gcp$ gcloud pubsub subscriptions create quick --topic=app-events --ack-deadline=5 && gcloud pubsub subscriptions describe quick --format='value(ackDeadlineSeconds)'
Created subscription [projects/planner-dev/subscriptions/quick].
5
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing-retry --topic=app-events --min-retry-delay=20s --max-retry-delay=60s
Created subscription [projects/planner-dev/subscriptions/billing-retry].
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message=retry-me > /dev/null && A=$(gcloud pubsub subscriptions pull billing-retry --format='value(ackId)') && gcloud pubsub subscriptions modify-message-ack-deadline billing-retry --ack-ids=$A --ack-deadline=0 > /dev/null 2>&1 && time gcloud pubsub subscriptions pull billing-retry --format='value(message.data)'
retry-me

real	0m1.535s
user	0m0.602s
sys	0m0.063s
ana@laptop:~/gcp$ gcloud pubsub topics create kept --message-retention-duration=1d && gcloud pubsub topics publish kept --message=before > /dev/null && gcloud pubsub subscriptions create kept-late --topic=kept && gcloud pubsub subscriptions pull kept-late --auto-ack --format='value(message.data)'
Created topic [projects/planner-dev/topics/kept].
Created subscription [projects/planner-dev/subscriptions/kept-late].
before
ana@laptop:~/gcp$ gcloud pubsub subscriptions create to-warehouse --topic=app-events --bigquery-table=planner-dev:quitanda.app_events
Created subscription [projects/planner-dev/subscriptions/to-warehouse].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe to-warehouse --format='yaml(bigqueryConfig,state)'
bigqueryConfig:
  table: planner-dev:quitanda.app_events
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message=to-the-warehouse > /dev/null && gcloud pubsub subscriptions pull to-warehouse --auto-ack --format='value(message.data)'
to-the-warehouse
```

**Cinco configurações, todas guardadas, e só a primeira aplicada como o Google
documenta.** A política de dead letter da quarta seção está ali na descrição, e foi respeitada. O resto
não foi. Um prazo de ack de 5 segundos foi aceito e guardado, onde o mínimo do serviço é 10. Uma
política de nova tentativa de 20 a 60 segundos também foi guardada, e a mensagem com nack voltou em 1,5 segundo, o tempo que o próprio comando leva. Uma assinatura criada num tópico que retém mensagens
recebeu `before`, uma mensagem publicada antes de a assinatura existir; no serviço, uma assinatura nova
começa vazia e só alcança o passado com um seek. E uma assinatura do BigQuery foi aceita com a tabela
dela, não gravou em lugar nenhum, porque aqui não há BigQuery, e entregou a mensagem dela a um pull
comum.

E uma que leva onze minutos, porque o relógio do emulador é o que está sendo testado. Uma assinatura que
guarda mensagens pelo mínimo de dez minutos, uma mensagem, e um pull depois de onze:

```
ana@laptop:~/gcp$ gcloud pubsub topics create ten-minutes && gcloud pubsub subscriptions create ten-minutes --topic=ten-minutes --message-retention-duration=10m && gcloud pubsub topics publish ten-minutes --message=old
Created topic [projects/planner-dev/topics/ten-minutes].
Created subscription [projects/planner-dev/subscriptions/ten-minutes].
messageIds:
- '47'
ana@laptop:~/gcp$ sleep 660; gcloud pubsub subscriptions pull ten-minutes --auto-ack --format='value(message.data)'
old
```

**A mensagem ainda estava lá onze minutos depois de uma retenção de dez.** O emulador guarda a
retenção, aplica os limites dela e nunca apaga nada por ela, então um consumidor que fica mais atrasado
que a retenção não perde nada aqui e perde tudo no Google, onde o backlog além dela é jogado fora sem
erro nenhum.

| | o Google documenta | o emulador, aqui |
|---|---|---|
| ordem depois de um nack | a mensagem de novo, depois as seguintes da chave | as seguintes da chave primeiro |
| política de nova tentativa | espera entre 20 e 60 segundos antes de entregar de novo | entregou de novo na hora |
| prazo de ack | de 10 a 600 segundos | aceitou 5 |
| uma assinatura nova num tópico com retenção | começa vazia, e pode fazer seek para trás | recebeu a mensagem publicada antes dela |
| retenção | apaga a mensagem quando expira | ainda entregou depois da retenção |
| assinaturas do BigQuery e do Cloud Storage | gravam linhas ou arquivos | aceitas, sem gravar nada, e lidas por pull |
| mudar um filtro | não é flag do `gcloud pubsub subscriptions update` | a chamada de API recusada, pelo nome |
| ids de mensagem | strings longas, sem ordem | 1, 2, 3 |

## Do que ele não tem noção

**Permissões, cotas e dinheiro.** O emulador não confere credencial nem papel do IAM, então as
concessões que um tópico de dead letter precisa, os papéis de publicador e assinante num tópico e o
token de um endpoint de push ficam sem teste aqui. Ele não tem cota e nunca limita, então um publicador
que funciona contra ele nunca encontrou um `RESOURCE_EXHAUSTED`. Ele não tem regiões, então "ordenado
dentro de uma região" e a política de armazenamento de mensagens que prende mensagens a regiões não
podem ser testados. E ele não cobra nada, que é o resto desta seção.

## A conta

O Pub/Sub cobra três coisas, e os preços vêm de cloud.google.com/pubsub/pricing, lida em 2026-10-30.
**Vazão custa US$ 40 por TiB, em todas as regiões do Google Cloud**, `southamerica-east1` incluída,
depois dos primeiros 10 GiB de cada mês, que são de graça. A vazão conta bytes publicados e bytes
entregues, uma vez para cada assinatura, e o tamanho de uma mensagem é os dados, os atributos, 20 bytes
de timestamp e o id da mensagem. **Armazenamento custa US$ 0,27 por GiB-mês**, para retenção no
tópico, mensagens confirmadas retidas, snapshots e um backlog guardado além do primeiro dia. Uma
assinatura do BigQuery ou do Cloud Storage custa **US$ 50 por TiB** no lugar do preço de entrega, sem os
10 GiB grátis. Mover mensagens entre regiões é cobrado como transferência de rede, e entre zonas a
página não cobra nada.

Duas linhas daquela página moldam o desenho mais que os preços. **Mensagens filtradas são cobradas como
entregues**: o Pub/Sub confirma o que um filtro recusa e cobra a vazão mesmo assim. E **uma requisição é
cobrada como pelo menos 1 KB**, então mensagens pequenas mandadas uma por requisição custam mais que o
tamanho delas. Um programa curto faz a conta para os eventos do app da Quitanda, salvo como
`~/gcp/bill.py`:

```schooling-example
{"language": "python", "file": "bill.py", "parts": [{"code": "GiB, TiB = 2**30, 2**40\nevents_a_day, size, days = 5_000_000, 600, 30\npublished = events_a_day * size * days\n\n", "note": "O app da Quitanda: cinco milhões de eventos por dia, 600 bytes cada um contando os atributos, os 20 bytes de timestamp e o id da mensagem, como a página de preços conta. Um mês de 30 dias."}, {"code": "throughput = published * (1 + 2)\nbilled = max(throughput - 10 * GiB, 0)\nprint(f'published        {published / GiB:8.2f} GiB')\nprint(f'throughput       {throughput / TiB:8.4f} TiB, {billed / TiB:.4f} TiB after the free 10 GiB')\nprint(f'throughput       ${billed / TiB * 40:7.2f}')\n\n", "note": "**Vazão é bytes publicados mais bytes entregues, uma vez por assinatura**: uma publicação e duas entregas, para `billing` e `analytics`. O filtro de `billing` não diminui a conta, porque mensagens filtradas são cobradas como entregues. Os primeiros 10 GiB do mês são de graça e o resto custa US$ 40 por TiB."}, {"code": "kept = events_a_day * size * 7\nprint(f'a week kept      {kept / GiB:8.2f} GiB, ${kept / GiB * 0.27:.2f} a month')\n\n", "note": "Sete dias de retenção no tópico guardam uma semana de eventos o tempo todo, a US$ 0,27 por GiB-mês."}, {"code": "alone = (events_a_day * 1000 * days + published * 2 - 10 * GiB) / TiB * 40\nprint(f'one per request  ${alone:7.2f}')\nprint(f'to BigQuery      ${published / TiB * 50:7.2f}')\n", "note": "**Os mesmos eventos publicados um por requisição**: cada requisição conta como pelo menos 1 KB, então cada evento de 600 bytes é cobrado como 1.000 bytes na entrada. A última linha precifica o analytics como uma assinatura do BigQuery: a parte dele, a US$ 50 por TiB e sem os 10 GiB grátis."}]}
```

```
ana@laptop:~/gcp$ python3 bill.py
published           83.82 GiB
throughput         0.2456 TiB, 0.2358 TiB after the free 10 GiB
throughput       $   9.43
a week kept         19.56 GiB, $5.28 a month
one per request  $  11.61
to BigQuery      $   4.09
```

**US$ 9,43 por mês levam todo evento aos dois serviços**, e uma semana de retenção no tópico soma US$
5,28. O filtro de `billing` não economizou nada: ela recebe dois eventos em oito e é cobrada pelos oito,
então um serviço de cobrança num tópico só dele, alimentado só com pagamentos, cortaria um terço da
linha de vazão. Publicar cada evento numa requisição própria sobe a conta de US$ 9,43 para US$ 11,61,
porque cada evento de 600 bytes conta como 1.000 na entrada, que é o que os lotes do publicador evitam.
E se o analytics fosse uma assinatura do BigQuery, a parte dele, 83,82 GiB, seria cobrada a US$ 50 por
TiB sem faixa grátis, US$ 4,09, sem nenhum consumidor da Quitanda para rodar.
