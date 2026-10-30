---
title: SSD local, rápido e temporário
version: 1
---

Todo disco até aqui chegava à máquina pela rede. **Um SSD local está fisicamente ligado ao host em
que a máquina roda, o que o torna muito mais rápido e faz o conteúdo dele pertencer ao host, não a
você.** Quando a máquina sai do host, os dados ficam para trás e são apagados.

## Para que serve

A velocidade vem de pular a rede, e o preço disso é a durabilidade. Trate um SSD local como espaço de
rascunho: um cache que pode ser reconstruído, os arquivos temporários de uma ordenação que transborda
para o disco, os resultados intermediários de um job em lote que pode recomeçar. **Nunca a única
cópia de nada.**

Ele vem em fatias fixas de **375 GiB**, anexadas quando a máquina é criada e nunca depois. Em séries
mais antigas, como a N2, você mesmo as acrescenta; nas mais novas as fatias vêm com o tipo de
máquina, e era isso que o sufixo `-lssd` da lição 1 queria dizer. Numa N2, numa pasta `scratch`:

```hcl
# scratch/main.tf
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

resource "google_compute_instance" "photos_worker" {
  name         = "photos-worker-1"
  machine_type = "n2-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/scratch$ terraform plan -no-color | grep -E '^  #|scratch_disk|^          \+ (interface|size) |^Plan'
  # google_compute_instance.photos_worker will be created
      + scratch_disk {
          + interface   = "NVME"
          + size        = 375
      + scratch_disk {
          + interface   = "NVME"
          + size        = 375
Plan: 1 to add, 0 to change, 0 to destroy.
```

Dois blocos, duas fatias, 750 GiB. A página de discos do Google cobra o SSD local a 0,08 por GiB-mês,
então uma fatia custa **30 dólares por mês** e estas duas, 60, cobrados enquanto a máquina existir,
haja ou não alguma coisa escrita nelas.

## Quando os dados sobrevivem, e quando não

A regra é sobre o host, e a documentação lista os casos:

| evento | os dados do SSD local |
|---|---|
| o sistema operacional reinicia | mantidos |
| migração ao vivo na manutenção do host | mantidos: os dados são copiados para o host novo |
| a máquina é parada ou suspensa | perdidos, a menos que você peça para preservá-los, onde a série permitir |
| a máquina é apagada | perdidos |
| o host falha, ou uma máquina Spot sofre preempção | perdidos |

A terceira linha é a que surpreende: **parar uma máquina para economizar esvazia o SSD local
dela.** Então um job que guarda estado num deles precisa escrever esse estado em algum lugar durável
antes de uma parada, e a lição 6 acrescenta a preempção, a parada que ninguém pede, à mesma lista.
