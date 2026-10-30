---
title: O estado, num bucket só dele
version: 1
---

**O estado do Terraform é o único registro de qual objeto real é cada recurso dos arquivos**, e num
laptop ele é um arquivo chamado `terraform.tfstate` que ninguém mais vê. A lição 7 de `iac` o levou para um
backend remoto; no Google Cloud o backend é um bucket do Cloud Storage, pelo backend `gcs`, e o bucket é a
primeira coisa a criar, porque o estado de todo o resto vai morar nele.

Ele é criado por uma configuração própria, `bootstrap`, que guarda o próprio estado localmente e é
aplicada uma vez:

```hcl
# tf/bootstrap/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project                 = "planner-dev"
  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
}

resource "google_storage_bucket" "tfstate" {
  name                        = "planner-dev-tfstate"
  location                    = "SOUTHAMERICA-EAST1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 50
    }
    action {
      type = "Delete"
    }
  }
}
```

Três configurações fazem dele um bucket próprio para estado:

- **`versioning`**: cada escrita do estado guarda a anterior como versão não atual. É isso que torna
  sobrevivível o acidente mais adiante nesta lição, e é a configuração sem a qual um bucket de estado não
  pode ficar.
- **`public_access_prevention = "enforced"`**: o estado guarda cada atributo de cada recurso, muitas vezes
  incluindo strings de conexão e senhas geradas, então nada pode tornar este bucket público, quem quer que
  tente depois.
- **a regra de ciclo de vida** mantém as 50 versões mais novas e apaga as mais antigas, para o histórico não
  crescer para sempre. Cinquenta é mais ou menos um mês de applies da loja.

```
ana@laptop:~/gcp/tf/bootstrap$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket.tfstate: Creating...
google_storage_bucket.tfstate: Creation complete after 0s [id=planner-dev-tfstate]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## A configuração da loja, primeiro local

A configuração da loja gerencia uma lista de preços no bucket de assets e o tópico do Pub/Sub para onde vão
os pedidos. `pubsub_custom_endpoint` manda as chamadas de Pub/Sub do provider para o emulador do Google,
como `storage_custom_endpoint` faz para o Cloud Storage. Escreva-a em `~/gcp/tf/shop/main.tf`, substituindo
a da lição 5:

```hcl
# tf/shop/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project                 = "planner-dev"
  storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  pubsub_custom_endpoint  = "http://localhost:8085/v1/"
}

resource "google_storage_bucket_object" "prices" {
  bucket  = "planner-dev-shop-assets"
  name    = "prices.json"
  content = jsonencode({ notebook = 2490, pencil_case = 1890 })
}

resource "google_pubsub_topic" "orders" {
  name = "shop-orders"
}
```

O bucket de assets é criado antes com `gcloud storage buckets create gs://planner-dev-shop-assets
--location=southamerica-east1`. Aplicado sem backend, o estado é um arquivo ao lado da configuração:

```
ana@laptop:~/gcp/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket_object.prices: Creating...
google_pubsub_topic.orders: Creating...
google_storage_bucket_object.prices: Creation complete after 0s [id=planner-dev-shop-assets-prices.json]
google_pubsub_topic.orders: Creation complete after 0s [id=projects/planner-dev/topics/shop-orders]
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

## Levando o estado para o bucket

Acrescente o backend num arquivo próprio:

```hcl
# tf/shop/backend.tf
terraform {
  backend "gcs" {
    bucket                  = "planner-dev-tfstate"
    prefix                  = "shop"
    storage_custom_endpoint = "http://localhost:4443/storage/v1/"
  }
}
```

`prefix` é a pasta dentro do bucket. Um bucket guarda o estado de muitas configurações, cada uma sob o
próprio prefixo, então o prefixo é na prática o endereço da configuração, e duas configurações dividindo
um sobrescreveriam o estado uma da outra. `terraform init -migrate-state` copia o estado local para o
bucket:

```
ana@laptop:~/gcp/tf/shop$ terraform init -migrate-state -force-copy -input=false -no-color | grep -E "backend|Successfully|copy"
Initializing the backend...
Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
If you ever set or change modules or backend configuration for Terraform,
```

O estado agora é `shop/default.tfstate` no bucket (`default` é o workspace), e a cópia local pode ir
embora. **Deixá-la é como duas cópias da verdade começam a discordar.**

## Quem pode lê-lo

O bucket de estado ganha IAM próprio: `roles/storage.objectAdmin` para as contas de serviço que rodam o
Terraform, e para as pessoas que podem precisar consertá-lo, e nada para mais ninguém. Uma pessoa que lê o
estado lê cada segredo que o Terraform já escreveu nele, por isso a lição 12 de `iac` mantém segredos fora
dele e por isso este bucket não está no IAM de uso geral do projeto.
