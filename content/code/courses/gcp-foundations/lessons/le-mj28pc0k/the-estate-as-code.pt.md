---
title: A árvore, escrita e planejada
version: 1
---

A hierarquia não pode ser rodada no laboratório, mas pode ser **escrita com exatidão** e conferida
contra tudo que o provider do Google para o Terraform sabe sobre ela. Isso vale mais do que parece: a
árvore de uma empresa costuma ser criada no clique, e um ano depois ninguém sabe dizer por que uma pasta
existe. Um arquivo diz, e um plano diz se o arquivo faz sentido antes de alguém pedir qualquer coisa ao
Google.

## Um arquivo de que toda lição de Terraform parte

O Terraform precisa saber que provider usar e como alcançá-lo. Crie um diretório para esta lição e
escreva o arquivo que toda lição seguinte copia:

```sh
mkdir -p ~/gcp/hierarchy && cd ~/gcp/hierarchy
```

Salve isto como `provider.tf`:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.7.0"
    }
  }
}

# The lab's provider: the project and region every lesson uses, and the same
# placeholder token gcloud sends. A plan asks Google nothing; an apply would
# send this token and be refused.
provider "google" {
  project      = "planner-dev"
  region       = "southamerica-east1"
  access_token = "placeholder"
}
```

O `version = "8.7.0"` fixa exatamente o provider do Google, a versão com que todo plano deste curso
foi feito. O `access_token` é o placeholder de novo, escrito no arquivo em vez de lido do
`~/gcp/placeholder-token`, para que o arquivo diga de cara que não guarda segredo nenhum.

## A árvore

Salve isto como `hierarchy.tf`. É o ambiente da figura da primeira seção, escrito como três pastas e
cinco projetos:

```hcl
locals {
  org = "organizations/123456789012" # example.com, made up for this course
}

resource "google_folder" "production" {
  display_name = "production"
  parent       = local.org
}

resource "google_folder" "non_production" {
  display_name = "non-production"
  parent       = local.org
}

resource "google_folder" "shared" {
  display_name = "shared"
  parent       = local.org
}

resource "google_project" "prod" {
  name       = "Planner production"
  project_id = "planner-prod"
  folder_id  = google_folder.production.folder_id
}

resource "google_project" "staging" {
  name       = "Planner staging"
  project_id = "planner-staging"
  folder_id  = google_folder.non_production.folder_id
}

resource "google_project" "dev" {
  name       = "Planner development"
  project_id = "planner-dev"
  folder_id  = google_folder.non_production.folder_id
}

resource "google_project" "network" {
  name       = "Shared network"
  project_id = "planner-network"
  folder_id  = google_folder.shared.folder_id
}

resource "google_project" "logs" {
  name       = "Logs"
  project_id = "planner-logs"
  folder_id  = google_folder.shared.folder_id
}
```

**Um projeto nomeia a sua pasta por referência, nunca por número.** O
`google_folder.production.folder_id` é um valor que o Google inventa quando a pasta é criada; escrito
como referência, o Terraform sabe que deve criar a pasta primeiro e preencher o número que receber de
volta.

## Init, validate, plan

O `terraform init` baixa o provider para o cache que o `env.sh` nomeou, uma vez; todo diretório seguinte
o encontra lá. O `terraform validate` confere os arquivos contra o esquema do provider. O
`terraform plan` diz o que o Terraform pediria ao Google:

```
ana@laptop:~/gcp/hierarchy$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "8.7.0"...
- Installing hashicorp/google v8.7.0...
- Installed hashicorp/google v8.7.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/gcp/hierarchy$ terraform validate
Success! The configuration is valid.

ana@laptop:~/gcp/hierarchy$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:'
  # google_folder.non_production will be created
  # google_folder.production will be created
  # google_folder.shared will be created
  # google_project.dev will be created
  # google_project.logs will be created
  # google_project.network will be created
  # google_project.prod will be created
  # google_project.staging will be created
Plan: 8 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/hierarchy$ terraform plan -input=false -no-color -target=google_project.dev | sed -n "/# google_project.dev/,/^    }/p"
  # google_project.dev will be created
  + resource "google_project" "dev" {
      + auto_create_network = true
      + deletion_policy     = "PREVENT"
      + effective_labels    = {
          + "goog-terraform-provisioned" = "true"
        }
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "Planner development"
      + number              = (known after apply)
      + project_id          = "planner-dev"
      + terraform_labels    = {
          + "goog-terraform-provisioned" = "true"
        }
    }
```

**Oito recursos a adicionar, e todo número que o Google escolheria é `(known after apply)`**: os números
das pastas, os números dos projetos, a pasta em que cada projeto vai parar. O plano conhece a forma e
nenhuma das identidades, que é exatamente o que dá para saber sem perguntar. O segundo plano, estreitado
a um projeto com `-target`, mostra três valores que ninguém escreveu: `deletion_policy = "PREVENT"`, que
a lição 3 explica; um rótulo `goog-terraform-provisioned`, que o provider põe em tudo que cria para que
um recurso diga quem o fez; e `auto_create_network = true`, uma rede que o Google criaria no projeto novo
a não ser que lhe dissessem o contrário, e que a lição 15 desmonta.

## O que o plano não pode saber

**Este plano seria recusado se fosse aplicado**, e não só porque o token é um placeholder. Criar uma
pasta exige o papel `resourcemanager.folderCreator` na organização, criar um projeto exige
`resourcemanager.projectCreator` na pasta, e `organizations/123456789012` não é uma organização de
ninguém neste curso. Um plano confere a descrição; se quem pede pode fazer o pedido é decidido pelo
Google, no momento do pedido, e esse é o assunto das lições 5 a 9.
