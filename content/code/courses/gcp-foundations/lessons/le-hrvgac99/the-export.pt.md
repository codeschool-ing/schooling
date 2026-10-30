---
title: A exportação, e onde ela cai
version: 1
---

**A tabela de custos do console responde às perguntas que alguém pensou em pôr nela. A exportação de
faturamento responde ao resto**: o Cloud Billing escreve cada linha da fatura, como linhas de tabela, num
dataset do BigQuery que pertence ao cliente, e dali em diante qualquer pergunta sobre custo é uma consulta. É
a ferramenta com que a lição 13 terminou, e a que toda empresa com mais que uns poucos projetos acaba usando.

São três exportações, cada uma uma tabela própria no mesmo dataset:

| exportação | o que cada linha é | tabela |
|---|---|---|
| **custo de uso padrão** | o uso e o custo de um SKU num projeto ao longo de um trecho de tempo, em geral uma hora | `gcp_billing_export_v1_<account>` |
| **custo de uso detalhado** | o mesmo, mais quebrado, até o recurso individual quando o serviço informa um | `gcp_billing_export_resource_v1_<account>` |
| **preços** | o preço de tabela de um SKU e o preço que esta conta paga | `cloud_pricing_export` |

`<account>` é o id da conta de faturamento com sublinhados no lugar dos hífens. O planner liga as duas
primeiras e lê a padrão nesta lição: ela é menor, e toda pergunta abaixo pode ser respondida por ela.

**A documentação da exportação não estava acessível quando esta lição foi escrita**, então a tabela acima, e
as colunas da próxima seção, vêm do esquema publicado como estava antes, não lido no dia. Confira o nome de
uma coluna na página atual antes de confiar nele num relatório que alguém assina.

## O que é criado, e por quem

Duas coisas, por duas pessoas:

1. **Um dataset do BigQuery**, num projeto. É um recurso comum, criado como qualquer outro, e o planner o
   mantém no `planner-logs`, o projeto que a lição 2 pôs na pasta `shared`.
2. **A exportação em si**, ligada na página *Billing export* do console por alguém com
   `roles/billing.costsManager` ou `roles/billing.admin` na conta de faturamento, lição 11. Não há comando
   gcloud nem recurso de Terraform para ela: de tudo neste curso, é o único passo feito só por uma pessoa, no
   console.

Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/export-dataset && cd ~/gcp/export-dataset
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `dataset.tf`, com um hífen no nome, que é o que a maioria das pessoas digita primeiro:

```hcl
resource "google_bigquery_dataset" "billing" {
  project    = "planner-logs"
  dataset_id = "billing-export"
  location   = "southamerica-east1"
}
```

```
ana@laptop:~/gcp/export-dataset$ terraform plan -input=false -no-color 2>&1 | tail -6
Error: "dataset_id" must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_)

  with google_bigquery_dataset.billing,
  on dataset.tf line 3, in resource "google_bigquery_dataset" "billing":
   3:   dataset_id = "billing-export"
```

**O provider recusa antes de perguntar a alguém**: um id de dataset aceita letras, números e sublinhados, e
nada mais. Troque o hífen por um sublinhado, e dê ao pessoal de finanças acesso de leitura ao dataset e a nada
em volta dele. Substitua o `dataset.tf` por isto:

```hcl
resource "google_bigquery_dataset" "billing" {
  project    = "planner-logs"
  dataset_id = "billing_export"
  location   = "southamerica-east1"
}

resource "google_bigquery_dataset_iam_member" "finance" {
  project    = "planner-logs"
  dataset_id = google_bigquery_dataset.billing.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:finance@example.com"
}
```

```
ana@laptop:~/gcp/export-dataset$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|location|dataset_id|role"
  # google_bigquery_dataset.billing will be created
      + dataset_id                 = "billing_export"
      + location                   = "southamerica-east1"
  # google_bigquery_dataset_iam_member.finance will be created
      + dataset_id = "billing_export"
      + role       = "roles/bigquery.dataViewer"
Plan: 2 to add, 0 to change, 0 to destroy.
```

Planejado, não criado: o BigQuery não tem emulador neste laboratório. Três escolhas nesse arquivo importam
mais do que parecem:

- **A localização é definida uma vez.** Um dataset não pode ser movido para outra região depois, e a
  exportação escreve onde o dataset está. O planner guarda a fatura em São Paulo, com todo o resto.
- **O acesso de leitura é no dataset**, não no projeto. `roles/bigquery.dataViewer` no `planner-logs` abriria
  também tudo o mais que está guardado ali: um papel vai na menor coisa que resolve.
- **A exportação começa no dia em que é ligada.** Não conte com um histórico de antes: o momento mais barato
  de ligá-la é o dia em que a conta de faturamento é aberta, e cada mês antes disso é um mês que as consultas
  desta lição não respondem.
