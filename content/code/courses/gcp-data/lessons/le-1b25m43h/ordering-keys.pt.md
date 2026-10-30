---
title: Chaves de ordenação, e a ordem que o emulador não mantém
version: 1
---

**Sem chave de ordenação, o Pub/Sub não promete ordem nenhuma**, nem entre duas mensagens do mesmo
publicador com um segundo de diferença. Um leitor que imagina o tópico como uma fila só de eventos,
lidos de volta na ordem em que aconteceram, um dia vai marcar um pedido como entregue antes de ele ser
feito. O serviço é feito de muitas máquinas que guardam e entregam em paralelo, e ordem custa algo que
ele não gasta se ninguém pedir. O que ele oferece no lugar é uma **chave de ordenação** (*ordering
key*): uma string em cada mensagem, e a promessa de que mensagens com a mesma chave, publicadas na
mesma região, são entregues a uma assinatura com ordenação ligada na ordem em que o Pub/Sub as
recebeu.

**Escolha como chave a menor coisa cujos eventos precisam ficar em ordem.** Para status de pedido, é o
cliente ou o pedido, nunca a loja e nunca uma constante: uma chave carrega um fluxo ordenado de
mensagens por vez, e o Google documenta um limite de 1 MB por segundo por chave de ordenação. Um tópico
com chave constante é um tópico de uma faixa só.

## Ordenação nas duas pontas

Um tópico para status de pedido, e duas assinaturas nele, uma com ordenação e uma sem:

```
ana@laptop:~/gcp$ gcloud pubsub topics create order-status
Created topic [projects/planner-dev/topics/order-status].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create status-ordered --topic=order-status --enable-message-ordering
Created subscription [projects/planner-dev/subscriptions/status-ordered].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create status-any --topic=order-status
Created subscription [projects/planner-dev/subscriptions/status-any].
```

Salve o publicador como `~/gcp/ordered.py`:

```schooling-example
{"language": "python", "file": "ordered.py", "parts": [{"code": "from google.cloud import pubsub_v1\n\noptions = pubsub_v1.types.PublisherOptions(enable_message_ordering=True)\npublisher = pubsub_v1.PublisherClient(publisher_options=options)\ntopic = publisher.topic_path('planner-dev', 'order-status')\n\n", "note": "**A ordenação é ligada no publicador além da assinatura.** Com a opção, o cliente manda as mensagens de uma chave um lote por vez, em ordem, e nunca dois lotes da mesma chave ao mesmo tempo."}, {"code": "EVENTS = [\n    ('o-101', 'c-17', 'placed'), ('o-102', 'c-02', 'placed'),\n    ('o-101', 'c-17', 'packed'), ('o-103', 'c-05', 'placed'),\n    ('o-102', 'c-02', 'packed'), ('o-101', 'c-17', 'delivered'),\n    ('o-103', 'c-05', 'cancelled'), ('o-102', 'c-02', 'delivered'),\n]\n\n", "note": "Oito mudanças de status de três pedidos, intercaladas como estariam numa noite movimentada. Um pedido é feito, separado e entregue, ou cancelado."}, {"code": "futures = [publisher.publish(topic, f'{order} {status}'.encode(), ordering_key=customer)\n           for order, customer, status in EVENTS]\nfor (order, customer, status), future in zip(EVENTS, futures):\n    print(f'id {future.result():>3}  key {customer}  {order} {status}')\n", "note": "**A chave de ordenação é o cliente**, então os eventos de cada cliente mantêm a ordem e os de clientes diferentes ficam livres uns dos outros."}]}
```

```
ana@laptop:~/gcp$ python3 ordered.py
id  21  key c-17  o-101 placed
id  18  key c-02  o-102 placed
id  22  key c-17  o-101 packed
id  23  key c-05  o-103 placed
id  19  key c-02  o-102 packed
id  24  key c-17  o-101 delivered
id  25  key c-05  o-103 cancelled
id  20  key c-02  o-102 delivered
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull status-any --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.orderingKey:label=KEY,message.data.decode(base64).decode(utf-8):label=DATA)'
ID  KEY   DATA
18  c-02  o-102 placed
19  c-02  o-102 packed
20  c-02  o-102 delivered
23  c-05  o-103 placed
25  c-05  o-103 cancelled
21  c-17  o-101 placed
22  c-17  o-101 packed
24  c-17  o-101 delivered
```

**Os ids mostram o publicador trabalhando.** O programa publicou na ordem intercalada de `EVENTS`, e a
biblioteca mandou um lote por chave, então os ids foram dados conforme os lotes chegaram: 18 a 20 para
`c-02`, 21, 22 e 24 para `c-17`, 23 e 25 para `c-05`. Entre chaves eles não querem dizer nada, e dentro
de cada chave sobem na ordem escrita. O pull de
`status-any`, a assinatura sem ordenação, por acaso também voltou em ordem de chave. Isso é hábito deste
emulador e não promessa: a assinatura não pediu ordem, e o serviço de verdade intercala um pull desses
do jeito que as máquinas dele terminarem.

**A ordenação precisa da opção no publicador além da assinatura.** Sem ela, a biblioteca recusa uma
chave de ordenação antes de mandar qualquer coisa:

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import pubsub_v1; p = pubsub_v1.PublisherClient(); p.publish(p.topic_path('planner-dev', 'order-status'), b'x', ordering_key='c-17')" 2>&1 | tail -1
ValueError: Cannot publish a message with an ordering key when message ordering is not enabled.
```

## Quando uma mensagem recebe nack

**A ordem importa mais quando algo falha**, e é aí que o emulador se separa do serviço. Salve isto como
`~/gcp/redeliver.py`. Ele lê a assinatura com ordenação, pega uma mensagem, a devolve com um nack e
depois lê tudo o que sobrou:

```schooling-example
{"language": "python", "file": "redeliver.py", "parts": [{"code": "import sys\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\n\n\ndef pull(n):\n    return subscriber.pull(subscription=path, max_messages=n, timeout=5).received_messages\n\n\n", "note": "`pull` é a forma unária, uma requisição e uma resposta, que é o que o `gcloud` usa. Ela deixa fácil imprimir a ordem de entrega."}, {"code": "first = pull(1)[0]\nprint(f'pulled {first.message.ordering_key}  {first.message.data.decode()}, nacked it')\nsubscriber.modify_ack_deadline(subscription=path, ack_ids=[first.ack_id], ack_deadline_seconds=0)\n\n", "note": "**Um nack é um prazo de ack igual a zero**: devolve a mensagem na hora em vez de esperar o prazo acabar. É o que um consumidor faz quando falha numa mensagem."}, {"code": "for r in pull(20):\n    print(f'then   {r.message.ordering_key}  {r.message.data.decode()}')\n", "note": "Depois ele puxa tudo o que sobrou, a mensagem com nack incluída, e imprime a ordem em que veio."}]}
```

`status-ordered` ainda tem as oito mensagens, já que só `status-any` foi lida:

```
ana@laptop:~/gcp$ python3 redeliver.py status-ordered
pulled c-02  o-102 placed, nacked it
then   c-02  o-102 packed
then   c-05  o-103 placed
then   c-17  o-101 placed
then   c-17  o-101 packed
then   c-02  o-102 delivered
then   c-02  o-102 placed
then   c-05  o-103 cancelled
then   c-17  o-101 delivered
```

**O emulador entregou `o-102 packed` e `o-102 delivered` antes de `o-102 placed`**, na assinatura que
pediu ordem. Ele aceitou o nack, pôs `placed` de volta atrás do resto e seguiu entregando as mensagens
seguintes da chave como se a anterior estivesse resolvida. Um consumidor testado contra ele nunca
veria o que o serviço de verdade faz aqui. O Google documenta isso, e não foi rodado: quando uma mensagem com chave de
ordenação recebe nack ou tem o prazo esgotado, o Pub/Sub a entrega de novo **junto com todas as
mensagens seguintes daquela chave**, inclusive as já confirmadas, para que o leitor as encontre de novo
em ordem. O preço da ordem, então, são duplicados, e um consumidor de uma assinatura ordenada precisa
ser idempotente, que é a aula 20.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma chave de ordenação, c-02, cuja primeira mensagem o-102 placed recebe nack. Linha de cima, o que o Google documenta e não foi rodado aqui: o-102 placed é entregue de novo, depois o-102 packed e o-102 delivered, e a ordem se mantém. Linha de baixo, o que o emulador fez em redeliver.py: o-102 packed e o-102 delivered vieram em seguida, antes de o pedido ser feito, e o-102 placed veio por último.\" data-fig=\"l19-order\"><text x=\"20.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o Google documenta</text><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não rodado aqui</text><rect x=\"175.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"234.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"234.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nack</text><rect x=\"311.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"370.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entregue de novo</text><line x1=\"294.0\" y1=\"62.0\" x2=\"303.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"309.0,62.0 303.0,65.0 303.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"447.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 packed</text><line x1=\"430.0\" y1=\"62.0\" x2=\"439.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,62.0 439.0,65.0 439.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"583.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 delivered</text><line x1=\"566.0\" y1=\"62.0\" x2=\"575.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"581.0,62.0 575.0,65.0 575.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"20.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o emulador</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">como rodou, redeliver.py</text><rect x=\"175.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"234.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"234.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nack</text><rect x=\"311.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 packed</text><text x=\"370.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">antes de ser feito</text><line x1=\"294.0\" y1=\"162.0\" x2=\"303.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"309.0,162.0 303.0,165.0 303.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"447.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 delivered</text><text x=\"506.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">antes de ser feito</text><line x1=\"430.0\" y1=\"162.0\" x2=\"439.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,162.0 439.0,165.0 439.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"583.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"642.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">por último</text><line x1=\"566.0\" y1=\"162.0\" x2=\"575.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"581.0,162.0 575.0,165.0 575.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon></svg>", "caption": "As três mensagens de uma chave depois do nack na primeira: a ordem que o serviço documenta, e a ordem que o emulador entregou."}
```

## O que a ordenação não sobrevive

**Uma falha do publicador para a chave, de propósito.** Se a publicação de uma mensagem com chave de
ordenação falha depois das novas tentativas da biblioteca, o cliente Python pausa aquela chave: toda
publicação seguinte com ela falha na hora, para que nada passe na frente da mensagem que não foi. O
programa decide o que fazer com a falha e depois chama `publisher.resume_publish(topic, key)`. As outras
chaves seguem. Nada disso foi rodado, porque o emulador nunca falha uma publicação.

**A ordenação é por região e por assinatura.** Dois publicadores em duas regiões escrevendo a mesma
chave não ficam ordenados entre si; um tópico de dead letter, na próxima seção, tira uma mensagem da
sequência da chave para sempre. E uma assinatura ordenada entrega as mensagens de uma chave um lote por
vez, então uma chave com consumidor lento segura só as próprias mensagens, enquanto uma chave com uma
única mensagem lenta segura tudo o que vem depois dela. Se uma pergunta precisa da ordem dos eventos
entre chaves, a assinatura não responde; os eventos precisam trazer um timestamp próprio, e a aula 22 é
sobre ordenar por ele quando alguns chegam atrasados.
