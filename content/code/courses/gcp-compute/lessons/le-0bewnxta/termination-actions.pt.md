---
title: Parar ou apagar, e um limite de tempo
version: 1
---

Quando o Compute Engine retoma uma máquina Spot, ele precisa fazer alguma coisa com ela, e você
escolhe o quê. **Uma máquina Spot retomada é parada, mantendo os discos e o nome, ou apagada, levando
o disco de boot junto.** A escolha decide o que uma preempção deixa para trás e o que continua
custando.

## As duas ações

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --instance-termination-action/,/^     --internal-ipv6-address/p' | head -n -2
     --instance-termination-action=INSTANCE_TERMINATION_ACTION
        Specifies the termination action that will be taken upon VM preemption
        (--provisioning-model=SPOT) or automatic instance termination
        (--max-run-duration or --termination-time).

        INSTANCE_TERMINATION_ACTION must be one of:

         DELETE
            Permanently delete the VM.
         STOP
            Default only for Spot VMs. Stop the VM without preserving memory.
            The VM can be restarted later.
```

| ação | o que sobra | o que custa depois |
|---|---|---|
| `STOP` | a máquina, parada, com os discos persistentes | os discos, até alguém ligar ou apagar a máquina |
| `DELETE` | nada além dos discos marcados para sobreviver a ela | nada pela máquina; um disco de dados continua custando |

**`STOP` é o certo para uma máquina avulsa que você vai ligar de novo**, quando a capacidade voltar,
com o disco como estava. **`DELETE` é o certo dentro de um grupo gerenciado**, que cria uma máquina
nova do template de qualquer jeito e não tem uso para um cadáver parado; a seção 04 volta a isso. Um
SSD local, da lição 3, se perde nos dois casos: a máquina saiu do host.

## Escrevendo

Para uma máquina em lote que redimensiona as fotos da loja, numa pasta `spot`:

```hcl
# spot/main.tf
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

resource "google_compute_instance" "photos_batch" {
  name         = "photos-batch-1"
  machine_type = "e2-standard-2"
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
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "STOP"

    max_run_duration {
      seconds = 14400
    }
  }
}
```

```
ana@laptop:~/gcp/spot$ terraform plan -no-color | grep -E 'provisioning_model|preemptible|automatic_restart|instance_termination_action|seconds|^Plan'
          + automatic_restart           = false
          + instance_termination_action = "STOP"
          + preemptible                 = true
          + provisioning_model          = "SPOT"
              + seconds = 14400
Plan: 1 to add, 0 to change, 0 to destroy.
```

Três dessas linhas não são escolhas. **Uma máquina Spot precisa ter `preemptible = true` e
`automatic_restart = false`**: a API do Google recusa os outros valores, porque uma máquina que ele
pode retomar não pode ser também uma que ele promete reiniciar. O plan não sabe disso; ponha
`automatic_restart = true` e ele planeja do mesmo jeito, e a recusa vem na criação, como toda regra
das lições 1 a 5 que pertencia ao Compute Engine.

## Um limite de tempo seu

`max_run_duration` é o oposto de uma preempção: **um limite que você define, depois do qual o próprio
Compute Engine aplica a ação de encerramento.** 14.400 segundos são quatro horas. Ele existe para a
máquina que nunca deveria rodar muito, um job em lote que deveria terminar em uma hora, para que um job
preso num laço pare de custar dinheiro depois de quatro, em vez de rodar até alguém perceber. Ele
funciona também em máquinas comuns, não só em Spot. A ajuda do gcloud acrescenta o detalhe que importa,
que é quando o relógio começa:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --max-run-duration/,/^     --metadata=/p' | head -n -2
     --max-run-duration=MAX_RUN_DURATION
        Limits how long this VM instance can run, specified as a duration
        relative to the last time when the VM began running. Format the
        duration, MAX_RUN_DURATION, as the number of days, hours, minutes, and
        seconds followed by d, h, m, and s respectively. For example, specify
        30m for a duration of 30 minutes or specify 1d2h3m4s for a duration of
        1 day, 2 hours, 3 minutes, and 4 seconds. Alternatively, to specify a
        timestamp, use --termination-time instead.

        If neither --max-run-duration nor --termination-time is specified
        (default), the VM instance runs until prompted by a user action or
        system event. If either is specified, the VM instance is scheduled to
        be automatically terminated at the VM's termination timestamp
        (terminationTimestamp) using the action specified by
        --instance-termination-action.

        Note: The terminationTimestamp is removed whenever the VM is stopped or
        suspended and redefined whenever the VM is rerun. For
        --max-run-duration specifically, the terminationTimestamp is the sum of
        MAX_RUN_DURATION and the time when the VM last entered the RUNNING
        state, which changes whenever the VM is rerun.
```
