---
title: Erros, novas tentativas e a tarefa que roda duas vezes
version: 1
---

O primeiro instinto com um passo que falha é envolvê-lo num `try` e registrar o erro. Numa máquina
de estados **o tratamento de erro faz parte do documento**: um `Retry` diz quais erros tentar de
novo, quantas vezes e com que intervalo, e um `Catch` diz para onde a execução vai quando as novas
tentativas acabam. O serviço aplica os dois, registra cada tentativa no histórico e deixa o código
da sua tarefa livre de laços e pausas.

## Um erro tem nome

Toda falha numa execução carrega um nome de erro e uma causa. Uma tarefa que falha informa o erro
do serviço que ela chamou. O Step Functions acrescenta nomes próprios, todos começando com
`States.`: `States.Timeout` quando uma tarefa passa do seu `TimeoutSeconds`, `States.TaskFailed`
para qualquer falha de tarefa, `States.Permissions` quando a role não pode fazer a chamada.
**`States.ALL` casa com todos eles**, e é o pega-tudo que fica por último numa lista, depois dos
erros específicos que você quer tratar de outro jeito.

## Retry, depois Catch

Esta máquina manda para uma fila que não existe, então toda tentativa falha. Salve-a como
`~/aws/retry.asl.json`:

```schooling-example
{"language": "json", "file": "retry.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"Notify\",\n  \"States\": {\n    \"Notify\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage\",\n      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/missing\",\n        \"MessageBody\": \"42\"\n      },\n", "note": "A mesma tarefa de antes, apontada de propósito para uma fila que não existe, para que toda tentativa falhe."}, {"code": "      \"Retry\": [\n        {\"ErrorEquals\": [\"States.ALL\"], \"IntervalSeconds\": 1, \"MaxAttempts\": 2, \"BackoffRate\": 2}\n      ],\n", "note": "`Retry` tenta a tarefa de novo: depois de 1 segundo, depois de 1 × 2 = 2 segundos, e então desiste, porque `MaxAttempts` conta as novas tentativas e não a primeira."}, {"code": "      \"Catch\": [\n        {\"ErrorEquals\": [\"States.ALL\"], \"ResultPath\": \"$.error\", \"Next\": \"Failed\"}\n      ],\n      \"End\": true\n    },\n", "note": "`Catch` é o que acontece depois da última nova tentativa: o erro vai para `$.error` e a execução segue para `Failed` em vez de parar na tarefa."}, {"code": "    \"Failed\": {\"Type\": \"Fail\", \"Error\": \"NotifyFailed\", \"Cause\": \"the queue did not take the message\"}\n  }\n}\n", "note": "Um `Fail` encerra a execução com um erro com o nome que você deu, que é o que um alarme ou quem chamou lê."}]}
```

```
ana@laptop:~/aws$ RETRY=$(aws stepfunctions create-state-machine --name retry --definition file://retry.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$RETRY" --name order-45 --input '{"id": "45"}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:retry:order-45
ana@laptop:~/aws$ sleep 5
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "{status: status, error: error, cause: cause}"
{
    "status": "FAILED",
    "error": "NotifyFailed",
    "cause": "the queue did not take the message"
}
```

A execução falhou com o erro que o estado `Fail` nomeia, não com o do SQS. Esse é o propósito do
`Catch`: quem acompanha este workflow vê `NotifyFailed`, um nome que o time escolheu, e uma causa
escrita para pessoas. O histórico mostra o resto:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[].[id, type, timestamp]" --output text
1	ExecutionStarted	2026-10-16T13:31:56.235000-03:00
2	TaskStateEntered	2026-10-16T13:31:56.237000-03:00
3	TaskScheduled	2026-10-16T13:31:56.237000-03:00
4	TaskStarted	2026-10-16T13:31:56.237000-03:00
5	TaskFailed	2026-10-16T13:31:56.281000-03:00
6	TaskScheduled	2026-10-16T13:31:57.283000-03:00
7	TaskStarted	2026-10-16T13:31:57.283000-03:00
8	TaskFailed	2026-10-16T13:31:57.294000-03:00
9	TaskScheduled	2026-10-16T13:31:59.295000-03:00
10	TaskStarted	2026-10-16T13:31:59.295000-03:00
11	TaskFailed	2026-10-16T13:31:59.307000-03:00
12	TaskStateExited	2026-10-16T13:31:59.308000-03:00
13	FailStateEntered	2026-10-16T13:31:59.308000-03:00
14	ExecutionFailed	2026-10-16T13:31:59.308000-03:00
```

**Três tentativas, e os intervalos entre elas são o backoff.** A primeira tentativa falhou em
56.281; a segunda foi agendada em 57.283, um segundo depois, e a terceira em 59.295, dois segundos
depois da segunda falha, porque o `BackoffRate` dobrou o intervalo. São segundos reais deste
laptop, porque o moto roda as esperas. Na AWS o mesmo documento dá o mesmo cronograma, e dois
ajustes não usados aqui o mudam: `MaxDelaySeconds` limita até onde o intervalo pode crescer, e
`JitterStrategy` com valor `FULL` sorteia cada intervalo, para que mil execuções falhando juntas
não tentem todas no mesmo segundo.

O erro da própria tarefa está nos eventos de falha:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[?type==\`TaskFailed\`].taskFailedEventDetails | [0]"
{
    "resourceType": "sqs",
    "resource": "sendMessage",
    "error": "SQS.SdkClientException",
    "cause": "The specified queue does not exist."
}
```

`SQS.SdkClientException` é o nome que o moto dá a esta falha. A AWS nomeia os erros das integrações
de serviço pelo serviço e pela exceção, então espere outro nome lá, e **case nomes de erro reais só
depois de vê-los num histórico real**; até lá, `States.ALL` é a escolha honesta.

## Uma nova tentativa roda a tarefa de novo

Tentar de novo só é seguro para uma tarefa cuja segunda execução não faz mal. **Uma tarefa que roda
duas vezes não é um evento raro**: a primeira tentativa pode dar certo do outro lado e estourar o
tempo na volta, e a nova tentativa faz o mesmo trabalho de novo. Para uma mensagem numa fila isso
quer dizer uma duplicata, que um consumidor pode ser escrito para tolerar, e a aula 21 faz
exatamente isso. Para um pagamento quer dizer cobrar um cliente duas vezes.

A defesa é uma **chave de idempotência**: um identificador que é o mesmo em toda tentativa do mesmo
trabalho, que o serviço do outro lado usa para reconhecer uma repetição. O nome da execução é uma
chave natural, porque é único e não muda entre novas tentativas. `$$.Execution.Name` o lê dentro do
documento, e uma tarefa o repassa, por exemplo como o cabeçalho de idempotência do provedor de
pagamento ou como a chave de uma escrita condicional no DynamoDB. Um workflow Standard já garante
que a execução em si não roda duas vezes; a chave cobre as novas tentativas que você pediu, e um
workflow Express precisa dela em toda parte.

## O que não tentar de novo

Alguns erros vão falhar de novo aconteça o que acontecer. Um erro `States.Permissions` continua
sendo de permissão, e um erro de validação do outro lado continua sendo de validação. **Tente de
novo o passageiro e capture o permanente**: nomeie no `Retry` os erros que vêm e vão (limitação,
timeouts, um serviço fora do ar por um instante), e deixe todo o resto chegar ao `Catch` na hora em
vez de três tentativas depois. Um `Retry` em `States.ALL` com `MaxAttempts` alto transforma todo
bug numa longa espera antes da mesma falha.
