---
title: O plano de controle que o Google roda, e quanto custa
version: 1
---

Um cluster Kubernetes tem duas metades: o **plano de controle**, que guarda o estado do cluster e
decide o que roda onde, e os **nós**, que rodam os pods. O GKE Standard divide o trabalho nessa
linha. **O Google roda o plano de controle, aplica as correções e o mantém disponível; você
escolhe, paga e cuida dos nós.** Esta lição é sobre a segunda metade, porque é a que continua sua,
mas começa pelo que a primeira é e quanto custa.

## O que o Google roda

O plano de controle é o API server, o etcd, o scheduler e o controller manager, os componentes que
o curso `kubernetes` instala à mão. No GKE nenhum deles aparece no seu projeto. Não há máquina
virtual para ver, disco para copiar nem versão do etcd para escolher. Você chega ao plano de
controle pelo endpoint dele, com o `kubectl`, e tudo atrás desse endpoint é do Google.

A única decisão que você toma sobre ele é **onde ele mora**:

- um cluster **zonal** tem um plano de controle numa zona. Se essa zona tiver problema, o API
  server fica inalcançável: os pods que já rodam continuam rodando, mas nada pode ser agendado,
  escalado ou mudado até ele voltar;
- um cluster **regional** tem o plano de controle replicado nas zonas da região, e os nós
  espalhados por elas também. Ele sobrevive à perda de uma zona, e o nível de serviço que o Google
  oferece para ele é maior.

A escolha é feita quando o cluster é criado e não muda depois, o que a torna a primeira linha da
definição do cluster, não um detalhe.

## Escrevendo o cluster

Crie uma pasta `gke` em `~/gcp` e salve isto como `main.tf` dentro dela. É o cluster da loja:
regional, no canal de lançamento regular, com uma janela de manutenção e Workload Identity, que as
seções 04 e 05 e a lição 15 explicam, nessa ordem:

```hcl
# gke/main.tf
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

resource "google_container_cluster" "shop" {
  name                = "shop"
  location            = "southamerica-east1"
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2026-11-07T05:00:00Z"
      end_time   = "2026-11-07T11:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
    maintenance_exclusion {
      exclusion_name = "black-friday"
      start_time     = "2026-11-25T00:00:00Z"
      end_time       = "2026-12-02T00:00:00Z"
      exclusion_options {
        scope = "NO_UPGRADES"
      }
    }
  }

  workload_identity_config {
    workload_pool = "planner-dev.svc.id.goog"
  }
}
```

**`location` é uma região, então este é um cluster regional.** Uma zona ali, como
`southamerica-east1-a`, o faria zonal. Repare no que falta: nenhum node pool. O recurso de cluster
só descreve o plano de controle, e os nós vêm na seção 03 como um recurso próprio. Depois do
`terraform init`, o plan só do cluster:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E '^  #|\+ location|channel|workload_pool|^Plan'
  # google_container_cluster.shop will be created
      + location                                 = "southamerica-east1"
      + release_channel {
          + channel = "REGULAR"
          + workload_pool = "planner-dev.svc.id.goog"
Plan: 1 to add, 0 to change, 0 to destroy.
```

## Quanto o plano de controle custa

O GKE cobra uma taxa fixa por cluster pelo plano de controle, seja qual for o tamanho, e dá a toda
conta de faturamento um crédito mensal contra ela:

```
ana@laptop:~/gcp$ python3 prices.py serverless | grep -E 'cluster|credit'
  cluster management fee                                 0.1  per cluster-hour
  free credit each month, per billing account           74.4  dollars
```

**0,10 por hora dá 73 dólares num mês de 730 horas, e o crédito de 74,40 cobre um cluster.** A
página de preços do Google descreve o crédito como o equivalente a um cluster Autopilot ou um
cluster Standard zonal gratuito por mês. O cluster da loja é regional, então conte em pagar a taxa
dele, e um segundo cluster sempre paga. Clusters são baratos de criar e cada um acrescenta 73
dólares por mês antes de existir um único nó; "um cluster por desenvolvedor" é o hábito que deixa
esse número visível.

Os nós são cobrados à parte, como as máquinas do Compute Engine que são. É dessa metade que o resto
da lição trata.
