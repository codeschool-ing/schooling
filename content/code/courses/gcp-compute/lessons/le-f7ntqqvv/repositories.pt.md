---
title: Repositórios, e o endereço em que uma imagem mora
version: 1
---

Todo produto de computação deste curso roda uma imagem que vem de algum lugar: o Cloud Run, os jobs
dele, o GKE, o build de uma função. **No Google Cloud esse lugar é o Artifact Registry, e o endereço
da imagem diz onde ela está guardada, qual projeto é dono dela e qual repositório a contém.** O
Container Registry, o antigo serviço `gcr.io`, foi substituído por ele, e endereços `gcr.io` em
projetos novos são atendidos pelo Artifact Registry por trás.

## Lendo um endereço

Um endereço completo de imagem no Artifact Registry tem cinco partes:

| parte | no endereço da loja | o que é |
|---|---|---|
| host | `southamerica-east1-docker.pkg.dev` | a região, depois o formato |
| projeto | `planner-dev` | quem é dono e quem paga |
| repositório | `shop` | um contêiner com as próprias permissões e políticas |
| imagem | `web` | um nome dentro do repositório |
| tag ou digest | `:1.4.0` ou `@sha256:…` | qual versão da imagem |

Então `southamerica-east1-docker.pkg.dev/planner-dev/shop/web:1.4.0` se lê da esquerda para a
direita como um caminho. **A região faz parte do host**, e isso é uma decisão com custo: um serviço
do Cloud Run em São Paulo puxando de um repositório em São Paulo puxa dentro da região, enquanto o
mesmo serviço puxando de um repositório em outra região paga pelos dados que cruzam entre elas e
espera por eles a cada partida a frio.

## O que um repositório decide

Um repositório é criado com um **formato**, `DOCKER` aqui, mas também Maven, npm, Python, apt, yum
e Go, então um produto só guarda as imagens de contêiner de uma empresa e as bibliotecas dela. E ele
tem um **modo**:

- **standard**, o padrão: você faz push nele e ele guarda o que recebe;
- **remote**: um cache na frente de uma origem como o Docker Hub ou o PyPI, que busca no primeiro
  pull e serve a cópia depois, para um build continuar funcionando quando a origem limita ou cai;
- **virtual**: um endereço na frente de vários repositórios, consultados numa ordem que você
  define.

As permissões são dadas no repositório, e é por isso que as imagens da loja e as bibliotecas dela
costumam morar em repositórios diferentes, mesmo quando as mesmas pessoas usam os dois.

## O repositório, por escrito

**Crie `~/gcp/registry` e salve isto como `main.tf`:**

```hcl
# registry/main.tf
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

resource "google_artifact_registry_repository" "shop" {
  repository_id = "shop"
  location      = "southamerica-east1"
  format        = "DOCKER"
  description   = "Container images of the shop"
}
```

Depois `terraform init` e o plan:

```
ana@laptop:~/gcp/registry$ terraform plan -no-color | grep -E '^  #|repository_id|format|mode +=|location|^Plan'
  # google_artifact_registry_repository.shop will be created
      + format           = "DOCKER"
      + location         = "southamerica-east1"
      + mode             = "STANDARD_REPOSITORY"
      + repository_id    = "shop"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**O `mode` saiu como `STANDARD_REPOSITORY`** sem ter sido escrito, que é o padrão que o provider
preenche. O plan não diz nada sobre quem pode fazer push ou pull; isso é uma ligação de IAM no
repositório, `roles/artifactregistry.writer` para quem faz o build e
`roles/artifactregistry.reader` para o que roda, e o `gcp-foundations` mostra como se escrevem
essas ligações.

## O que custa

```
ana@laptop:~/gcp$ python3 prices.py other | grep 'Artifact Registry'
  Artifact Registry, after the free 0.5 GiB              0.1  per GiB-month
```

Dez centavos por GiB por mês, depois do primeiro meio GiB, e a imagem `web` da loja é quase toda a
base Python sobre a qual foi construída. Armazenamento raramente é a parte cara de um registry;
**dados saindo da região são**, mais um motivo para manter o repositório ao lado dos serviços que
puxam dele.
