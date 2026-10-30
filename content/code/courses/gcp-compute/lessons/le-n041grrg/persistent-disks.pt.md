---
title: Discos persistentes, zonais e regionais
version: 1
---

A imagem errada mais comum de um disco na nuvem é um drive dentro do servidor. **Um disco
persistente é armazenamento na rede do Google, ligado à máquina por essa rede, e ele sobrevive à
máquina a que está ligado.** Apague a máquina e o disco pode ficar; pare a máquina e o disco guarda
tudo; ligue-o a outra máquina e os dados vão junto.

## Quatro tipos, uma pergunta

O tipo decide quão rápido é o disco e quanto custa cada gigabyte, e a tabela de preços da lição 1
lista os tipos:

```
ana@laptop:~/gcp$ python3 prices.py disks | head -7
Google Cloud public prices, us-central1, USD, 30 October 2026

Disks and images, per GiB per month
  pd-standard, after the free 30 GiB                    0.04  per GiB-month
  pd-balanced                                            0.1  per GiB-month
  pd-ssd                                                0.17  per GiB-month
  pd-balanced, regional                                  0.2  per GiB-month
```

| tipo | para que serve |
|---|---|
| `pd-standard` | apoiado em discos rígidos: logs, backups, dados lidos em sequências longas |
| `pd-balanced` | SSD a preço moderado: o padrão para discos de boot e para a maioria dos dados |
| `pd-ssd` | SSD com mais operações por segundo por GiB: bancos de dados ocupados |
| `pd-extreme` | SSD cujas operações você provisiona à parte: os maiores bancos de dados |

**O desempenho de um disco persistente cresce com o tamanho.** Cada tipo promete um número de
operações por segundo e uma vazão por GiB, até um teto, então um `pd-ssd` pequeno pode ser mais lento
que um `pd-balanced` grande. A máquina impõe tetos próprios, por série e número de vCPUs, e o disco
fica com o menor dos dois. É por isso que "o banco está lento, dá um disco mais rápido para ele" às
vezes não resolve nada: o limite era da máquina.

## Um disco próprio

Um disco de boot vem com a máquina. Um disco de dados é um recurso à parte, criado separadamente e
anexado, e é isso que o deixa sobreviver à máquina. Para o serviço `orders` da loja, numa pasta
`disks`:

```hcl
# disks/main.tf
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

resource "google_compute_disk" "orders_data" {
  name = "orders-data"
  type = "pd-balanced"
  zone = "southamerica-east1-a"
  size = 100
}

resource "google_compute_region_disk" "orders_ha" {
  name          = "orders-ha"
  type          = "pd-balanced"
  region        = "southamerica-east1"
  replica_zones = ["southamerica-east1-a", "southamerica-east1-b"]
  size          = 100
}

resource "google_compute_instance" "orders" {
  name         = "orders-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  attached_disk {
    source      = google_compute_disk.orders_data.id
    device_name = "orders-data"
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/disks$ terraform plan -no-color | grep -E '^  #|^      \+ (type|size) |device_name += "|^Plan'
  # google_compute_disk.orders_data will be created
      + size                           = 100
      + type                           = "pd-balanced"
  # google_compute_instance.orders will be created
          + device_name                = "orders-data"
  # google_compute_region_disk.orders_ha will be created
      + size                           = 100
      + type                           = "pd-balanced"
Plan: 3 to add, 0 to change, 0 to destroy.
```

`device_name` é o nome que o disco tem dentro da máquina: o Debian o mostra como
`/dev/disk/by-id/google-orders-data`, que é o caminho a pôr no `/etc/fstab`, porque `/dev/sdb` pode
mudar entre boots e o nome by-id não muda. O disco chega vazio e sem formatação; criar um sistema de
arquivos nele é um passo dentro da máquina, que o script de inicialização da lição 7 pode fazer.

## Zonal ou regional

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas zonas de southamerica-east1 lado a lado. Na zona a, a máquina orders-1 escreve no disco regional orders-ha, e cada escrita é copiada para a réplica na zona b. Na zona b uma segunda máquina, tracejada, pode anexar a réplica e continuar se a zona a cair. Um disco zonal, orders-data, fica sozinho na zona a.\"><defs><marker id=\"l3r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"370\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">southamerica-east1-a</text><text x=\"386\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">southamerica-east1-b</text><rect x=\"60\" y=\"66\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-1</text><text x=\"140.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">máquina</text><rect x=\"60\" y=\"150\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-ha</text><text x=\"140.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">disco regional</text><rect x=\"410\" y=\"150\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-ha</text><text x=\"490.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">réplica</text><rect x=\"410\" y=\"66\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reserva</text><text x=\"490.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">se a zona a cair</text><rect x=\"60\" y=\"222\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-data</text><text x=\"234\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zonal: só na zona a</text><path d=\"M140 110 L140 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3r-ah)\"></path><path d=\"M220 175 L408 175\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3r-ah)\"></path><text x=\"314\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cada escrita</text><path d=\"M490 148 L490 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3r-ah)\"></path></svg>", "caption": "Um disco regional grava cada bloco em duas zonas antes de confirmar a escrita. Um disco zonal mora numa zona só e fica indisponível enquanto ela estiver."}
```

Um disco zonal mora numa zona, e **uma zona que cai leva os seus discos zonais junto** até voltar.
Um **disco regional** grava cada bloco em duas zonas de forma síncrona, então uma máquina na outra
zona pode anexá-lo e seguir em frente. Esse é o segundo recurso do arquivo, e o preço dele é o preço
dessa garantia: 0,2 por GiB-mês contra 0,1, porque cada byte fica guardado duas vezes. As escritas
também demoram um pouco mais, já que cada uma é confirmada em dois lugares.

Use um onde os dados são o que não pode ser perdido e o serviço não pode esperar uma zona se
recuperar: o disco embaixo de um banco de dados que não tem réplica própria. Onde a aplicação já
guarda cópias, um banco gerenciado ou um grupo de máquinas sem estado, um disco regional paga duas
vezes por algo que já existe.
