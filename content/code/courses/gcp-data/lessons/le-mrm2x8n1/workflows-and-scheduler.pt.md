---
title: O mesmo pipeline como workflow, iniciado pelo Cloud Scheduler
version: 1
---

**O Workflows roda um pipeline escrito como uma lista de passos**, em YAML: cada passo atribui uma
variável, faz uma chamada ou decide para onde ir, e uma chamada a uma API do Google por meio de um
**conector** espera uma operação longa terminar antes de o próximo passo começar. Nada roda entre
execuções e nada é cobrado entre elas: o Workflows cobra por passo executado, e o **Cloud
Scheduler**, que inicia coisas num horário, cobra por job definido. Nenhum dos dois tem emulador,
então esta seção é lida, e todo comando dela está marcado como não rodado.

Aqui está o pipeline da Quitanda como workflow, com o job Spark como batch do Dataproc Serverless.
Salve-o como `nightly.yaml`:

`nightly.yaml`:

```yaml
main:
  steps:
    - pick_day:
        assign:
          - day: ${text.substring(time.format(sys.now() - 86400, "America/Sao_Paulo"), 0, 10)}
    - daily_orders:
        call: googleapis.dataproc.v1.projects.locations.batches.create
        args:
          parent: projects/planner-dev/locations/southamerica-east1
          batchId: ${"daily-orders-" + day}
          body:
            pysparkBatch:
              mainPythonFileUri: gs://quitanda-raw-prod/jobs/daily_orders.py
              args: ["--dt", "${day}", "--src", "gs://quitanda-raw-prod/raw",
                     "--dst", "gs://quitanda-curated-prod"]
        result: batch
    - done:
        return: ${batch.state}
```

**Leia-o ao lado do DAG e os dois se alinham, com uma diferença.** O `daily_orders` é o
`DataprocCreateBatchOperator` da primeira seção, e o conector submete o batch e espera por ele como o
operador fazia. Um passo pode ser envolvido num `try` com uma política de `retry`, e é assim que um
workflow ganha as duas novas tentativas do DAG; este ficou sem, para continuar curto.

**O que não tem equivalente é o intervalo.** O Airflow sabia para qual dia era uma execução; um
workflow só sabe quando está rodando, então o `pick_day` calcula "ontem" a partir do relógio,
`sys.now()` menos os segundos de um dia, formatado no horário de São Paulo. Rodando atrasado, ele
ainda calcula o dia anterior ao momento em que roda, o que está certo. Rodado de novo no dia 3 para o dia 1, ele calcula o dia 2, o que está errado, e o único jeito de rodar de novo uma noite passada é
passar o dia como argumento, coisa que este workflow não recebe. Também não há backfill: rodar de novo
uma semana significa iniciar sete execuções à mão. Para um pipeline que roda toda noite e raramente
é refeito, é uma troca justa; para um que é refeito com frequência, é a primeira coisa que dói.

Publicá-lo é um comando, **não rodado aqui**:

```sh
gcloud workflows deploy quitanda-nightly --location=southamerica-east1 \
  --source=nightly.yaml --service-account=quitanda-pipeline@planner-dev.iam.gserviceaccount.com
```

A conta de serviço é a identidade com que o workflow age, e ela precisa do direito de criar batches
do Dataproc e de mais nada. O `gcp-foundations` é onde contas de serviço e os papéis delas são
criados.

## Três da manhã, pelo Cloud Scheduler

**O Cloud Scheduler inicia coisas num horário**: um job nomeia um agendamento e um alvo, e na hora
certa chama o alvo. Aqui o alvo é o endereço da API do Workflows que inicia uma execução. Uma coisa
sobre ele vale perguntar à linha de comando antes de escrever o job, porque decide de que três da
manhã se trata:

```
ana@laptop:~/gcp$ gcloud scheduler jobs create http --help | grep -A1 -E -- '^ +--time-zone'
     --time-zone=TIME_ZONE; default="Etc/UTC"
        Specifies the time zone to be used in interpreting --schedule. The
```

**O fuso padrão é `Etc/UTC`.** Um job criado com `--schedule='0 3 * * *'` e sem `--time-zone`
dispara às três da manhã UTC, que é meia-noite em São Paulo, e o workflow então calcularia "ontem"
três horas antes de o dia ter terminado. Por isso o job diz o fuso. **Não rodado aqui:**

```sh
gcloud scheduler jobs create http quitanda-nightly --location=southamerica-east1 \
  --schedule='0 3 * * *' --time-zone=America/Sao_Paulo \
  --uri=https://workflowexecutions.googleapis.com/v1/projects/planner-dev/locations/southamerica-east1/workflows/quitanda-nightly/executions \
  --http-method=POST \
  --oauth-service-account-email=quitanda-scheduler@planner-dev.iam.gserviceaccount.com
```

**A expressão cron tem cinco campos**, minutos, horas, dia do mês, mês e dia da semana, a mesma
forma Unix que o `schedule` do DAG usou, então dá para ler os dois lado a lado. A conta de serviço é
a que o Scheduler usa para chamar o Workflows, e ela precisa do direito de iniciar execuções deste
único workflow. Se a chamada falha, o Scheduler tenta de novo conforme a configuração de novas
tentativas do job, e ele não sabe nem quer saber se o workflow deu certo depois: um batch que falhou
aparece como execução falha no Workflows, e alguém precisa ser avisado disso por um alerta, que
nenhum dos dois serviços manda sozinho.

## O que cada um dos dois guarda

| | Composer | Workflows com Cloud Scheduler |
|---|---|---|
| pipeline escrito como | Python, num arquivo de DAG | YAML, num workflow |
| para qual dia é uma execução | a logical date e o intervalo de dados | o relógio, no momento em que roda |
| backfill | um comando, para qualquer intervalo de dias | uma execução por dia, iniciada à mão |
| esperar por um arquivo | um sensor | um laço de passos, ou um gatilho do Eventarc que inicia o workflow |
| histórico de execuções | o banco de metadados e a interface web | cada execução, os passos e o resultado dela |
| o que você opera | o tamanho do ambiente, os pacotes, as atualizações | as definições |
| custo parado | o ambiente, toda hora | nada |

A seção anterior pôs um número na última linha; a próxima trata da segunda e da terceira.
