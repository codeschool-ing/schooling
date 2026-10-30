---
title: Saída direta para a VPC
version: 1
---

**A saída direta para a VPC põe cada instância de uma revisão numa sub-rede da sua VPC, com um
endereço próprio tirado dessa sub-rede.** Não há máquina no meio, então não há nada para
dimensionar, atualizar ou pagar por hora; a conta traz o tráfego e mais nada. É o mecanismo que o
Google recomenda para serviços novos, e o primeiro a escolher.

## Escrevendo

Crie uma pasta `run-vpc` em `~/gcp` e salve isto como `main.tf` dentro dela. É o serviço orders
com as duas coisas que importam acrescentadas: um bloco `vpc_access` no modelo de revisão, e o
endereço do banco que o serviço recebe:

```hcl
# run-vpc/main.tf
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
    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
      env {
        name  = "DATABASE_HOST"
        value = "10.20.0.3"
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = "shop"
        subnetwork = "shop-run"
      }
    }
  }
}
```

Rode `terraform init` na pasta, como na lição 1, e depois o plan, filtrado no assunto desta seção:

```
ana@laptop:~/gcp/run-vpc$ terraform plan -no-color | grep -E '^  #|image|value|egress|network|^Plan'
  # google_cloud_run_v2_service.orders will be created
              + image      = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
                  + value = "10.20.0.3"
              + egress = "PRIVATE_RANGES_ONLY"
              + network_interfaces {
                  + network    = "shop"
                  + subnetwork = "shop-run"
Plan: 1 to add, 0 to change, 0 to destroy.
```

Leia o plan como a revisão que o Cloud Run montaria: uma imagem, uma variável de ambiente e uma
interface de rede em `shop-run`. A linha `egress` é assunto da seção 05; `PRIVATE_RANGES_ONLY`
manda para a VPC só os endereços privados e deixa todo o resto sair como sempre saiu.

## A sub-rede é um orçamento de endereços

A única coisa que a saída direta pede para você planejar é a sub-rede, porque **toda instância em
execução ocupa endereços nela.** Quando o serviço escala para fora, as instâncias novas pegam
endereços ao subir; quando ele escala para dentro, os endereços são liberados algum tempo depois de
as instâncias pararem, não no mesmo instante. Uma sub-rede que esgota não deixa o serviço lento.
As instâncias novas simplesmente não sobem, e o sintoma são requisições esperando capacidade
justamente no pico que precisava dela.

Então dimensione a sub-rede para o número máximo de instâncias do serviço, com folga, e dê ao
Cloud Run uma sub-rede só dele, em vez de dividir uma com máquinas virtuais cujos endereços você
também teria de contar. A documentação do Google traz os números atuais de quantos endereços uma
instância ocupa e por quanto tempo eles ficam retidos; leia-os para a versão contra a qual você
publica, porque já mudaram antes. A `shop-run` do laboratório é uma `/26`, 64 endereços, dos quais
o Google reserva quatro em toda sub-rede.

## O que o plan não diz

O Terraform aceitou `shop` e `shop-run` como nomes. **Se eles existem, se estão em
`southamerica-east1` e se têm endereços livres é verificado pelo Cloud Run quando ele cria a
revisão**, o mesmo limite que a lição 1 encontrou com tipos de máquina. Os comandos que mostrariam
isso são documentados e precisam de conta; neste laboratório eles param na falta de conta como
todo comando remoto do `gcloud`:

```sh
gcloud run services update orders --region=southamerica-east1 \
  --network=shop --subnet=shop-run --vpc-egress=private-ranges-only
gcloud compute networks subnets describe shop-run --region=southamerica-east1
```

Esses dois vêm da documentação do Google e não foram executados. O primeiro é como você
acrescentaria a saída direta a um serviço que já existe, o que cria uma revisão nova, igual à
mudança no Terraform.
