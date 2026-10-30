---
title: Hyperdisk, onde o desempenho é comprado à parte
version: 1
---

Um disco persistente amarra a velocidade ao tamanho, então o jeito de deixá-lo mais rápido é
deixá-lo maior e pagar por espaço que talvez você nunca encha. **O Hyperdisk separa as três coisas
que um disco vende: capacidade, operações por segundo e vazão são provisionadas e cobradas cada uma
por si.** As séries de máquina mais novas, N4 e C4 entre elas, só anexam Hyperdisk, e é por isso que
a lição 1 o mencionou.

## O que o Hyperdisk Balanced cobra

A página de discos do Google cobra o Hyperdisk Balanced em três partes, e declara uma base que vem
com todo disco sem custo extra: **3.000 IOPS e 140 MBps**. Só o que você provisiona acima disso é
cobrado. Em Iowa, em 30 de outubro de 2026, a página listava:

| parte | preço por hora | por mês de 730 horas |
|---|---|---|
| capacidade | 0,000109589 por GiB | 0,08 por GiB |
| IOPS acima de 3.000 | 0,000006849 por IOPS | cerca de 0,005 por IOPS |
| vazão acima de 140 MBps | 0,000054795 por MBps | cerca de 0,04 por MBps |

Então um disco de 100 GiB na base custa 8 dólares por mês, menos que um `pd-balanced` do mesmo
tamanho. Suba para 6.000 IOPS e 290 MBps para um banco de dados, e os 3.000 IOPS extras somam cerca
de 15 dólares e os 150 MBps extras cerca de 6, **29 dólares no total**, por um desempenho que um disco
persistente só alcançaria sendo várias vezes maior.

## Escrevendo um

Para o banco do `orders` numa máquina N4, numa pasta `hyperdisk`:

```hcl
# hyperdisk/main.tf
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

resource "google_compute_disk" "orders_db" {
  name                   = "orders-db"
  type                   = "hyperdisk-balanced"
  zone                   = "southamerica-east1-a"
  size                   = 100
  provisioned_iops       = 6000
  provisioned_throughput = 290
}

resource "google_compute_instance" "orders_db" {
  name         = "orders-db-1"
  machine_type = "n4-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      type  = "hyperdisk-balanced"
    }
  }

  attached_disk {
    source = google_compute_disk.orders_db.id
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/hyperdisk$ terraform plan -no-color | grep -E '^  #|provisioned_|^              \+ type|^Plan'
  # google_compute_disk.orders_db will be created
      + provisioned_iops               = 6000
      + provisioned_throughput         = 290
  # google_compute_instance.orders_db will be created
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + type                   = "hyperdisk-balanced"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**O disco de boot também precisa ser Hyperdisk.** Uma N4 não sobe a partir de um disco persistente,
e o plan não tem como saber disso: troque `hyperdisk-balanced` por `pd-balanced` em qualquer um dos
discos e ele planeja do mesmo jeito. A recusa viria do Compute Engine na criação, o mesmo limite que
as lições 1 e 2 encontraram.

## Mudando depois

Os números do Hyperdisk podem ser mudados num disco em uso, para cima e para baixo dentro de
limites, e o Google espaça essas mudanças: a documentação permite uma mudança no desempenho
provisionado a cada algumas horas por disco. Isso transforma um problema de desempenho de migração
em edição: suba os IOPS antes do relatório do fim do mês, baixe depois, e pague pelo número maior só
enquanto ele valeu. Com um disco persistente a mesma necessidade vira um disco maior, e um disco não
encolhe.
