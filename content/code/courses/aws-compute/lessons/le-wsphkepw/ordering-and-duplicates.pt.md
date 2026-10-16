---
title: Ordem, duplicatas e o consumidor que não se importa
version: 1
---

A suposição confortável é que uma mensagem é entregue uma vez e na ordem em que foi mandada. **Uma
fila standard do SQS não promete nenhuma das duas.** Ela entrega toda mensagem pelo menos uma vez, e
de vez em quando duas, e mais ou menos na ordem de envio, mas não exatamente. A primeira seção
mostrou uma causa da segunda entrega, um consumidor que não apaga a tempo. Outra está dentro do SQS,
que guarda cada mensagem em vários servidores e pode, raramente, entregar uma cópia que um deles
ainda tem. Em troca, uma fila standard aguenta uma vazão quase ilimitada. As duas promessas podem
ser compradas de volta, com uma fila FIFO, e as duas podem deixar de importar, com um consumidor
que faz o mesmo trabalho uma vez só, chegue o que chegar.

## FIFO: ordem por grupo, e duplicatas descartadas

O nome de uma fila FIFO termina em `.fifo`, e toda mensagem leva dois ids a mais. O **message group
id** diz quais mensagens precisam ficar em ordem umas em relação às outras; o **deduplication id**
diz quais envios são a mesma mensagem:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders.fifo --attributes FifoQueue=true --query QueueUrl --output text
http://localhost:4567/123456789012/orders.fifo
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text
91989792316542591463
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-paid --message-body paid --query SequenceNumber --output text
72866415318839542837
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-42 --message-deduplication-id 42-shipped --message-body shipped --query SequenceNumber --output text
63939971528844063907
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-group-id order-43 --message-deduplication-id 43-paid --message-body paid --query SequenceNumber --output text
04655964262658135292
```

O segundo envio repetiu `42-paid`, uma nova tentativa de um envio cuja resposta se perdeu, e os dois
envios foram aceitos. Depois, um receive:

```
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/orders.fifo" --max-number-of-messages 10 --attribute-names MessageGroupId --query "Messages[].[Attributes.MessageGroupId, Body]" --output text
order-42	paid
order-42	shipped
order-43	paid
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/orders.fifo" --message-body paid

aws: [ERROR]: An error occurred (MissingParameter) when calling the SendMessage operation: The request must contain the parameter MessageGroupId.
```

**Três mensagens, não quatro**: o `42-paid` repetido foi descartado, porque uma fila FIFO lembra um
deduplication id por cinco minutos. Dentro do grupo `order-42`, `paid` vem antes de `shipped`, e
enquanto uma mensagem de um grupo está sendo processada a fila não entrega nenhuma mensagem
posterior desse grupo, então dois consumidores nunca tratam os eventos do mesmo pedido fora de
ordem. Os grupos são independentes entre si, e é daí que vem o paralelismo de uma fila FIFO: um
grupo por pedido, por cliente ou por conta, nunca um grupo para tudo. Uma fila FIFO sem group id é
recusada, como o último comando mostra. Com `ContentBasedDeduplication` ligado, a fila gera o
deduplication id ela mesma a partir de um hash do corpo, e dois corpos idênticos dentro de cinco
minutos contam como um.

A garantia tem bordas. A deduplicação cobre cinco minutos e uma fila; um produtor que tenta de novo
depois de seis minutos, ou um consumidor que falha depois de fazer o trabalho e antes de apagar,
ainda produz uma segunda entrega. **O FIFO estreita as duplicatas; ele não as abole.**

## O consumidor que não se importa

Então a resposta confiável está do lado de quem consome: um **consumidor idempotente**, um para o
qual tratar a mesma mensagem duas vezes tem o efeito de tratá-la uma vez. O jeito comum é o que a
aula 20 usou para novas tentativas, uma chave de idempotência levada na mensagem e um registro das
chaves já feitas. Salve isto como `~/aws/consumer.py`:

```schooling-example
{"language": "python", "file": "consumer.py", "parts": [{"code": "import json\nimport sqlite3\n\nimport boto3\n\nQUEUE = \"https://sqs.sa-east-1.amazonaws.com/123456789012/payments\"\nsqs = boto3.client(\"sqs\")\n", "note": "O boto3 é o SDK da AWS para Python, e já está em `~/aws/venv` porque o moto precisa dele. Como a linha de comando, ele lê `AWS_ENDPOINT_URL`, as chaves e a região do ambiente, então este arquivo não nomeia endpoint nem guarda chave."}, {"code": "db = sqlite3.connect(\"done.db\")\ndb.execute(\"CREATE TABLE IF NOT EXISTS done (key TEXT PRIMARY KEY)\")\n\n\ndef charge(order):\n    print(f\"charging order {order['id']}: {order['total']} cents\")\n\n\n", "note": "O registro do que já foi feito, num arquivo SQLite. A chave primária é o que faz funcionar: uma segunda inserção da mesma chave falha, e quem verifica é o banco, não o programa. `charge` está no lugar da chamada a um provedor de pagamento."}, {"code": "while True:\n    reply = sqs.receive_message(QueueUrl=QUEUE, MaxNumberOfMessages=10, WaitTimeSeconds=1)\n    messages = reply.get(\"Messages\", [])\n    if not messages:\n        break\n", "note": "Até dez mensagens por requisição, esperando até um segundo por elas. Um consumidor real espera 20 segundos e nunca para; este para quando a fila está vazia, para que uma execução no laboratório termine."}, {"code": "    for m in messages:\n        order = json.loads(m[\"Body\"])\n        try:\n            with db:\n                db.execute(\"INSERT INTO done VALUES (?)\", (order[\"key\"],))\n                charge(order)\n        except sqlite3.IntegrityError:\n            print(f\"skipping {order['key']}: already done\")\n        sqs.delete_message(QueueUrl=QUEUE, ReceiptHandle=m[\"ReceiptHandle\"])\n", "note": "A chave entra primeiro e o trabalho acontece dentro da mesma transação, então uma cobrança que levanta erro desfaz a chave e a mensagem volta. Uma chave que já está lá quer dizer que o trabalho foi feito: pule, e apague a mensagem de qualquer jeito."}]}
```

Três pagamentos chegam numa fila standard, um deles duas vezes:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name payments --query QueueUrl --output text
http://localhost:4567/123456789012/payments
ana@laptop:~/aws$ for o in 42 42 43; do aws sqs send-message --queue-url "$Q/payments" --message-body "{\"key\": \"charge-$o\", \"id\": \"$o\", \"total\": 1500}" --query MessageId --output text; done
4e73cb0a-def5-4a73-8dd9-2aea1c0779a2
adfadf9b-6e5c-44c6-8507-55a645ec9754
272f3aca-2e6d-4ac3-bd2b-62cb547de84f
```

O consumidor esvazia a fila:

```
ana@laptop:~/aws$ python3 consumer.py
charging order 42: 1500 cents
skipping charge-42: already done
charging order 43: 1500 cents
```

Ele cobrou o pedido 42 uma vez, pulou a cópia e cobrou o 43. Mais tarde o mesmo pagamento chega de
novo, como chegaria depois de uma nova tentativa do produtor:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/payments" --message-body '{"key": "charge-42", "id": "42", "total": 1500}' --query MessageId --output text
bb2eeeaa-6a24-4784-98b0-928a401f7e8b
ana@laptop:~/aws$ python3 consumer.py
skipping charge-42: already done
```

Ele também foi pulado, porque o registro de `charge-42` está no `done.db`, e não na memória da fila.
**A verificação é uma chave única num armazenamento que dura mais que a mensagem.** Em produção esse
armazenamento é um banco que os consumidores compartilham, muitas vezes uma tabela do DynamoDB
escrita com a condição de que a chave ainda não exista, para que dois consumidores com duas cópias
no mesmo momento não consigam vencer os dois.

## Quanto custa

A tabela, como publicada em 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 14,18p
Queues, topics and buses
  SQS standard                                       0.4  per million
  SQS FIFO                                           0.5  per million
  SNS publish, after the first million               0.5  per million
  EventBridge custom event                             1  per million
```

Uma mensagem que é mandada, recebida e apagada custa três requisições do SQS. Com 10 milhões de
pedidos por mês, são 30 milhões de requisições: 30 × 0,4 = 12,00 USD numa fila standard e
30 × 0,5 = 15,00 USD numa fila FIFO. Receives vazios custam o mesmo que os cheios, e é aí que o long
polling se paga: um consumidor perguntando dez vezes por segundo a uma fila ociosa faz
10 × 2.592.000 = 25.920.000 requisições num mês de 30 dias, 10,37 USD por nada, contra
2.592.000 / 20 = 129.600 com uma espera de 20 segundos, 0,05 USD.

Publicar os mesmos 10 milhões de pedidos num tópico do SNS custa 9 × 0,5 = 4,50 USD, já que o
primeiro milhão é gratuito, e a AWS não cobra pelas entregas do SNS a filas do SQS. Pô-los num bus
do EventBridge como eventos custom custa 10 × 1 = 10,00 USD. **Cada requisição é contada em passos
de 64 KB** nos três serviços, então uma mensagem de 100 KB é cobrada como duas.

## Qual fila, então

Uma fila standard, com um consumidor idempotente, é o padrão: é mais barata, escala sem pensar em
grupos, e o consumidor precisa ser idempotente de qualquer jeito. **Uma fila FIFO é para o caso em
que a ordem dentro de uma chave é o requisito**, como os débitos e créditos de uma conta ou as
mudanças de estado de um pedido, e então o group id é a decisão que importa, porque ele decide ao
mesmo tempo a ordem e o paralelismo.
