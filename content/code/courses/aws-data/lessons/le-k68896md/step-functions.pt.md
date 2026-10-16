---
title: O mesmo pipeline como máquina de estados
version: 1
---

**O Step Functions roda um pipeline escrito como máquina de estados**: um documento JSON de estados,
cada um dizendo o que faz e qual estado vem depois. Um estado `Task` chama um serviço, e com o sufixo
`.sync` no recurso ele espera a chamada terminar, então um estado que liga um job do Glue só segue
quando o job deu certo. Nada roda entre uma execução e outra e nada é cobrado entre elas: os
workflows Standard são cobrados por transição de estado, e um pipeline de dois estados rodado uma vez
por noite faz poucas transições por noite. A tabela de preços deste curso não tem linha para o Step
Functions, então esta lição não cita número para ele.

Eis a DAG da primeira seção de novo, como máquina de estados. Salve-a como `nightly.json`:

`nightly.json`:

```json
{
  "Comment": "Quitanda's nightly orders: load the day, then build the daily table",
  "StartAt": "LoadOrders",
  "States": {
    "LoadOrders": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "load-orders",
        "Arguments": {"--scheduled.$": "$.scheduled"}
      },
      "Retry": [{"ErrorEquals": ["States.ALL"], "IntervalSeconds": 300, "MaxAttempts": 2}],
      "Next": "BuildDaily"
    },
    "BuildDaily": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "build-daily",
        "Arguments": {"--scheduled.$": "$.scheduled"}
      },
      "Retry": [{"ErrorEquals": ["States.ALL"], "IntervalSeconds": 300, "MaxAttempts": 2}],
      "End": true
    }
  }
}
```

**Leia-a ao lado da DAG e as duas se alinham uma a uma.** `load_orders` é `LoadOrders`, o `>>` é
`"Next": "BuildDaily"`, e `retries=2` com cinco minutos entre elas é o `Retry` de cada estado, duas
tentativas com 300 segundos entre elas. O `.$` no fim de `--scheduled.$` diz ao Step Functions para
tirar o valor da entrada da execução, no caminho `$.scheduled`, em vez de passar o texto literal.

**O que não tem equivalente é o `{{ ds }}`.** O Airflow sabia qual intervalo uma execução cobria; uma
máquina de estados só sabe o que recebeu. Aqui ela recebe um horário, o momento em que o
agendamento disparou, e o job do Glue precisa calcular "ontem" a partir dele. Também não há backfill:
rodar de novo o dia 12 quer dizer iniciar uma execução à mão com o horário do dia 13 na entrada. Para
um pipeline que roda toda noite e raramente é refeito, é uma troca justa; para um que é refeito com
frequência, é a primeira coisa que dói.

## Criada, iniciada, e rodada por ninguém

Crie a máquina de estados, inicie-a uma vez à mão e olhe a execução:

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name quitanda-nightly --definition file://nightly.json --role-arn arn:aws:iam::123456789012:role/quitanda-sfn
{
    "stateMachineArn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
    "creationDate": "2026-10-16T13:07:38.607000-03:00"
}
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly --input '{"scheduled": "2026-10-16T03:00:00-03:00"}'
{
    "executionArn": "arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c",
    "startDate": "2026-10-16T13:07:39.229000-03:00"
}
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c --query '[status,input,output]'
[
    "RUNNING",
    "{\"scheduled\": \"2026-10-16T03:00:00-03:00\"}",
    null
]
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c --query 'events[].type'
[
    "ExecutionStarted",
    "PassStateEntered",
    "PassStateExited",
    "ExecutionSucceeded"
]
ana@laptop:~/aws$ aws glue get-job-runs --job-name load-orders

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetJobRuns operation: Job load-orders not found.
```

**O moto se contradiz, e as duas metades merecem leitura.** `describe-execution` diz que a execução
está `RUNNING`, e vai continuar assim: o moto não executa máquinas de estados, então nada a faz
andar. `get-execution-history` diz o contrário, que a execução começou, entrou num estado `Pass`,
saiu dele e deu certo. Não há estado `Pass` em `nightly.json`. Esse histórico é uma amostra fixa que
o moto devolve para qualquer execução, os mesmos quatro eventos seja qual for a definição, e não
descreve nada que tenha acontecido.

**O último comando resolve a questão.** A máquina de estados deveria ligar o job `load-orders` do
Glue, e o Glue nunca ouviu falar dele: não existe esse job neste moto, e nada rodou. Então o
laboratório mostra a definição, guardada e devolvida exatamente como foi escrita, e a requisição para
iniciá-la, bem formada. Como o Step Functions espera uma tarefa `.sync`, tenta de novo e faz a
execução falhar depois da segunda tentativa é comportamento documentado da AWS, e nada disso foi
rodado aqui.
