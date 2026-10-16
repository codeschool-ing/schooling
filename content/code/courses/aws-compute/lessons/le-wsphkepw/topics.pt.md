---
title: "Tópicos: uma mensagem, uma cópia para cada assinante"
version: 1
---

Quando um pedido é pago, billing precisa saber, e shipping também. O primeiro desenho que vem à
cabeça é uma fila que os dois leem. **Uma fila entrega cada mensagem a um consumidor**, então
billing e shipping dividiriam os pedidos entre si, cada um vendo cerca de metade. O que eles
precisam é de um **tópico**: o SNS pega uma mensagem publicada e entrega uma cópia a cada
assinatura, e cada assinante pode ter uma fila própria, lida no seu próprio ritmo. Essa forma se
chama fan-out.

## Duas filas atrás de um tópico

A Ana cria o tópico e assina uma fila para cada time:

```
ana@laptop:~/aws$ TOPIC=$(aws sns create-topic --name orders --query TopicArn --output text); echo "$TOPIC"
arn:aws:sns:sa-east-1:123456789012:orders
ana@laptop:~/aws$ for name in billing shipping; do aws sqs create-queue --queue-name $name --query QueueUrl --output text; aws sns subscribe --topic-arn "$TOPIC" --protocol sqs --notification-endpoint arn:aws:sqs:sa-east-1:123456789012:$name --query SubscriptionArn --output text; done
http://localhost:4567/123456789012/billing
arn:aws:sns:sa-east-1:123456789012:orders:9dc5471f-2567-45f1-ad4e-7df5df16ba5b
http://localhost:4567/123456789012/shipping
arn:aws:sns:sa-east-1:123456789012:orders:69e63d69-7e71-462f-ae44-4f8e86a2cb48
```

**Na AWS cada fila também precisa de uma política que deixe o tópico mandar para ela**, uma queue
policy do SQS cujo principal é `sns.amazonaws.com` e cuja condição cita o ARN do tópico; sem ela o
SNS não entrega nada e a assinatura parece certa. O moto não verifica queue policy nenhuma, então o
laboratório funciona sem ela. A política é uma resource policy do tipo que a aula 7 de
`aws-foundations` lê.

## Um filtro por assinatura

Shipping só se importa com bens físicos. Em vez de receber todo pedido e jogar metade fora, a
assinatura dele ganha uma **filter policy**, e o SNS barra o que não casa antes da entrega. A mesma
assinatura passa para **entrega raw**, então a fila recebe a própria mensagem em vez do envelope do
SNS em volta dela:

```
ana@laptop:~/aws$ SHIP=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" --query "Subscriptions[?Endpoint==\`arn:aws:sqs:sa-east-1:123456789012:shipping\`].SubscriptionArn" --output text)
ana@laptop:~/aws$ aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name FilterPolicy --attribute-value '{"kind": ["physical"]}'
ana@laptop:~/aws$ aws sns set-subscription-attributes --subscription-arn "$SHIP" --attribute-name RawMessageDelivery --attribute-value true
```

Dois pedidos são pagos, um físico e um digital:

```
ana@laptop:~/aws$ aws sns publish --topic-arn "$TOPIC" --message "order 42 paid" --message-attributes '{"kind": {"DataType": "String", "StringValue": "physical"}}' --query MessageId --output text
4c3efa1a-0327-421b-a53a-a050642070e2
ana@laptop:~/aws$ aws sns publish --topic-arn "$TOPIC" --message "order 43 paid" --message-attributes '{"kind": {"DataType": "String", "StringValue": "digital"}}' --query MessageId --output text
1ecaf880-c606-4620-b2ba-59da62f81741
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/billing" --max-number-of-messages 10 | jq -c ".Messages[].Body | fromjson | {Type, Message, kind: .MessageAttributes.kind.Value}"
{"Type":"Notification","Message":"order 42 paid","kind":"physical"}
{"Type":"Notification","Message":"order 43 paid","kind":"digital"}
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/shipping" --max-number-of-messages 10 --query "Messages[].Body" --output text
order 42 paid
```

**Billing recebeu os dois, shipping recebeu um, e chegaram em formatos diferentes.** As mensagens de
billing são o envelope JSON do SNS, com `Type`, a `Message` e os atributos; um consumidor lê a
`Message` de dentro dele, e o `jq` acima fez exatamente isso. As de shipping chegaram raw, como o
texto publicado e nada mais, e o pedido digital nem chegou à fila. O moto aplicou o filtro como a
AWS aplica.

Uma filter policy lê os atributos da mensagem por padrão. Desde 2022 ela também pode ler o corpo de
uma mensagem JSON, com o atributo de assinatura `FilterPolicyScope` valendo `MessageBody`. De um
jeito ou de outro, a comparação acontece antes da entrega, então uma mensagem que não casa nenhum
filtro não custa entrega e não acorda consumidor.

## O que um tópico não faz

**Um tópico não guarda nada.** Uma mensagem publicada enquanto o endpoint de uma assinatura não
consegue recebê-la é tentada de novo num cronograma e depois descartada, a menos que essa assinatura
tenha uma dead-letter queue própria; uma mensagem publicada antes de uma assinatura existir nunca é
entregue a ela. Esse é o outro motivo da fila atrás de cada assinatura: a fila guarda a mensagem até
o consumidor estar pronto, por até catorze dias, e o tópico só precisa chegar à fila.

A ordem é outra coisa que um tópico standard também não guarda. Um **tópico FIFO do SNS**, cujo nome
termina em `.fifo`, entrega a filas FIFO do SQS em ordem e descarta duplicatas, com os mesmos group
e deduplication ids da fila FIFO da última seção desta aula.

O SNS também entrega a outros tipos de endpoint: uma função Lambda, um endereço HTTPS, um endereço
de e-mail, um número de telefone. Com o SQS atrás, o trabalho do tópico é estreito e confiável, e
cada time mantém as próprias novas tentativas, a própria dead-letter queue e o próprio ritmo.
