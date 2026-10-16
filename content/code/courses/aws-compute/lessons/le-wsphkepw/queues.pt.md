---
title: "Filas: receber, ocultar, apagar"
version: 1
---

É fácil imaginar uma fila como um cano: uma mensagem entra por uma ponta e sai pela outra. A
imagem perde o passo que importa. **Receber uma mensagem do SQS não a remove.** Ela fica oculta por
um tempo, o visibility timeout, e o consumidor precisa apagá-la antes de o tempo acabar. Um
consumidor que cai no meio nunca apaga, a mensagem reaparece, e outro consumidor a recebe. Essa
regra é como uma fila sobrevive aos seus consumidores, e também é por isso que toda mensagem pode
chegar mais de uma vez.

## Uma fila com lugar para guardar as falhas

Uma mensagem que falha toda vez que é tentada voltaria, sem isso, durante todo o período de
retenção da fila, quatro dias por padrão. Então a fila de trabalho ganha antes uma **dead-letter
queue**, e uma redrive policy que diz quando desistir. `$Q` poupa digitar o começo do endereço de
cada fila, na forma que a AWS usa, que o moto aceita:

```
ana@laptop:~/aws$ Q=https://sqs.sa-east-1.amazonaws.com/123456789012
ana@laptop:~/aws$ aws sqs create-queue --queue-name work-dlq --query QueueUrl --output text
http://localhost:4567/123456789012/work-dlq
```

Salve os ajustes como `~/aws/attrs.json`. A redrive policy é um documento JSON escrito como string
dentro de JSON, e é por isso que ela leva as próprias aspas escapadas:

```json
{
  "VisibilityTimeout": "3",
  "RedrivePolicy": "{\"deadLetterTargetArn\": \"arn:aws:sqs:sa-east-1:123456789012:work-dlq\", \"maxReceiveCount\": \"3\"}"
}
```

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name work --attributes file://attrs.json --query QueueUrl --output text
http://localhost:4567/123456789012/work
```

O `VisibilityTimeout` é de três segundos para o laboratório andar rápido; o padrão é 30 segundos, e
o valor certo é maior que o tempo mais lento que um consumidor leva para terminar uma mensagem.
**O `maxReceiveCount` é quantos recebimentos uma mensagem ganha** antes de a fila movê-la para a
dead-letter queue em vez de entregá-la de novo.

## O caminho normal: receber, depois apagar

Uma mensagem é recebida com um **receipt handle**, uma string que nomeia este recebimento dela, e o
handle é o que o `delete-message` precisa:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/work" --message-body "order 41" --query MessageId --output text
a836dce7-ac4d-407a-8043-18b2af7ddd87
ana@laptop:~/aws$ RH=$(aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].ReceiptHandle" --output text)
ana@laptop:~/aws$ aws sqs delete-message --queue-url "$Q/work" --receipt-handle "$RH"
ana@laptop:~/aws$ sleep 4; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text
None
```

Depois do delete, esperar mais que o visibility timeout não traz nada de volta: o trabalho está
feito e a mensagem sumiu. O `None` é o jeito da linha de comando de imprimir uma resposta sem
mensagens.

## O caminho que uma falha percorre

Agora uma mensagem que ninguém apaga. Cada volta do laço a recebe, tenta recebê-la de novo na hora,
e espera quatro segundos, mais que o timeout:

```
ana@laptop:~/aws$ aws sqs send-message --queue-url "$Q/work" --message-body "order 42" --query MessageId --output text
4d7ecbb2-3174-4088-9fa3-6a6da1b9a4b6
ana@laptop:~/aws$ for i in 1 2 3 4; do aws sqs receive-message --queue-url "$Q/work" --attribute-names ApproximateReceiveCount --query "Messages[0].[Body, Attributes.ApproximateReceiveCount]" --output text; aws sqs receive-message --queue-url "$Q/work" --query "Messages[0].Body" --output text; sleep 4; done
order 42	1
None
order 42	2
None
order 42	3
None
None
None
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/work-dlq" --query "Messages[0].Body" --output text
order 42
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo da mensagem order 42 na fila work, com visibility timeout de 3 segundos e maxReceiveCount 3. Três vezes um consumidor a recebe, a contagem de recebimentos vai a 1, 2 e 3, e a mensagem fica oculta por 3 segundos; ninguém a apaga, então ela volta a ficar visível. No quarto receive a contagem passaria de 3, e a fila move a mensagem para work-dlq em vez de entregá-la.\"><defs><marker id=\"redrive-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"redrive-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"16\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">fila work</text><path d=\"M16 60 L704 60\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><circle cx=\"40\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"40\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"40\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">contagem 1</text><rect x=\"48\" y=\"28\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"123\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">oculta 3 s</text><circle cx=\"220\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"220\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"220\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">contagem 2</text><rect x=\"228\" y=\"28\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"303\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">oculta 3 s</text><circle cx=\"400\" cy=\"60\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">receive</text><text x=\"400\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">contagem 3</text><rect x=\"408\" y=\"28\" width=\"150\" height=\"20\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"483\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">oculta 3 s</text><circle cx=\"580\" cy=\"60\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"580\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quarto receive</text><path d=\"M580 106 L580 148\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#redrive-a)\"></path><rect x=\"500\" y=\"150\" width=\"160\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"580\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">movida para work-dlq</text><text x=\"220\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ninguém a apagou</text></svg>", "caption": "Uma mensagem recebida não sumiu, só ficou oculta. Cada vez que o visibility timeout acaba sem um delete, ela volta e a contagem sobe; passado o maxReceiveCount a fila desiste dela e a põe de lado."}
```

Leia em pares. O primeiro receive de cada volta pega `order 42` com a contagem, e o segundo não pega
nada, **porque a mensagem está oculta, não sumida**. Depois de três segundos ela volta, e a contagem
subiu. Na quarta volta a contagem passaria do `maxReceiveCount`, então a fila moveu a mensagem para
`work-dlq`, e os dois receives voltaram vazios. O moto fez tudo isso de verdade, com segundos
reais.

A dead-letter queue é um lugar para olhar, não para esquecer. Uma mensagem ali é uma que o sistema
não conseguiu processar, e alguém precisa saber que ela chegou: um alarme no
`ApproximateNumberOfMessagesVisible` da dead-letter queue acima de zero é a resposta comum, que as
aulas 8 a 10 de `aws-operations` constroem com o CloudWatch. Corrigida a causa, a AWS pode devolver
as mensagens à fila de origem com uma tarefa de redrive, `aws sqs start-message-move-task`.

## Consultar sem gastar muito

Todo `receive-message` é uma requisição, e requisições são o que o SQS cobra, inclusive as que
voltam vazias. Um consumidor que pergunta num laço apertado a uma fila ociosa paga por cada `None`.
O **long polling** espera no servidor: com `--wait-time-seconds 20`, ou o atributo da fila
`ReceiveMessageWaitTimeSeconds`, um receive numa fila vazia espera até 20 segundos por uma mensagem
antes de responder. Um consumidor ocioso faz então três requisições por minuto, em vez de uma a cada
volta do laço, e a última seção desta aula faz a conta.

Um consumidor costuma ser uma função Lambda, e não um laço. A aula 15 ligou uma por um event source
mapping, que faz o receive, o long polling e o delete por você, e devolve à fila as mensagens que
falharam uma a uma com `batchItemFailures`. As regras acima continuam sendo as que ele segue.
