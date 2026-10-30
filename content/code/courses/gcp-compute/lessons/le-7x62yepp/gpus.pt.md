---
title: Máquinas com GPU
version: 1
---

Uma GPU não é um processador maior. **É um dispositivo separado, com preço separado, que só algumas
séries de máquina conseguem carregar e só algumas zonas conseguem fornecer.** Pedir uma se parece
menos com escolher um tamanho e mais com reservar um recurso escasso, e as regras em volta disso
decorrem daí.

## Dois jeitos de ter uma

O jeito mais novo é um tipo de máquina da família **otimizada para aceleradores**, em que a GPU faz
parte do tipo: `g2-standard-4` são quatro vCPUs, 16 GiB e uma NVIDIA L4, e não dá para ter a máquina
sem a GPU nem o contrário. As séries A2, A3 e G4 funcionam do mesmo jeito com GPUs maiores, até oito
por máquina.

O jeito mais antigo é uma máquina **N1** com uma GPU anexada, que o Terraform escreve como um bloco
`guest_accelerator`. Ele deixa escolher a GPU e a máquina separadamente, e é assim que GPUs mais
baratas e mais antigas, como a NVIDIA T4, ainda são oferecidas. Numa pasta `gpu`:

```hcl
# gpu/main.tf
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

resource "google_compute_instance" "infer" {
  name         = "infer-1"
  machine_type = "g2-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}

resource "google_compute_instance" "train" {
  name         = "train-1"
  machine_type = "n1-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  guest_accelerator {
    type  = "nvidia-tesla-t4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}
```

```
ana@laptop:~/gcp/gpu$ terraform plan -no-color | grep -E '^  #|machine_type|on_host_maintenance|^          \+ (count|type) |^Plan'
  # google_compute_instance.infer will be created
      + machine_type         = "g2-standard-4"
          + on_host_maintenance = "TERMINATE"
  # google_compute_instance.train will be created
      + machine_type         = "n1-standard-4"
          + count = 1
          + type  = "nvidia-tesla-t4"
          + on_host_maintenance = "TERMINATE"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## Por que `TERMINATE`

O Compute Engine move máquinas comuns para outro host enquanto faz manutenção no primeiro, uma
**migração ao vivo** que a máquina mal percebe. Uma GPU é uma placa física num host, e a memória dela
não se move com a máquina. Então uma máquina com GPU precisa **parar na manutenção do host**, e o
Google exige `on_host_maintenance = "TERMINATE"` nela. O plan acima aceitou a configuração; também
teria aceitado `MIGRATE`, e a recusa viria do Compute Engine na criação, o mesmo limite que a lição 1
encontrou com um tipo de máquina que não existia.

A opção documentada do gcloud diz qual é o padrão, e a ajuda funciona sem conta:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --maintenance-policy/,/^     --max-run/p'
     --maintenance-policy=MAINTENANCE_POLICY
        Specifies the behavior of the VMs when their host machines undergo
        maintenance. The default is MIGRATE. For more information, see
        https://cloud.google.com/compute/docs/instances/host-maintenance-options.
        MAINTENANCE_POLICY must be one of:

         MIGRATE
            The instances should be migrated to a new host. This will
            temporarily impact the performance of instances during a migration
            event.
         TERMINATE
            The instances should be terminated.

     --max-run-duration=MAX_RUN_DURATION
```

O que `TERMINATE` significa para o software é o mesmo que a lição 6 significa para máquinas Spot: a
máquina é parada de fora, com aviso, e o trabalho nela precisa ser escrito para sobreviver a isso.

## Quanto custa uma, e os outros dois obstáculos

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "per hour|e2-standard-2|g2-standard-4"
                                    per hour   per month   Spot/hour
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  g2-standard-4   4 vCPU  16 GiB   0.706832276      515.99           -
```

**516 dólares por mês por uma `g2-standard-4` deixada ligada**, dez vezes a `e2-standard-2` ao lado,
e é por isso que uma máquina com GPU é a que mais vale parar quando está ociosa. A T4 numa N1 é mais
barata por hora: a página de GPUs do Google a listava a 0,35 dólar por hora por GPU em Iowa em 30 de
outubro de 2026, além da própria máquina N1.

Dois obstáculos vêm antes do preço, e nenhum deles se vê deste laboratório:

- **Nem toda zona tem toda GPU.** Cada zona oferece uma lista de tipos de acelerador, e um tipo que
  falte nela é recusado na criação. `gcloud compute accelerator-types list
  --filter="zone:southamerica-east1-a"` é a pergunta a fazer, com uma conta.
- **A cota de GPU de um projeto novo é zero na maioria das regiões.** A cota é um pedido separado,
  analisado pelo Google, e vale a pena fazê-lo dias antes de a máquina ser necessária, não na tarde
  em que ela for.
