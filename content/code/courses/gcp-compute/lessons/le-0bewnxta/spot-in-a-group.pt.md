---
title: Máquinas Spot num grupo
version: 1
---

Uma máquina Spot avulsa que é retomada fica parada até alguém agir. **Um grupo gerenciado de
máquinas Spot se cura sozinho: uma máquina retomada é recriada a partir do template assim que houver
capacidade, e a meta do grupo é defendida exatamente como a lição 4 descreveu.** Isso faz de um grupo a
casa natural das máquinas Spot, e também faz fácil esquecer o que ainda pode dar errado.

## O template carrega a condição

Spot é uma propriedade do template, então toda máquina que o grupo faz é uma máquina Spot. Na mesma
pasta da seção 03, acrescente um template e um grupo:

```hcl
# spot/group.tf
resource "google_compute_instance_template" "photos" {
  name_prefix  = "photos-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "debian-cloud/debian-12"
    boot         = true
  }

  network_interface {
    network = "default"
  }

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "DELETE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "photos" {
  name               = "photos"
  base_instance_name = "photos"
  region             = "southamerica-east1"
  target_size        = 4

  distribution_policy_target_shape = "ANY"

  version {
    instance_template = google_compute_instance_template.photos.id
  }
}
```

```
ana@laptop:~/gcp/spot$ terraform plan -no-color | grep -E '^  #|provisioning_model|instance_termination_action|target_shape|target_size +=|^Plan'
  # google_compute_instance.photos_batch will be created
          + instance_termination_action = "STOP"
          + provisioning_model          = "SPOT"
  # google_compute_instance_template.photos will be created
          + instance_termination_action = "DELETE"
          + provisioning_model          = "SPOT"
  # google_compute_region_instance_group_manager.photos will be created
      + distribution_policy_target_shape = "ANY"
      + target_size                      = 4
Plan: 3 to add, 0 to change, 0 to destroy.
```

O template diz `DELETE`, como a seção 03 recomendou para grupos: o grupo vai fazer uma máquina nova de
qualquer jeito, então uma parada só seguraria um disco e um nome.

## O que o grupo não pode prometer

**Um grupo só consegue recriar uma máquina quando há capacidade para criá-la**, e a condição de uma
preempção é que não há. Um grupo Spot pode então ficar abaixo da meta por minutos ou horas, justamente
nos momentos em que falta aquele tipo naquela zona ao Google. Dois hábitos amenizam isso:

- **espalhar o grupo pelas zonas de uma região**, porque a capacidade acaba zona por zona, e deixá-lo
  pôr máquinas onde houver espaço: `distribution_policy_target_shape = "ANY"` livra um grupo regional
  da distribuição equilibrada da lição 4, o que é certo para trabalho em lote e errado para um serviço
  web que precisa sobreviver a uma zona;
- **não deixar o serviço inteiro depender de Spot.** Um serviço web mantém uma base de máquinas comuns
  que responde sozinha, e acrescenta um grupo Spot atrás do mesmo balanceador para a capacidade extra
  que ele pode perder sem dano.

O segundo hábito são dois grupos, não um: os grupos do Compute Engine pegam um modelo de
provisionamento do template, então uma frota mista é um grupo comum e um grupo Spot lado a lado. O GKE
faz a mesma coisa com node pools, assunto da lição 13.
