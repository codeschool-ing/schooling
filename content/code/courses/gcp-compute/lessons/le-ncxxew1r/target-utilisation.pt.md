---
title: Escalando para uma utilização alvo
version: 1
---

A lição 4 deixou o grupo defendendo um número que alguém digitou. **Um autoscaler troca esse número
por uma regra: manter um sinal medido perto de uma meta, e deixar o tamanho do grupo ser o que for
preciso para isso.** O sinal mais comum é a CPU, e a regra é simples o bastante para fazer à mão, que
é o melhor jeito de confiar nela.

## A conta que o autoscaler faz

A documentação do Google descreve a regra de CPU sem rodeios: o autoscaler soma quão ocupadas estão
as máquinas, divide pela meta e arredonda para cima. Um grupo de quatro máquinas rodando a 90%, 85%,
95% e 80% da CPU, com meta de 60%, está carregando 3,5 máquinas de trabalho, e 3,5 dividido por 0,6
dá 5,83, então ele quer seis máquinas. Eis essa regra como um programa curto; salve como
`~/gcp/recommend.py`:

```python
# recommend.py
import math
import sys

target = float(sys.argv[1])
busy = [float(x) for x in sys.argv[2:]]

work = sum(busy)
print(f'{len(busy)} machines, {work:.2f} machines of work, target {target:.0%}')
print(f'recommended size: {math.ceil(work / target)}')
```

```
ana@laptop:~/gcp$ python3 recommend.py 0.6 0.9 0.85 0.95 0.8
4 machines, 3.50 machines of work, target 60%
recommended size: 6
ana@laptop:~/gcp$ python3 recommend.py 0.6 0.2 0.2 0.2 0.2
4 machines, 0.80 machines of work, target 60%
recommended size: 2
```

As duas execuções dizem a mesma coisa por dois lados. Máquinas ocupadas e uma meta baixa fazem o
grupo crescer; o mesmo grupo a 20% cada o faz encolher para dois, porque duas máquinas a 40% cada
dariam conta do trabalho abaixo da meta. **A meta é a folga que você guarda**: a 60%, cada máquina tem
40% sobrando para o minuto que leva para acrescentar mais. Uma meta de 90% é mais barata e não deixa
espaço para um pico; uma meta de 30% paga para duas de cada três máquinas ficarem paradas.

## Escrevendo

Um autoscaler é um recurso ligado a um grupo. Numa pasta `autoscale`, um grupo mínimo e o autoscaler
ao lado dele:

```hcl
# autoscale/main.tf
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

resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "debian-cloud/debian-12"
    boot         = true
  }

  network_interface {
    network = "default"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name               = "web"
  base_instance_name = "web"
  region             = "southamerica-east1"

  version {
    instance_template = google_compute_instance_template.web.id
  }
}

resource "google_compute_region_autoscaler" "web" {
  name   = "web"
  region = "southamerica-east1"
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = 3
    max_replicas    = 12
    cooldown_period = 90

    cpu_utilization {
      target = 0.6
    }
  }
}
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E '^  #|_replicas|cooldown_period|^          \+ target|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_autoscaler.web will be created
          + cooldown_period = 90
          + max_replicas    = 12
          + min_replicas    = 3
  # google_compute_region_instance_group_manager.web will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**O grupo não tem mais `target_size`.** Com um autoscaler ligado, é ele que define o tamanho, e um
número no próprio recurso do grupo só brigaria com ele a cada `terraform apply`. `min_replicas` é o
piso que o autoscaler nunca fura, três aqui para uma máquina por zona sobreviver à noite mais calma, e
`max_replicas` é o teto que impede um bug ou um ataque de criar uma conta de cem máquinas.

A meta é uma fração, e a ajuda do gcloud diz em que faixa ela precisa estar. O plan não verifica:
`target = 1.5` planeja tão limpo quanto `0.6`, e o Compute Engine recusa quando o autoscaler é
criado.

```
ana@laptop:~/gcp/autoscale$ gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --target-cpu-utilization/,/^$/p'
     --target-cpu-utilization=TARGET_CPU_UTILIZATION
        Autoscaler aims to maintain CPU utilization at target level (0.0 to
        1.0).
```
