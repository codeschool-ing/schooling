---
title: O workload pool e a vinculação
version: 1
---

O Workload Identity se apoia numa ideia: **uma conta de serviço do Kubernetes no seu cluster ganha
um nome que o IAM do Google entende, e o IAM então é informado do que esse nome pode fazer.**
Nenhum segredo é copiado para lugar nenhum. O cluster responde pelo pod, e o Google confia no
cluster.

## O pool

O nome vem do **workload pool** do cluster, e o cluster da lição 13 já tem um:

```hcl
  workload_identity_config {
    workload_pool = "planner-dev.svc.id.goog"
  }
```

Um pool é sempre `PROJECT_ID.svc.id.goog`, um por projeto, compartilhado por todo cluster dele que
tenha o Workload Identity ligado. Dentro do pool, uma conta de serviço do Kubernetes é nomeada pelo
namespace e pelo próprio nome: a conta de serviço `photos` no namespace `shop` é
`planner-dev.svc.id.goog[shop/photos]`. Clusters Autopilot, como a lição 14 disse, já vêm com o
pool ligado.

No Standard o node pool também precisa rodar o servidor de metadados do GKE, que é o
`workload_metadata_config` com `GKE_METADATA` que o `pool.tf` da lição 13 definiu. Sem isso, um pod
que pede credenciais alcança a conta de serviço do próprio nó, que é o vazamento que o Workload
Identity existe para fechar.

## A vinculação

Há dois jeitos de dar acesso a esse nome. Esta seção mostra o mais antigo, ainda comum: **a
identidade do pod pode agir como uma conta de serviço do Google**, e a conta de serviço recebe o
acesso. Crie uma pasta `wi` em `~/gcp` com este `main.tf`:

```hcl
# wi/main.tf
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

resource "google_service_account" "photos" {
  account_id   = "photos-reader"
  display_name = "Reads the shop's photos"
}

resource "google_service_account_iam_member" "photos_pod" {
  service_account_id = google_service_account.photos.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:planner-dev.svc.id.goog[shop/photos]"
}

resource "google_storage_bucket_iam_member" "photos_read" {
  bucket = "shop-photos"
  role   = "roles/storage.objectViewer"
  member = google_service_account.photos.member
}
```

Três recursos, cada um com uma função: uma conta de serviço do Google; uma vinculação **nessa conta
de serviço** deixando a identidade do Kubernetes usá-la, pelo `roles/iam.workloadIdentityUser`; e
uma vinculação **no bucket** deixando a conta de serviço ler. Depois do `terraform init`:

```
ana@laptop:~/gcp/wi$ terraform plan -no-color | grep -E '^  #|account_id|email|member|role|^Plan'
  # google_service_account.photos will be created
      + account_id      = "photos-reader"
      + email           = "photos-reader@planner-dev.iam.gserviceaccount.com"
      + member          = "serviceAccount:photos-reader@planner-dev.iam.gserviceaccount.com"
  # google_service_account_iam_member.photos_pod will be created
  + resource "google_service_account_iam_member" "photos_pod" {
      + member             = "serviceAccount:planner-dev.svc.id.goog[shop/photos]"
      + role               = "roles/iam.workloadIdentityUser"
      + service_account_id = (known after apply)
  # google_storage_bucket_iam_member.photos_read will be created
  + resource "google_storage_bucket_iam_member" "photos_read" {
      + member = "serviceAccount:photos-reader@planner-dev.iam.gserviceaccount.com"
      + role   = "roles/storage.objectViewer"
Plan: 3 to add, 0 to change, 0 to destroy.
```

O provider calculou o e-mail da conta de serviço a partir do `account_id` e do projeto, então o plan
o mostra antes de qualquer coisa existir. Duas recusas valem ser vistas uma vez, porque as duas são
erros que as pessoas cometem. O membro de uma vinculação precisa do tipo na frente:

```
ana@laptop:~/gcp/wi$ sed -i 's#"serviceAccount:planner-dev.svc.id.goog#"planner-dev.svc.id.goog#' main.tf
ana@laptop:~/gcp/wi$ terraform validate -no-color

Error: invalid value "planner-dev.svc.id.goog[shop/photos]" for member (IAM members must have one of the values outlined here: https://cloud.google.com/billing/docs/reference/rest/v1/Policy#Binding)

  with google_service_account_iam_member.photos_pod,
  on main.tf line 24, in resource "google_service_account_iam_member" "photos_pod":
  24:   member             = "planner-dev.svc.id.goog[shop/photos]"
```

E um `account_id` precisa ter entre 6 e 30 caracteres:

```
ana@laptop:~/gcp/wi$ sed -i 's/"photos-reader"/"pr"/' main.tf
ana@laptop:~/gcp/wi$ terraform validate -no-color

Error: "account_id" ("pr") must be between 6 and 30 characters long

  with google_service_account.photos,
  on main.tf line 17, in resource "google_service_account" "photos":
  17:   account_id   = "pr"
```

## A outra metade, no cluster

O IAM agora permite que `[shop/photos]` aja como `photos-reader`, mas o pod ainda precisa dizer
qual conta de serviço do Google quer usar. Isso é uma anotação na conta de serviço do Kubernetes,
aplicada com `kubectl` a um cluster que este laboratório não tem. Ela vem da documentação do Google
e não foi executada:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: photos
  namespace: shop
  annotations:
    iam.gke.io/gcp-service-account: photos-reader@planner-dev.iam.gserviceaccount.com
```

Um Deployment cujos pods usam `serviceAccountName: photos` no namespace `shop` fica pronto. O código
lá dentro não faz nada de especial: as bibliotecas cliente do Google encontram as credenciais
sozinhas, do mesmo jeito que numa máquina virtual.
