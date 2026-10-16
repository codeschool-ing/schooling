---
title: "Esperando: um relógio, um callback e um job"
version: 1
---

Orquestração de longa duração parece exigir algo rodando por muito tempo. **Nada roda.** Uma
execução Standard que espera três dias por um depósito custa o que as transições dela custam, e
nenhum processo seu fica de pé durante nada disso. O Step Functions tem três jeitos de esperar, e
eles diferem em quem decide que a espera acabou: um relógio, alguém que tem um token, ou o job que o
estado iniciou.

## Um relógio: Wait

O estado `Wait` da máquina de pedidos esperou dois segundos. Ele também pode esperar até um
momento, com `Timestamp`, ou por um número ou uma data tirados da entrada, com `SecondsPath` e
`TimestampPath`: um lembrete mandado na hora que o cliente escolheu é um `Wait` com
`TimestampPath`. Num workflow Standard o estado conta como transições igual a qualquer outro, e o
tempo passado nele é de graça, então **uma espera de uma semana custa o mesmo que uma de um
segundo**. Um workflow Express não consegue esperar além dos seus cinco minutos.

## Alguém com um token: .waitForTaskToken

Alguns trabalhos terminam quando uma pessoa ou outro sistema diz: uma loja confirma que separou um
pedido, um gerente aprova um reembolso. A tarefa entrega um token e a execução espera até o token
voltar. Salve o arquivo como `~/aws/token.asl.json`:

```schooling-example
{"language": "json", "file": "token.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"AskStore\",\n  \"States\": {\n    \"AskStore\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage.waitForTaskToken\",\n", "note": "O sufixo `.waitForTaskToken` muda o que a tarefa espera: ela manda a mensagem e então espera alguém dizer que o trabalho terminou, leve o tempo que levar."}, {"code": "      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/store\",\n        \"MessageBody\": {\"order.$\": \"$.id\", \"token.$\": \"$$.Task.Token\"}\n      },\n", "note": "`$$` lê o contexto em vez da entrada, e `$$.Task.Token` é o token desta espera. Ele viaja dentro da mensagem, porque quem terminar o trabalho precisa devolvê-lo."}, {"code": "      \"TimeoutSeconds\": 86400,\n      \"End\": true\n    }\n  }\n}\n", "note": "Sem timeout, um token que ninguém devolve deixa a execução esperando o tempo que uma execução Standard pode viver, que é um ano. Um dia é o limite aqui."}]}
```

A Ana inicia a execução, e o lado da loja na conversa é feito à mão no prompt: ler o pedido da fila
e informar sucesso com o token que ele traz:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name store --query QueueUrl --output text
http://localhost:4567/123456789012/store
ana@laptop:~/aws$ TOKEN_SM=$(aws stepfunctions create-state-machine --name ask-store --definition file://token.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$TOKEN_SM" --name order-46 --input '{"id": "46"}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:ask-store:order-46
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query status
"RUNNING"
ana@laptop:~/aws$ MSG=$(aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/store --query "Messages[0].Body" --output text); echo "$MSG"
{"order": "46", "token": "57190edc-1fda-4e90-8701-408ad3fc2252"}
```

**A execução ficou em `RUNNING` sem nada rodando.** A mensagem traz o pedido e o token, e é tudo de
que a loja precisa. Agora ela responde:

```
ana@laptop:~/aws$ aws stepfunctions send-task-success --task-token "$(echo "$MSG" | jq -r .token)" --task-output '{"picked": true}'
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "{status: status, output: output}"
{
    "status": "SUCCEEDED",
    "output": "{\"picked\": true}"
}
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "events[].type" --output text
ExecutionStarted	TaskStateEntered	TaskScheduled	TaskStarted	TaskSubmitted	TaskSucceeded	TaskStateExited	ExecutionSucceeded
```

O `send-task-success` é a loja dizendo que terminou, e o `--task-output` vira o resultado da
tarefa. No histórico, `TaskSubmitted` é o momento em que a mensagem saiu e `TaskSucceeded` o
momento em que o token voltou; entre os dois, a execução não guardava nada além do seu lugar. As
outras duas chamadas que um worker pode fazer são `send-task-failure`, com um erro e uma causa, que
o `Retry` e o `Catch` do estado tratam como qualquer falha de tarefa, e `send-task-heartbeat`, que
importa quando o estado define `HeartbeatSeconds`: um worker que fica calado por mais tempo que
isso faz a tarefa falhar com `States.HeartbeatTimeout`, então um worker que caiu é percebido em
minutos, e não no fim de um `TimeoutSeconds` de um dia.

O token do moto é um UUID. **O token da AWS é uma string opaca e longa, de até 1.024 caracteres**, e
a única coisa a fazer com ele é guardá-lo inteiro e devolvê-lo; nada nele é para ser lido.

## O próprio job: .sync

O terceiro jeito é para trabalho que outro serviço da AWS roda e de que sabe o fim. Uma tarefa cujo
recurso termina em `.sync`, como `arn:aws:states:::ecs:runTask.sync` para uma tarefa ECS da aula 8
ou `arn:aws:states:::states:startExecution.sync:2` para uma máquina de estados filha, inicia o job
e então espera até o job terminar, e o resultado da tarefa é o desfecho do job. Sem `.sync`, o
mesmo recurso inicia o job e segue em frente na hora, o que é o certo quando ninguém precisa do
resultado.

**Esta parte não foi rodada.** O moto não tem tarefa ECS para esperar, já que não roda contêiner
nenhum, e a aula não se apoia no que o interpretador dele faria com uma. Na AWS, o Step Functions
acompanha o próprio job, por eventos onde o serviço os oferece e consultando onde não oferece, e
uma tarefa `.sync` é cobrada como transições igual a qualquer outra; a espera é de graça aqui
também. Como o `.waitForTaskToken`, ela só existe em workflows Standard.

## Qual espera, para qual trabalho

- Uma hora conhecida, ou uma hora na entrada: `Wait`.
- Uma pessoa, ou um sistema fora da AWS que vai chamar de volta: `.waitForTaskToken`, com um
  `TimeoutSeconds` que diz quanto é demais e, para um worker que pode cair, um `HeartbeatSeconds`.
- Um job no ECS, Batch, Glue, CodeBuild ou outra máquina de estados: `.sync`.

O motivo para fazer qualquer coisa disso numa máquina de estados e não numa função é o mesmo com
que a aula 19 terminou. Uma requisição que inicia um job de minutos responde na hora com o nome de
uma execução, e o cliente pergunta ao `describe-execution` depois, ou é avisado pela fila e pelo
tópico da aula 21. A espera em si acontece no único lugar feito para lembrar dela.
