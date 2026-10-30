---
title: Escala a zero, e o que publicar exigiria
version: 1
---

Quando ninguém está pedindo, um serviço do Cloud Run **não tem instância nenhuma**, e não custa
nada de computação. Quando chega uma requisição, o Cloud Run inicia uma instância a partir da
imagem, espera ela escutar e entrega a requisição. **Essa primeira requisição paga pela partida, e
nenhuma das seguintes paga até a instância ficar ociosa.** Esta seção é esse ciclo, e a descrição
do serviço que o Terraform mandaria para torná-lo real.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de um serviço. No começo não há instâncias. Uma requisição chega e espera enquanto uma instância inicia: a imagem é baixada, o contêiner sobe e começa a escutar; essa espera é a partida a frio. A instância então atende esta requisição e as seguintes. Quando as requisições param, ela fica ociosa um tempo, até uns quinze minutos, e depois é desligada com SIGTERM, voltando a nenhuma instância.\"><defs><marker id=\"l8z-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sem instâncias</text><rect x=\"150\" y=\"90\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"235.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">iniciando</text><rect x=\"330\" y=\"90\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">atendendo</text><rect x=\"510\" y=\"90\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">ociosa</text><path d=\"M140 115 L150 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M320 115 L330 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M500 115 L510 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><path d=\"M165 40 L165 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8z-ah)\"></path><text x=\"165\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chega a primeira requisição</text><text x=\"235\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">baixar, subir, escutar</text><text x=\"235\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a partida a frio</text><text x=\"415\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esta requisição e as seguintes</text><text x=\"605\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">até uns 15 minutos</text><path d=\"M605 196 L70 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l8z-ah)\"></path><text x=\"340\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SIGTERM, e de volta a nenhuma instância</text></svg>", "caption": "Só a primeira requisição depois de um período quieto paga pela partida. Quanto dura o estado ocioso é decisão do Google, e sem mínimo definido ele não custa nada."}
```

## O ciclo, em quatro estados

**Sem instâncias.** O serviço existe, tem endereço, e ainda não atende nada. Uma requisição que
chega agora fica segurada pelo front end do Cloud Run enquanto uma instância sobe.

**Iniciando.** O Cloud Run baixa a imagem, sobe o contêiner e espera a sondagem de inicialização,
por padrão uma conexão TCP ao `PORT`. O tempo da requisição até o primeiro byte aqui é a **partida
a frio**, a soma do download, da subida do runtime e do que quer que o seu programa faça antes de
escutar. A lição 11 a desmonta.

**Atendendo.** A instância responde esta requisição e as outras que chegarem, várias ao mesmo tempo
se a concorrência permitir. Mais instâncias sobem quando as que estão rodando enchem.

**Ociosa.** Quando as requisições param, a instância não é parada na hora. A documentação do Google
diz que uma instância ociosa pode ser mantida por até quinze minutos, para a próxima requisição a
encontrar quente, e depois é desligada com o `SIGTERM` da seção anterior. Com cobrança por
requisição, uma instância ociosa sem mínimo definido não custa nada enquanto espera; os preços da
tabela estão na lição 11.

**Um número mínimo de instâncias** muda o primeiro estado: com `min_instance_count = 1`, uma
instância está sempre lá e a primeira requisição da manhã a encontra quente. Essa instância é
cobrada enquanto ociosa, pela taxa de ociosidade que a tabela de preços lista, e a lição 11 calcula
quando ela compensa.

## O serviço, por escrito

Salve isto como `cloudrun/main.tf` em `~/gcp`:

```hcl
# cloudrun/main.tf
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

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }
}
```

Depois, em `~/gcp/cloudrun`, rode `terraform init` como na lição 1, e o plan:

```
ana@laptop:~/gcp/cloudrun$ terraform plan -no-color | grep -E '^  #|^      \+ (name|location|ingress) |image|min_instance|max_instance|cpu|memory|container_port|^Plan'
  # google_cloud_run_v2_service.orders will be created
      + ingress                 = "INGRESS_TRAFFIC_ALL"
      + location                = "southamerica-east1"
      + name                    = "orders"
          + max_instance_request_concurrency = (known after apply)
              + image      = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"
                  + container_port = 8080
                      + "cpu"    = "1"
                      + "memory" = "512Mi"
              + max_instance_count = 10
              + min_instance_count = 0
Plan: 1 to add, 0 to change, 0 to destroy.
```

Cada linha é uma decisão desta lição. **A imagem é nomeada pelo caminho no Artifact Registry**, que
a lição 21 explica, porque o Cloud Run não baixa nada do seu laptop. `container_port` é o `PORT`
que o contêiner vai receber. Uma vCPU e 512 MiB é o tamanho de cada instância, e a unidade de todo
preço. `min_instance_count = 0` é a escala a zero, e `max_instance_count = 10` é um teto para
quantas instâncias uma rajada de tráfego, ou um ataque, consegue fazer você pagar. A configuração
de ingress deixa qualquer um na internet alcançar o endereço; a lição 12 a estreita. E uma linha
que o arquivo nunca menciona, `max_instance_request_concurrency`, fica para o Cloud Run preencher:
quantas requisições uma instância aceita ao mesmo tempo, assunto da lição 11.

## O que publicar exige, e por que não acontece aqui

O mesmo serviço pode ser publicado com o gcloud num comando só, que neste laboratório para onde
todo comando remoto para:

```
ana@laptop:~/gcp/cloudrun$ gcloud run deploy orders --image=southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1 --region=southamerica-east1
ERROR: (gcloud.run.deploy) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

Com uma conta, esse comando pediria a imagem no Artifact Registry, criaria o serviço e a primeira
revisão, e imprimiria um endereço terminado em `run.app`. **Nada disso pode ser mostrado aqui, e
nada disso é inventado**: nenhum endereço, nenhum nome de revisão, nenhum tempo. O que o
laboratório mostra é a parte que decide se uma publicação funciona, o contêiner cumprindo o
contrato, e a descrição do serviço, que é o que o Terraform mandaria. A lição 9 continua com as
revisões que toda publicação cria.
