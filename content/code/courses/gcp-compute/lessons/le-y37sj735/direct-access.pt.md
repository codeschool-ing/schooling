---
title: Acesso direto, sem conta de serviço do Google
version: 1
---

A seção 03 usou duas identidades: a conta de serviço do Kubernetes e uma conta de serviço do Google
como a qual ela podia agir. **Hoje o Google também deixa a própria identidade do Kubernetes receber
papéis diretamente, sem conta de serviço do Google no meio.** Uma identidade, uma vinculação, e
nada a personificar.

## O principal

Numa concessão direta, o membro não é `serviceAccount:` coisa nenhuma. É um **identificador de
principal** que nomeia a conta de serviço do Kubernetes dentro do workload pool, e traz o
**número** do projeto, os doze dígitos que o Google atribui, e não o id:

```
principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos
```

Leia da direita para a esquerda: a conta de serviço `photos` do Kubernetes, no namespace `shop`, no
pool `planner-dev.svc.id.goog`. Uma variante que termina num namespace em vez de numa conta de
serviço, ou que nomeia um conjunto de principais, concede algo a todo pod que combine, e é assim que
um namespace inteiro recebe um papel de uma vez.

## Escrevendo

Acrescente um arquivo `direct.tf` à pasta `wi` da seção 03. **O `planner-dev` não tem número de
projeto neste laboratório, porque não existe no Google**, então o número é uma variável com doze
zeros no lugar do real:

```hcl
# wi/direct.tf
variable "project_number" {
  type    = string
  default = "000000000000"
}

resource "google_storage_bucket_iam_member" "photos_direct" {
  bucket = "shop-photos"
  role   = "roles/storage.objectViewer"
  member = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos"
}
```

O plan, filtrado na vinculação nova:

```
ana@laptop:~/gcp/wi$ terraform plan -no-color | grep -E '^  # .*direct|principal|^Plan'
  # google_storage_bucket_iam_member.photos_direct will be created
      + member = "principal://iam.googleapis.com/projects/000000000000/locations/global/workloadIdentityPools/planner-dev.svc.id.goog/subject/ns/shop/sa/photos"
Plan: 4 to add, 0 to change, 0 to destroy.
```

Esse único recurso faz o que a seção 03 precisou de três para fazer. Num projeto real você
definiria a variável com o número do projeto, que o `gcloud projects describe planner-dev` mostra e
que precisa de conta; não foi executado aqui.

## Qual usar

O acesso direto é o arranjo mais simples, e a documentação do Google agora o apresenta primeiro. O
jeito com conta de serviço continua, e ainda é o certo em dois casos:

- **uma API do Google que ainda não aceita identificadores de principal.** O Google mantém uma lista
  dos produtos que aceitam a forma direta e das limitações, e uma vinculação num recurso fora dela
  precisa passar por uma conta de serviço;
- **a mesma identidade é necessária fora do cluster também**, por um serviço do Cloud Run ou um job
  numa máquina virtual, quando agir como uma conta de serviço do Google com nome mantém um único
  lugar para conceder e revogar.

Para o `photos` da loja, que só lê um bucket, a concessão direta basta. Seja como for, a mudança em
relação à seção 01 é a mesma, e é a que importa: **nenhuma chave existe**, então não há nada a
vazar, nada a trocar e nada que dure mais que a necessidade do pod.
