---
title: "Pollers: lotes do SQS e shards de stream"
version: 1
---

Com uma fila ou um stream, nada chama a função; o Lambda lê a origem por ela. **A unidade de
trabalho passa a ser um lote, e a pergunta difícil é o que um registro ruim faz com o resto do seu
lote.** Para o SQS a resposta pode ser "nada", se o handler disser quais mensagens falharam. Para um
stream é "tudo o que vem atrás dele", a menos que o mapeamento seja instruído a desistir. As duas
respostas são configurações do mapeamento de origem de eventos, e o moto as guarda.

## O mapeamento de uma fila

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders --query QueueUrl
"http://localhost:4567/123456789012/orders"
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name orders --event-source-arn arn:aws:sqs:sa-east-1:123456789012:orders --batch-size 10 --maximum-batching-window-in-seconds 5 --function-response-types ReportBatchItemFailures --query "{State:State,BatchSize:BatchSize,Window:MaximumBatchingWindowInSeconds,Responses:FunctionResponseTypes}"
{
    "State": "Enabled",
    "BatchSize": 10,
    "Window": 5,
    "Responses": [
        "ReportBatchItemFailures"
    ]
}
```

Três configurações, cada uma uma troca. **`--batch-size 10`** é o máximo de mensagens que uma
invocação recebe, e menos invocações com mais mensagens custam menos pedidos.
**`--maximum-batching-window-in-seconds 5`** deixa o poller esperar até cinco segundos para encher um
lote, o que economiza invocações quando o tráfego é fraco e acrescenta até cinco segundos de atraso
a cada mensagem; sem ela, um lote sai assim que houver algo para mandar. E
**`ReportBatchItemFailures`** muda o que a resposta da função significa, que é o resto desta seção.

O moto registra o mapeamento e não consulta nada, então o que vem a seguir rodou no emulador, com um
evento no formato que a AWS documenta para o SQS. Ele foi escrito à mão para esta aula, três
mensagens das quais a segunda não é um pedido. Salve como `~/aws/sqs-event.json`:

```json
{
  "Records": [
    {
      "messageId": "m-1",
      "receiptHandle": "rh-1",
      "body": "{\"id\": \"A-1\", \"total\": 1299.9}",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    },
    {
      "messageId": "m-2",
      "receiptHandle": "rh-2",
      "body": "not an order",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    },
    {
      "messageId": "m-3",
      "receiptHandle": "rh-3",
      "body": "{\"id\": \"A-3\", \"total\": 45.0}",
      "attributes": {
        "ApproximateReceiveCount": "1"
      },
      "messageAttributes": {},
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:sa-east-1:123456789012:orders",
      "awsRegion": "sa-east-1"
    }
  ]
}
```

## Uma mensagem ruim num lote

Por padrão, um lote dá certo ou falha inteiro. Se o handler levanta uma exceção, toda mensagem do lote
volta a ficar visível na fila quando o seu visibility timeout acaba, e o lote seguinte entrega todas
de novo, inclusive as que estavam boas. **A cada nova tentativa, as mensagens boas são processadas
duas vezes e a ruim continua falhando**, até a política de redrive da fila mandá-la para uma
dead-letter queue depois de tantos recebimentos, que a aula 21 configura.

A resposta de lote parcial evita as duas coisas. Este handler trata cada mensagem por si e responde
com as que não conseguiu fazer. Salve como `~/aws/orders/orders.py`:

```schooling-example
{"language": "python", "file": "orders.py", "parts": [{"code": "import json\n\n\ndef handler(event, context):\n    failures = []\n", "note": "Um lote do SQS é um evento. `failures` reúne as mensagens que esta invocação não conseguiu tratar, e mais nada."}, {"code": "    for record in event['Records']:\n        try:\n            order = json.loads(record['body'])\n            print(f\"order {order['id']}: {order['total']}\")\n", "note": "Cada registro é uma mensagem, com o texto em `body`. O trabalho de uma mensagem fica dentro do seu próprio `try`, então uma mensagem ruim não derruba as outras junto."}, {"code": "        except (ValueError, KeyError) as err:\n            print(f\"cannot read {record['messageId']}: {err!r}\")\n            failures.append({'itemIdentifier': record['messageId']})\n", "note": "Uma mensagem que falha é identificada pelo seu `messageId`. Levantar uma exceção aqui falharia o lote inteiro, e todas as mensagens dele voltariam."}, {"code": "    return {'batchItemFailures': failures}\n", "note": "**A resposta de lote parcial.** Com `ReportBatchItemFailures` no mapeamento, o Lambda apaga toda mensagem que não está nesta lista e deixa as listadas na fila. Uma lista vazia quer dizer que o lote inteiro deu certo."}]}
```

```
ana@laptop:~/aws$ docker run --rm -d --name orders -p 9000:8080 -v "$PWD/orders":/var/task:ro public.ecr.aws/lambda/python:3.12 orders.handler
d7028bb9fe9c27ad9a049a055504fa5128a9380959d5d2be507c1bfb15502aef
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d @sqs-event.json; echo
{"batchItemFailures": [{"itemIdentifier": "m-2"}]}
ana@laptop:~/aws$ docker logs orders 2>&1 | grep -E '^(order|cannot)'
order A-1: 1299.9
cannot read m-2: JSONDecodeError('Expecting value: line 1 column 1 (char 0)')
order A-3: 45.0
ana@laptop:~/aws$ docker stop orders
orders
```

`A-1` e `A-3` foram tratados, `m-2` não pôde ser lida, e a resposta nomeia só `m-2`. Na AWS, com
`ReportBatchItemFailures` no mapeamento, o Lambda agora apaga as duas mensagens boas da fila e deixa
`m-2` voltar sozinha. **Sem essa configuração a mesma resposta significa sucesso para as três**, e
`m-2` é apagada sem ser lida: a resposta só é lida quando o mapeamento pede. Levantar uma exceção
continua falhando o lote inteiro, de um jeito ou de outro.

## Streams: o shard é uma fila indiana

O DynamoDB Streams e o Kinesis não são filas. Um stream é dividido em **shards**, os registros de um
shard ficam em ordem, e o mapeamento lê cada shard com uma posição nele, avançando só quando um lote
dá certo. Crie uma tabela cujas mudanças vão para um stream, e um mapeamento para ele:

```
ana@laptop:~/aws$ aws dynamodb create-table --table-name carts --attribute-definitions AttributeName=id,AttributeType=S --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --query TableDescription.LatestStreamArn
"arn:aws:dynamodb:sa-east-1:123456789012:table/carts/stream/2026-10-16T16:50:22.203886"
ana@laptop:~/aws$ STREAM=$(aws dynamodb describe-table --table-name carts --query Table.LatestStreamArn --output text)
ana@laptop:~/aws$ aws lambda create-event-source-mapping --function-name orders --event-source-arn "$STREAM" --starting-position TRIM_HORIZON --batch-size 100 --bisect-batch-on-function-error --maximum-retry-attempts 2 --query "{State:State,Start:StartingPosition,Bisect:BisectBatchOnFunctionError,Retries:MaximumRetryAttempts}"
{
    "State": "Enabled",
    "Start": "TRIM_HORIZON",
    "Bisect": true,
    "Retries": 2
}
ana@laptop:~/aws$ aws lambda list-event-source-mappings --function-name orders --query "EventSourceMappings[].[EventSourceArn,State,BatchSize]" --output text
arn:aws:sqs:sa-east-1:123456789012:orders	Enabled	10
arn:aws:dynamodb:sa-east-1:123456789012:table/carts/stream/2026-10-16T16:50:22.203886	Enabled	100
```

**`--starting-position TRIM_HORIZON`** começa no registro mais antigo que o stream ainda guarda, onde
`LATEST` começaria no próximo a ser escrito. Um stream do DynamoDB guarda os registros por 24 horas;
um mapeamento que fica mais atrasado que isso perde o que expirou.

A diferença em relação ao SQS é o que uma falha faz. **Um lote que falha é tentado de novo, e nada
atrás dele naquele shard é lido até ele dar certo**, porque pulá-lo quebraria a ordem que o stream
existe para manter. Um registro que a função não consegue tratar pararia o seu shard por um dia, e a
idade do registro é o alarme que avisa. Três configurações limitam isso:

- **`--maximum-retry-attempts 2`** desiste de um lote depois de duas novas tentativas;
- **`--bisect-batch-on-function-error`** divide um lote que falha em dois e tenta as metades, então o
  registro ruim acaba sozinho e os bons em volta dele passam;
- um **destino em caso de falha**, uma fila SQS ou um tópico SNS, recebe uma descrição dos registros
  abandonados, para que possam ser examinados em vez de perdidos.

O moto aceitou as duas primeiras e não executa nenhuma, já que não lê stream nenhum para uma função.
O comportamento acima é o da AWS, pela documentação dela, e não foi executado aqui. O último comando
mostra a função com os seus dois mapeamentos, um por origem.

## O que o lote cobra do handler

Todo poller entrega uma lista. O handler é um laço, e o tratamento de erros do laço é o projeto:
**capture por registro, informe por registro**, como o `orders.py` faz, para o SQS e também para os
streams, onde a mesma resposta `batchItemFailures` diz ao mapeamento o número de sequência de onde
retomar. Um handler que processa um lote com um único `try` em volta do laço inteiro escolheu, sem
dizer, que um registro ruim falha todos os registros junto com ele.
