---
title: O vínculo entre um projeto e o que paga por ele
version: 1
---

**Todo projeto que usa serviços pagos é vinculado a exatamente uma conta de faturamento.** O vínculo pode
ser feito quando o projeto é criado ou depois, e pode passar para outra conta a qualquer hora: um projeto em
desenvolvimento pago pela conta da equipe passa para a conta de produção quando entra no ar, e os recursos
dele nem percebem.

O `gcloud` tem os comandos das duas pontas, e o laboratório consegue mandar o primeiro deles ao Google:

```
ana@laptop:~/gcp$ gcloud billing accounts list
ERROR: (gcloud.billing.accounts.list) UNAUTHENTICATED: Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project. This command is authenticated with an access token from /home/ana/gcp/placeholder-token specified by the [auth/access_token_file] property.
- '@type': type.googleapis.com/google.rpc.ErrorInfo
  metadata:
    method: google.cloud.billing.v1.CloudBilling.ListBillingAccounts
    service: cloudbilling.googleapis.com
  reason: CREDENTIALS_MISSING
```

A recusa vem do `cloudbilling.googleapis.com`, a API do Cloud Billing, com as próprias palavras. Contra uma
conta real, o comando lista toda conta de faturamento que quem pede pode ver, com o id, o nome e se está
aberta. O `gcloud billing projects link planner-dev --billing-account=012345-6789AB-CDEF01` faria então o
vínculo, e o `gcloud billing projects describe planner-dev` o mostraria. **Nenhum dos dois foi rodado aqui**:
os dois seriam recusados do mesmo jeito.

## O vínculo como código

O Terraform escreve o vínculo como um argumento do projeto. Crie um diretório com o arquivo do provider da
lição 2:

```sh
mkdir -p ~/gcp/billing && cd ~/gcp/billing
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `billing.tf`. Ele vincula o projeto de relatórios da lição 3 à conta da empresa, e deixa a
líder da equipe vincular projetos a ela:

```hcl
locals {
  billing_account = "012345-6789AB-CDEF01" # made up for this course
}

resource "google_project" "reports" {
  name            = "Planner reports"
  project_id      = "planner-reports"
  folder_id       = "345678901234"
  billing_account = local.billing_account
}

resource "google_billing_account_iam_member" "lead_links_projects" {
  billing_account_id = local.billing_account
  role               = "roles/billing.user"
  member             = "user:ana@example.com"
}
```

```
ana@laptop:~/gcp/billing$ terraform plan -input=false -no-color | grep -E '^  # |      \+ (billing_account|billing_account_id|role|member) |^Plan:'
  # google_billing_account_iam_member.lead_links_projects will be created
      + billing_account_id = "012345-6789AB-CDEF01"
      + member             = "user:ana@example.com"
      + role               = "roles/billing.user"
  # google_project.reports will be created
      + billing_account     = "012345-6789AB-CDEF01"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## O que desvincular faz

**Desvincular é o interruptor que para os serviços pagos de um projeto**, e o Google o trata como o ato
sério que é. Quando um projeto perde a conta de faturamento, ou a conta é fechada, os serviços pagos dele
param: máquinas virtuais são desligadas, APIs que custam dinheiro recusam pedidos, e recursos que custam
dinheiro para ser mantidos, como discos e dados guardados, **podem ser apagados** se o faturamento não for
restabelecido, num prazo que a documentação do Google dá por serviço. Um projeto que deveria pausar tem de
ser parado de propósito, não desvinculado para ver o que acontece.

É também, numa emergência, o único jeito de parar o gasto na hora. A lição 12 volta a isso: um orçamento
não para o gasto, e um desvínculo automatizado é o jeito documentado de fazê-lo parar.
