---
title: "Amazon States Language: um workflow como documento JSON"
version: 1
---

A orquestração costuma começar como código: uma função que chama um segundo serviço, espera,
chama um terceiro e trata o que dá errado. Funciona até a função precisar esperar mais que o
próprio timeout, ou algo falhar no meio e ninguém saber quais passos já rodaram. **Uma máquina de
estados do Step Functions tira a sequência do seu código e a põe num documento que o serviço roda
por você.** O serviço lembra onde cada execução está, por até um ano, e anota cada passo que deu. O
seu código encolhe para os passos em si.

O documento é escrito na Amazon States Language, ASL para encurtar, e é JSON. Uma rodada dele é uma
**execução**: uma entrada, um caminho pelos estados, uma saída ou um erro.

## Pedindo ao moto que a rode

O moto responde à API do Step Functions de dois jeitos. Por padrão uma execução não faz nada, e o
histórico dela é uma lista fixa de eventos que o moto inventa igual para toda execução. **Peça a
ele que rode as máquinas de estados**, uma vez a cada início do `moto_server`, pelo endereço de
configuração do próprio moto:

```
ana@laptop:~/aws$ curl -s -XPOST localhost:4567/moto-api/config -d '{"stepfunctions": {"execute_state_machine": true}}'; echo
{"batch": {"use_docker": true}, "lambda": {"use_docker": true}}
```

A resposta lista dois outros ajustes e deixa este de fora, o que é uma peculiaridade da resposta do
moto e não uma recusa; as execuções abaixo provam que o ajuste pegou. Com ele ligado, o moto
interpreta o documento e chama o próprio SQS quando uma tarefa manda. Ele roda os estados de
verdade e continua sem aplicar nenhuma política IAM, então a role abaixo nunca é verificada.

## A máquina, estado por estado

Os pedidos da Ana passam por quatro estados. Um pedido grande espera uma janela de cancelamento
antes de o depósito saber dele; um pequeno passa direto. Salve o arquivo como
`~/aws/order.asl.json`:

```schooling-example
{"language": "json", "file": "order.asl.json", "parts": [{"code": "{\n  \"Comment\": \"One order: a cancel window if it is large, then the warehouse queue\",\n  \"StartAt\": \"Check\",\n  \"States\": {\n", "note": "A máquina inteira é um documento JSON. `StartAt` nomeia o primeiro estado e `States` guarda cada estado pelo nome; o nome é como um estado aponta para o próximo."}, {"code": "    \"Check\": {\n      \"Type\": \"Choice\",\n      \"Choices\": [\n        {\"Variable\": \"$.total\", \"NumericGreaterThan\": 1000, \"Next\": \"CancelWindow\"}\n      ],\n      \"Default\": \"Notify\"\n    },\n", "note": "Um `Choice` não faz trabalho: ele lê a entrada e escolhe o próximo estado. As regras são tentadas em ordem; `Default` é para onde vai todo o resto, e um `Choice` sem ele faz a execução falhar numa entrada que nenhuma regra casa."}, {"code": "    \"CancelWindow\": {\n      \"Type\": \"Wait\",\n      \"Seconds\": 2,\n      \"Next\": \"Notify\"\n    },\n", "note": "Um `Wait` segura a execução e não roda nada enquanto espera, então não custa nada por segundo. Dois segundos deixam o laboratório rápido; uma janela de cancelamento real seria de trinta minutos, e `Timestamp` espera até uma data."}, {"code": "    \"Notify\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage\",\n      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/orders\",\n        \"MessageBody.$\": \"$.id\"\n      },\n      \"ResultPath\": \"$.sent\",\n      \"Next\": \"Done\"\n    },\n", "note": "Um `Task` faz o trabalho. Este `Resource` é uma integração de serviço: o Step Functions chama o SQS ele mesmo, sem função no meio. Uma chave terminada em `.$` pega o valor da entrada, e `ResultPath` põe a resposta do SQS ao lado da entrada em vez de substituí-la."}, {"code": "    \"Done\": {\"Type\": \"Succeed\"}\n  }\n}\n", "note": "`Succeed` encerra a execução com a entrada que recebeu como saída. O oposto, `Fail`, encerra com um nome de erro e uma causa, e a seção sobre erros usa um."}]}
```

Há oito tipos de estado e este arquivo usa quatro. Os outros quatro são `Pass`, que só molda dados,
`Fail`, `Parallel` e `Map`, e o fim desta seção roda os dois últimos. **Todo estado que não é fim
nomeia o seu `Next`**, então o documento é um grafo que dá para ler, e o console do Step Functions o
desenha como um.

A máquina de estados precisa de uma role que o Step Functions possa assumir, e de uma fila para o
`Notify` mandar:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name orders --query QueueUrl --output text
http://localhost:4567/123456789012/orders
ana@laptop:~/aws$ aws iam create-role --role-name orders-sfn --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "states.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/orders-sfn
ana@laptop:~/aws$ ROLE=arn:aws:iam::123456789012:role/orders-sfn
ana@laptop:~/aws$ SM=$(aws stepfunctions create-state-machine --name orders --definition file://order.asl.json --role-arn "$ROLE" --query stateMachineArn --output text); echo "$SM"
arn:aws:states:sa-east-1:123456789012:stateMachine:orders
```

## Duas execuções, dois caminhos

Primeiro um pedido grande. `--name` dá à execução um nome próprio, que na AWS precisa ser único
dentro da máquina de estados por 90 dias. O ARN de uma execução é o da máquina de estados com
`execution` no lugar de `stateMachine` e o nome no fim:

```
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SM" --name order-42 --input '{"id": "42", "total": 1500}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:orders:order-42
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query status
"RUNNING"
ana@laptop:~/aws$ sleep 3
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query "{status: status, output: output}"
{
    "status": "SUCCEEDED",
    "output": "{\"id\": \"42\", \"total\": 1500, \"sent\": {\"MD5OfMessageBody\": \"a1d0c6e83f027327d8461063f4ac58a6\", \"MessageId\": \"d655fee0-5aae-463a-9a1e-5630782a1b62\"}}"
}
```

**A execução ainda estava `RUNNING` quando a linha de comando voltou.** O `start-execution` volta
na hora, e o trabalho segue sem quem chamou: dois segundos de `Wait`, depois a tarefa. A saída é a
entrada com a resposta do SQS em `$.sent`, porque o `ResultPath` a pôs ali. O histórico diz por
quais estados ela passou, e a fila tem a mensagem:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-42" --query "events[].[id, type]" --output text
1	ExecutionStarted
2	ChoiceStateEntered
3	ChoiceStateExited
4	WaitStateEntered
5	WaitStateExited
6	TaskStateEntered
7	TaskScheduled
8	TaskStarted
9	TaskSucceeded
10	TaskStateExited
11	SucceedStateEntered
12	SucceedStateExited
13	ExecutionSucceeded
ana@laptop:~/aws$ aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/orders --query "Messages[0].Body" --output text
42
```

Um pedido pequeno vai pelo outro ramo. O histórico dele não tem `Wait` nenhum:

```
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SM" --name order-43 --input '{"id": "43", "total": 300}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:orders:order-43
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-43" --query "events[].type" --output text
ExecutionStarted	ChoiceStateEntered	ChoiceStateExited	TaskStateEntered	TaskScheduled	TaskStarted	TaskSucceeded	TaskStateExited	SucceedStateEntered	SucceedStateExited	ExecutionSucceeded
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A máquina de estados orders como caixas: Check, um Choice, leva a CancelWindow, um Wait de dois segundos, quando o total passa de 1000, e senão, pelo Default, direto a Notify, um Task que manda para a fila do SQS. Notify leva a Done. A execução order-42, total 1500, foi pelo caminho de cima em 13 eventos; a order-43, total 300, foi pelo de baixo em 11 eventos, sem Wait.\"><defs><marker id=\"sf-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"88\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"75.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Check</text><text x=\"75.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Choice</text><rect x=\"200\" y=\"20\" width=\"150\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"275.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">CancelWindow</text><text x=\"275.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wait</text><text x=\"275.0\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dois segundos</text><rect x=\"420\" y=\"88\" width=\"150\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"495.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Notify</text><text x=\"495.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Task</text><text x=\"495.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para a fila do SQS</text><rect x=\"630\" y=\"88\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"667.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Done</text><text x=\"667.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Succeed</text><path d=\"M130 100 L170 100 L170 49 L196 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><text x=\"164\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">total > 1000</text><path d=\"M350 49 L385 49 L385 104 L416 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><path d=\"M130 122 L280 122 L280 130 L416 130\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#sf-a)\"></path><text x=\"205\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Default</text><path d=\"M570 110 L626 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#sf-p)\"></path><path d=\"M20 186 L48 186\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><text x=\"56\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order-42, total 1500: 13 eventos</text><path d=\"M370 186 L398 186\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 3\"></path><text x=\"406\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order-43, total 300: 11 eventos, sem Wait</text></svg>", "caption": "Uma definição, duas execuções. O Choice lê cada entrada e a manda por um caminho diferente; o histórico de cada execução lista os estados em que ela entrou, e é assim que as duas execuções acima diferem."}
```

O endereço da fila no arquivo está na forma da AWS, `https://sqs.sa-east-1.amazonaws.com/...`, e o
moto o aceitou, então o mesmo arquivo roda sem mudança contra uma conta real.

## O que o moto deixa passar

A AWS verifica uma definição quando ela é criada. Um `Next` que nomeia um estado que não existe,
uma regra de `Choice` sem `Next`, um estado que nada alcança: cada um é recusado com
`InvalidDefinition` e uma mensagem citando o estado. **O moto não verifica nada disso:**

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name broken --definition '{"StartAt": "A", "States": {"A": {"Type": "Pass", "Next": "B"}}}' --role-arn "$ROLE" --query stateMachineArn --output text
arn:aws:states:sa-east-1:123456789012:stateMachine:broken
```

`B` não existe, e na AWS este comando falha. No laboratório, um erro como esse só aparece quando
uma execução chega ao estado quebrado, então leia uma definição antes de confiar que o moto a
aceitou. Na AWS, `aws stepfunctions validate-state-machine-definition` faz a mesma verificação sem
criar nada; o moto não a implementa.

## Muitos de uma vez: Map e Parallel

Dois estados rodam mais de uma coisa. Salve este como `~/aws/split.asl.json`:

```schooling-example
{"language": "json", "file": "split.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"Lines\",\n  \"States\": {\n    \"Lines\": {\n      \"Type\": \"Map\",\n      \"ItemsPath\": \"$.lines\",\n      \"MaxConcurrency\": 2,\n", "note": "Um `Map` roda os mesmos passos uma vez para cada item de uma lista, aqui cada linha de um pedido, no máximo duas por vez."}, {"code": "      \"ItemProcessor\": {\n        \"ProcessorConfig\": {\"Mode\": \"INLINE\"},\n        \"StartAt\": \"Price\",\n        \"States\": {\n          \"Price\": {\"Type\": \"Pass\", \"Parameters\": {\"sku.$\": \"$.sku\", \"cents.$\": \"$.cents\"}, \"End\": true}\n        }\n      },\n      \"ResultPath\": \"$.priced\",\n      \"Next\": \"Both\"\n    },\n", "note": "Os passos de um item são uma pequena máquina de estados própria. `Pass` não faz nada além de moldar dados, o que o torna o substituto de trabalho real num rascunho; `INLINE` mantém as iterações dentro desta execução."}, {"code": "    \"Both\": {\n      \"Type\": \"Parallel\",\n      \"Branches\": [\n        {\"StartAt\": \"Invoice\", \"States\": {\"Invoice\": {\"Type\": \"Pass\", \"Result\": \"invoice queued\", \"End\": true}}},\n        {\"StartAt\": \"Pick\", \"States\": {\"Pick\": {\"Type\": \"Pass\", \"Result\": \"picking list queued\", \"End\": true}}}\n      ],\n      \"ResultPath\": \"$.done\",\n      \"End\": true\n    }\n  }\n}\n", "note": "Um `Parallel` roda ramos diferentes ao mesmo tempo e espera todos; o resultado é uma lista com uma entrada por ramo, na ordem em que os ramos estão escritos."}]}
```

Um pedido com duas linhas passa por ele:

```
ana@laptop:~/aws$ SPLIT=$(aws stepfunctions create-state-machine --name split --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$SPLIT" --name order-44 --input '{"lines": [{"sku": "A1", "cents": 1200}, {"sku": "B7", "cents": 350}]}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:split:order-44
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${SPLIT/stateMachine/execution}:order-44" --query output --output text | jq -c .
{"lines":[{"sku":"A1","cents":1200},{"sku":"B7","cents":350}],"priced":[{"sku":"A1","cents":1200},{"sku":"B7","cents":350}],"done":["invoice queued","picking list queued"]}
```

`priced` guarda um resultado por linha, na ordem das linhas, e `done` um por ramo. Os estados
`Pass` estão no lugar de trabalho real aqui; numa máquina real cada um seria um `Task`. Na AWS um
`Map` também pode rodar no modo `DISTRIBUTED`, em que cada item vira uma execução filha própria e
uma lista de milhões de objetos no S3 é processada em paralelo. Esta aula roda só o `INLINE`.
