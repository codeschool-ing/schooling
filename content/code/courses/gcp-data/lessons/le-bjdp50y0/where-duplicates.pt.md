---
title: De onde vêm os duplicados
version: 1
---

**Um duplicado não é defeito do Pub/Sub; é o que uma nova tentativa correta produz.** Cinco lugares os
fazem nos pipelines deste curso, e cada um está fazendo a coisa certa quando faz. Um fica do lado do
publicador e dá à cópia um id de mensagem novo; os outros quatro ficam do lado da entrega e mantêm o
antigo, e essa diferença decide o que consegue pegá-los.

O laboratório é o da aula 19: o emulador do Pub/Sub num terminal só dele, iniciado com o comando da
primeira seção da aula 19, e este terminal com as linhas de "Every time you open a terminal" da aula
1. Reinicie o emulador, para que ele fique vazio; os ids de mensagem abaixo começam do 1.

## O publicador que tenta de novo

Um publicador manda uma mensagem e espera o id. Se a resposta se perde, porque a conexão caiu ou a
chamada estourou o tempo, o publicador não consegue distinguir uma mensagem que nunca foi guardada de
uma que foi guardada e cuja resposta sumiu. O único movimento seguro é mandar de novo, e se a primeira
tinha sido guardada, o tópico agora a tem duas vezes. As bibliotecas cliente do Google tentam de novo
uma publicação que falhou por conta própria, então isso acontece sem uma linha do código do publicador
pedir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um publicador e o Pub/Sub ao longo do tempo. O publicador publica o pagamento o-301; o Pub/Sub o guarda como mensagem de id 1 e responde, e a resposta se perde na volta. O publicador estoura o timeout, não sabe se a mensagem foi guardada e a publica de novo; o Pub/Sub a guarda como mensagem de id 2 e esta resposta chega. O tópico agora tem o-301 duas vezes, com dois ids de mensagem.\" data-fig=\"l20-retry\"><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">publicador</text><text x=\"560.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Pub/Sub</text><line x1=\"160.0\" y1=\"30.0\" x2=\"160.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"560.0\" y1=\"30.0\" x2=\"560.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"160.0\" y1=\"50.0\" x2=\"554.0\" y2=\"69.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,70.0 553.9,72.7 554.2,66.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">publish o-301</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">guardada: id 1</text><line x1=\"560.0\" y1=\"90.0\" x2=\"380.0\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"380.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">resposta perdida</text><rect x=\"10.0\" y=\"120.0\" width=\"140.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeout: guardou ou não?</text><line x1=\"160.0\" y1=\"160.0\" x2=\"554.0\" y2=\"179.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,180.0 553.9,182.7 554.2,176.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">publish o-301</text><text x=\"290.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o mesmo pagamento, de novo</text><rect x=\"570.0\" y=\"170.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">guardada: id 2</text><line x1=\"560.0\" y1=\"200.0\" x2=\"166.0\" y2=\"219.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,220.0 165.8,216.7 166.1,222.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"190.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id 2 devolvido</text></svg>", "caption": "Uma resposta perdida e uma nova tentativa correta: um pagamento, duas mensagens.", "same": ["Pub/Sub"]}
```

O emulador nunca perde uma resposta, então o laboratório não consegue provocar o timeout. Consegue
mostrar o resultado, que é o mesmo que publicar um pagamento duas vezes:

```
ana@laptop:~/gcp$ gcloud pubsub topics create retries
Created topic [projects/planner-dev/topics/retries].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create retries --topic=retries
Created subscription [projects/planner-dev/subscriptions/retries].
ana@laptop:~/gcp$ gcloud pubsub topics publish retries --message='{"order_id": "o-301", "cents": 4590}' --attribute=order_id=o-301
messageIds:
- '1'
ana@laptop:~/gcp$ gcloud pubsub topics publish retries --message='{"order_id": "o-301", "cents": 4590}' --attribute=order_id=o-301
messageIds:
- '2'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'
ID  ORDER  ACK_ID
1   o-301  projects/planner-dev/subscriptions/retries:1
2   o-301  projects/planner-dev/subscriptions/retries:2
```

**Duas mensagens, dois ids, dados idênticos.** O Pub/Sub não compara mensagens e não tem como saber que
a segunda é uma cópia: para o tópico, são dois eventos. Isso define qual chave pega este duplicado. O
id da mensagem não pega, porque a cópia ganhou um novo; só algo dentro da mensagem, posto ali pelo
publicador, pega. Essa é uma **chave de idempotência** (*idempotency key*), e para um pagamento é o id
do pedido, porque um pedido é pago uma vez. O `pay.py` da próxima seção a manda como atributo.

## O prazo de ack que acaba

As duas mensagens acima foram puxadas e não confirmadas. Cada uma foi emprestada a este terminal pelo
prazo de ack da assinatura, dez segundos, e um segundo pull as pede de novo:

```
ana@laptop:~/gcp$ time gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'
ID  ORDER  ACK_ID
1   o-301  projects/planner-dev/subscriptions/retries:3
2   o-301  projects/planner-dev/subscriptions/retries:4

real	0m9.792s
user	0m0.649s
sys	0m0.079s
ana@laptop:~/gcp$ gcloud pubsub subscriptions modify-message-ack-deadline retries --ack-ids=projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4 --ack-deadline=60
Set ackDeadlineSeconds to [60] for messages with ackId [projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4]] for subscription [projects/planner-dev/subscriptions/retries]
{}
ana@laptop:~/gcp$ timeout 20 gcloud pubsub subscriptions pull retries --limit=10 --format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'; echo "exit $?"
exit 124
ana@laptop:~/gcp$ gcloud pubsub subscriptions ack retries --ack-ids=projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4
Acked the messages with the following ackIds: [projects/planner-dev/subscriptions/retries:3,projects/planner-dev/subscriptions/retries:4]
{}
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull retries --limit=10
Listed 0 items.
```

**O segundo pull esperou, e recebeu as mesmas duas mensagens de volta quando o prazo delas acabou**,
uns dez segundos depois do primeiro, com os ack ids novos 3 e 4. Um consumidor que demora mais que o
prazo, ou morre segurando uma mensagem, produz exatamente isto: os mesmos ids de mensagem, entregues de
novo. A linha `modify-message-ack-deadline` é o remédio para um consumidor lento, e não morto. Ela
estendeu os dois empréstimos para sessenta segundos, e o pull seguinte não achou nada por vinte
segundos e foi parado pelo `timeout`, código de saída 124. Confirmadas, elas somem. O streaming pull do
cliente Python faz essa extensão sozinho enquanto um callback roda, como a aula 19 disse, então um
callback lento é seguro e um processo morto não é.

**Um ack id pertence a uma entrega.** Depois da nova entrega, os ack ids 1 e 2 do primeiro pull não se
referem a nada. Numa assinatura comum, um ack com um id expirado é aceito sem erro, e nada diz se ele
fez alguma coisa; a última seção desta aula mostra isso. A documentação da própria biblioteca Python
chama os acks de melhor esforço numa assinatura dessas por esse motivo.

## O consumidor que cai

Um consumidor que faz o trabalho e depois dá ack morre entre os dois, e toda mensagem que ele tinha
puxado e não confirmado volta depois do prazo. É o reprocessamento da próxima seção, feito de
propósito. **Esses duplicados mantêm os ids de mensagem**, porque são as mesmas mensagens entregues duas
vezes, o que os torna mais fáceis de pegar que os do publicador.

## O serviço que tenta de novo por você

Um endpoint de push que responde 503, ou responde devagar demais, recebe a mensagem de novo, e o
`receiver.py` da aula 19 recebeu a mensagem 17 três vezes. Um endpoint que fez o trabalho e depois não
respondeu a tempo o faz de novo na nova tentativa. E uma assinatura ordenada, segundo o Google, entrega
de novo uma mensagem com nack junto com todas as mensagens seguintes da chave, inclusive as já
confirmadas: ali os duplicados são o preço da ordem.

## Dois que não são duplicados

**Um segundo evento parecido com o primeiro não é duplicado.** Dois pedidos de `c-17` do mesmo valor no
mesmo dia são dois pedidos; uma chave feita de cliente, valor e dia juntaria os dois e perderia dinheiro
na outra direção. A chave de idempotência precisa identificar o evento, não descrevê-lo, e por isso é
um id que o publicador atribui uma vez, quando o evento acontece, e nunca deriva depois.

E **uma mensagem fora de ordem também não é duplicado**. Sem chave de ordenação, o Pub/Sub entrega sem
ordem nenhuma, e a aula 19 mostrou o emulador quebrando até a ordem de uma chave depois de um nack. Uma
deduplicação tira cópias e não faz nada pela ordem; um consumidor que se importa com as duas coisas
precisa da chave de idempotência para as cópias e de uma versão ou timestamp nos dados para a ordem,
assunto a que a última seção desta aula volta.
