---
title: Novas tentativas, tempos limite e fazer duas vezes com segurança
version: 1
---

Uma tarefa que sai com qualquer coisa diferente de 0 falhou, e **o Cloud Run a inicia de novo, como
uma nova tentativa da mesma tarefa com o mesmo índice, até o número máximo de novas tentativas do
job.** Isso é quase sempre o que você quer, e tem uma consequência para a qual o programa precisa
ser escrito: parte do trabalho pode ser feita duas vezes.

## Uma falha e a nova tentativa, em casa

O `FAIL_TASK=1` faz a tarefa 1 falhar na primeira tentativa, como faria uma chamada a um serviço de
faturas lento. Fazendo de novo o papel do Cloud Run, rode a tentativa 0 e depois a tentativa 1 da
mesma tarefa:

```
ana@laptop:~/gcp$ docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e FAIL_TASK=1 invoices:1; echo "exit status $?"
{"severity": "INFO", "message": "task 1 of 3, attempt 0: orders [1002, 1005, 1008]"}
{"severity": "ERROR", "message": "task 1: the invoice service timed out"}
exit status 1
ana@laptop:~/gcp$ docker run --rm -e CLOUD_RUN_TASK_INDEX=1 -e CLOUD_RUN_TASK_COUNT=3 -e CLOUD_RUN_TASK_ATTEMPT=1 -e FAIL_TASK=1 invoices:1; echo "exit status $?"
{"severity": "INFO", "message": "task 1 of 3, attempt 1: orders [1002, 1005, 1008]"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
exit status 0
```

**A primeira tentativa falhou com status 1, então o Cloud Run tentaria de novo; a segunda deu
certo.** O índice não mudou: a nova tentativa é o mesmo pedaço de trabalho, e só o
`CLOUD_RUN_TASK_ATTEMPT` conta ao programa que ele já passou por ali. As tarefas 0 e 2 não são
afetadas: novas tentativas são por tarefa, como a ajuda do gcloud disse na seção 03, então um
pedaço ruim não reinicia os outros.

## Fazendo duas vezes com segurança

Veja o que a tentativa 0 fez antes de falhar: registrou os pedidos e parou antes de escrever
qualquer fatura. Suponha que ela tivesse falhado depois de escrever duas. A tentativa 1 escreveria
as três, e os pedidos 1002 e 1005 teriam **duas faturas cada**. Esse é o formato geral do problema:
uma nova tentativa repete o que a tentativa que falhou fez antes de falhar.

A correção é tornar cada passo **idempotente**, para que fazê-lo duas vezes deixe o mesmo resultado
que fazê-lo uma. Para o job de faturas isso quer dizer dar a cada fatura uma identidade que vem do
pedido, `invoice-1002`, e escrevê-la com uma operação que substitui em vez de acrescentar: um
arquivo com o nome do pedido num bucket, uma linha com o id do pedido como chave primária, uma
chamada de API com uma chave de idempotência. Aí a tentativa 1 reescreve a `invoice-1002` em vez de
criar uma segunda. **Um job que não é idempotente deve ter `max_retries = 0`**, e um alerta quando
falha, porque uma nova tentativa faria estrago.

## O job, por escrito

Salve isto como `jobtf/main.tf` em `~/gcp`:

```hcl
# jobtf/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_cloud_run_v2_job" "invoices" {
  name     = "invoices"
  location = "southamerica-east1"

  template {
    task_count  = 3
    parallelism = 3

    template {
      max_retries = 3
      timeout     = "600s"

      containers {
        image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/invoices:1"
      }
    }
  }
}
```

Os dois blocos `template` aninhados são o vocabulário da seção 02 na grafia do Terraform: o de fora
descreve uma **execução** (quantas tarefas, quantas ao mesmo tempo), o de dentro uma **tarefa** (as
novas tentativas, o tempo limite, o contêiner). Em `~/gcp/jobtf`, `terraform init` e o plan:

```
ana@laptop:~/gcp/jobtf$ terraform plan -no-color | grep -E '^  #|task_count|parallelism|max_retries|timeout|image|^Plan'
  # google_cloud_run_v2_job.invoices will be created
          + parallelism = 3
          + task_count  = 3
              + max_retries           = 3
              + timeout               = "600s"
                  + image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/invoices:1"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**O `timeout` vale para cada tentativa, não para a execução.** Com tempo limite de dez minutos e
três novas tentativas, uma tarefa pode rodar até quarenta minutos no total antes de a execução ser
dada como falha, o que vale saber antes de alguém pôr o tempo limite em uma hora "por segurança".

Rodá-lo é `gcloud run jobs execute invoices --region=southamerica-east1`, que neste laboratório para
na falta de conta como todo comando remoto. Com uma conta, ele inicia uma execução e, com `--wait`,
espera ela acabar e informa se toda tarefa deu certo.
