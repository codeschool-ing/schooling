---
title: Três da manhã, e qual dos dois escolher
version: 1
---

**O EventBridge Scheduler liga coisas num horário**: um agendamento indica um horário, um alvo e a
entrada a entregar, e nesse horário ele chama o alvo. Ele substitui o papel do scheduler do Airflow,
e nada além disso; a ordem do pipeline, as novas tentativas e a espera são da máquina de estados que
ele inicia. Ele cobra por invocação, e a linha dele, como a do Step Functions, não está na tabela de
preços deste curso.

O alvo do agendamento é a máquina de estados, e a entrada leva o momento em que o agendamento
disparou. Salve o alvo como `target.json`:

`target.json`:

```json
{
  "Arn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
  "RoleArn": "arn:aws:iam::123456789012:role/quitanda-scheduler",
  "Input": "{\"scheduled\": \"<aws.scheduler.scheduled-time>\"}"
}
```

**`<aws.scheduler.scheduled-time>` é preenchido pelo Scheduler quando ele dispara**, com o horário
em que a execução estava marcada e não o horário em que ela por acaso começou, e é a partir dele que o
job do Glue deve calcular "ontem". O papel é o que o Scheduler assume para chamar o Step Functions, e
a entrada é um documento JSON escrito como texto dentro de JSON, e é por isso que as aspas dele estão
escapadas. Crie o agendamento:

```
ana@laptop:~/aws$ aws scheduler create-schedule --name quitanda-nightly --schedule-expression 'cron(0 3 * * ? *)' --schedule-expression-timezone America/Sao_Paulo --flexible-time-window Mode=OFF --target file://target.json
{
    "ScheduleArn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-nightly"
}
ana@laptop:~/aws$ aws scheduler get-schedule --name quitanda-nightly
{
    "Arn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-nightly",
    "CreationDate": "2026-10-16T13:07:42.676690-03:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-10-16T13:07:42.676690-03:00",
    "Name": "quitanda-nightly",
    "ScheduleExpression": "cron(0 3 * * ? *)",
    "ScheduleExpressionTimezone": "America/Sao_Paulo",
    "State": "ENABLED",
    "Target": {
        "Arn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
        "Input": "{\"scheduled\": \"<aws.scheduler.scheduled-time>\"}",
        "RetryPolicy": {
            "MaximumEventAgeInSeconds": 86400,
            "MaximumRetryAttempts": 185
        },
        "RoleArn": "arn:aws:iam::123456789012:role/quitanda-scheduler"
    }
}
```

**`cron(0 3 * * ? *)` tem seis campos, e não cinco**, e esse é o cron da AWS, não o do Unix:
minutos, horas, dia do mês, mês, dia da semana e ano, com um `?` num dos dois campos de dia para dizer
"qualquer um". Com `--schedule-expression-timezone America/Sao_Paulo`, as três são as três de São
Paulo, ou seja, seis da manhã em UTC; sem isso, o agendamento dispararia à meia-noite em São Paulo. A
política de novas tentativas foi preenchida com o padrão, como a AWS também faz: até 185 tentativas
dentro de um dia, para um alvo que se recusa a começar.

**O moto guarda o agendamento e não dispara nada.** Às três da manhã nada vai acontecer neste
laboratório, porque o moto não tem um relógio que chame alvos. E ele confere menos que a AWS: dê a
ele o cron de cinco campos da DAG e ele aceita também.

```
ana@laptop:~/aws$ aws scheduler create-schedule --name quitanda-five-fields --schedule-expression 'cron(0 3 * * *)' --flexible-time-window Mode=OFF --target file://target.json
{
    "ScheduleArn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-five-fields"
}
ana@laptop:~/aws$ aws scheduler list-schedules --query 'Schedules[].[Name,State]' --output text
quitanda-five-fields	ENABLED
quitanda-nightly	ENABLED
```

**Na AWS essa chamada é recusada** com um erro de validação, porque `cron(0 3 * * *)` não é uma
expressão cron válida da AWS; o moto a guardou como foi escrita. Um agendamento errado desse jeito
nunca dispara, e numa conta de verdade o erro na criação é o que salva você de um pipeline que em
silêncio nunca rodou.

## MWAA, ou Step Functions com Scheduler

**Escolha pelo número e pelo formato dos pipelines, não pelo tamanho dos dados**, porque nenhum dos
dois faz o trabalho pesado: os dois ligam Glue, EMR ou Athena e esperam.

| | MWAA | Step Functions com Scheduler |
|---|---|---|
| custo ocioso | 615.02 por mês pelo menor ambiente da tabela | nada entre as execuções |
| pipeline escrito como | Python, num arquivo de DAG | JSON, numa máquina de estados |
| intervalos e backfill | embutidos: toda execução conhece o seu intervalo | nenhum: a entrada leva um horário |
| esperar um arquivo ou uma partição | sensores | um laço de estados, ou um evento que inicia a máquina |
| serviços fora da AWS | muitos operadores | uma chamada HTTP, ou uma Lambda escrita para isso |
| o que você opera | o tamanho do ambiente, os pacotes, as atualizações | as definições |

**Para a Quitanda de hoje, com um pipeline de dois passos, Step Functions com Scheduler é a
resposta**: a mesma ordem, as mesmas novas tentativas, e nenhum 615.02 por mês por um agendador que
espera. No dia em que houver trinta DAGs, três equipes e o costume de rodar de novo a semana passada,
a tabela vira, e ir para o MWAA é um trabalho de que a equipe vai gostar, e não um custo de que vai
reclamar. Escrever o primeiro pipeline de modo que cada passo seja o seu próprio job do Glue, com a
data como argumento, é o que mantém essa mudança barata: os jobs ficam, e só muda o que os liga.
