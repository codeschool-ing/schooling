---
title: Aplicando, o que uma imitação não guarda, e as APIs que um projeto precisa ligar
version: 1
---

Com o token no lugar, o apply cria o bucket no `fake-gcs-server`, e o `gcloud` o lê de volta:

```
ana@laptop:~/gcp/tf/shop$ terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"
google_storage_bucket.assets: Creating...
google_storage_bucket.assets: Creation complete after 1s [id=planner-dev-shop-assets]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/gcp/tf/shop$ gcloud storage buckets describe gs://planner-dev-shop-assets --format='yaml(name,labels,location)'
location: US-CENTRAL1
name: planner-dev-shop-assets
```

**O bucket existe, e não é o bucket que foi pedido.** Ele não tem rótulos, e a localização é
`US-CENTRAL1`, não São Paulo. O `fake-gcs-server` guarda o nome de um bucket e os objetos dele, e responde
qualquer outra pergunta com um padrão: nunca guardou os três rótulos que o plano mostrou, nem a
localização. O Google guarda os dois. Este é o exemplo mais claro do curso daquilo que a lição 1 avisou: o
pedido estava bem formado e foi aceito, e isso não prova nada sobre o que o serviço real teria feito com
ele.

Peça agora um plano ao Terraform, sem mudar nada no arquivo:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  #|forces replacement|Plan:"
  # google_storage_bucket.assets must be replaced
      ~ location                    = "US-CENTRAL1" -> "SOUTHAMERICA-EAST1" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

O Terraform atualizou o bucket, leu de volta `US-CENTRAL1` e comparou com o arquivo. **A localização de
um bucket não pode ser mudada**, então a única forma de fazer a realidade bater com o arquivo é destruir o
bucket e criá-lo de novo, com tudo o que tem dentro. É isso que `# forces replacement` significa, e é a
linha de um plano que merece a leitura mais lenta: contra o Google, este plano apagaria cada objeto do
bucket. Aqui é um efeito da imitação; num projeto real a mesma linha aparece quando alguém muda uma
localização ou um nome no arquivo, e a lição 6 é sobre o dia em que essa linha é aplicada por engano.

## Todo serviço é uma API, e uma API fica desligada até ser ligada

Um projeto novo do Google Cloud tem quase todas as APIs desligadas. Criar um serviço do Cloud Run num
projeto onde `run.googleapis.com` está desligada falha com `SERVICE_DISABLED`, sejam quais forem as
permissões de quem chama. Então uma configuração que cria recursos costuma começar ligando as APIs de que
eles precisam, como recursos próprios:

```hcl
# tf/apis/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}
```

```
ana@laptop:~/gcp/tf/apis$ terraform plan -input=false -no-color | grep -E "^  # |Plan:"
  # google_project_service.artifactregistry will be created
  # google_project_service.run will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

O plano foi calculado e nada mais: o `fake-gcs-server` não conhece APIs, então aplicá-lo mandaria o pedido
ao Google, com um token que o Google recusa. **`disable_on_destroy = false` é a linha a manter.** Sem ela,
`terraform destroy` nesta configuração desliga a API para o projeto inteiro, e todo serviço que a usa para,
inclusive os que esta configuração nunca criou.

Ligar uma API também leva um ou dois minutos para chegar a todas as partes do Google, então um recurso
criado no mesmo apply às vezes falha na primeira vez e funciona na segunda. Um `depends_on` do recurso para
o seu `google_project_service` deixa a ordem explícita, e uma nova tentativa ainda é às vezes necessária.
