---
title: Node pools
version: 1
---

**Um node pool é um grupo de nós idênticos**: um tipo de máquina, um disco, uma imagem, um conjunto
de rótulos. Por baixo, cada pool é um grupo gerenciado de instâncias de máquinas do Compute Engine,
o mesmo tipo de grupo que a lição 4 monta à mão, e o GKE o conduz por você. Um cluster tem tantos
pools quantos tipos de nó ele tiver, e o pool é a unidade que você redimensiona, atualiza e troca.

## Escrevendo um

Salve isto ao lado do `main.tf`, na mesma pasta, como `pool.tf`. O Terraform lê todo arquivo `.tf`
de uma pasta como uma configuração só, então o pool pode se referir ao cluster:

```hcl
# gke/pool.tf
resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.shop.id
  location   = "southamerica-east1"
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 50

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
```

O plan agora tem dois recursos:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E '^  #|node_count|node_locations|machine_type|^Plan'
  # google_container_cluster.shop will be created
      + node_locations                           = (known after apply)
  # google_container_node_pool.general will be created
      + initial_node_count          = (known after apply)
      + node_count                  = 1
      + node_locations              = (known after apply)
          + max_node_count  = 3
          + min_node_count  = 1
          + machine_type       = "e2-standard-4"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## O número que é por zona

`node_count = 1` parece um nó, e **num cluster regional é um nó em cada zona que o pool cobre.** A
região da loja tem três zonas, então o pool começa com três máquinas, e os limites de autoscaling
também são por zona: entre três e nove nós no total. `node_locations` aparece como `(known after
apply)` no plan porque o GKE escolhe as zonas ao montar o pool, a menos que você as liste.

Essa multiplicação é a surpresa mais comum na primeira conta do GKE:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E 'per hour|e2-standard-4'
                                    per hour   per month   Spot/hour
  e2-standard-4   4 vCPU  16 GiB    0.13402284       97.84           -
ana@laptop:~/gcp$ python3 -c "print(round(3 * 0.13402284 * 730, 2))"
293.51
```

**Três nós `e2-standard-4` dão 293,51 dólares por mês no piso**, antes da taxa do cluster. É isso
que a disponibilidade de um cluster regional custa: um nó em cada zona, para que perder uma zona
perca um terço da capacidade e não toda. Um cluster zonal com um nó custaria 97,84, e ficaria fora
do ar enquanto a zona dele estivesse.

## O que mais um pool decide

- **`management`** liga duas coisas que o GKE faz com os nós do pool: o **auto-repair** substitui
  um nó que falha nas verificações de saúde, e o **auto-upgrade** leva os nós para versões novas
  conforme o canal de lançamento as oferece. Os dois vêm ligados nos canais de lançamento, e o
  segundo é o assunto da seção 04.
- **`workload_metadata_config` com `GKE_METADATA`** é aquilo de que a lição 15 depende: os pods
  nesses nós pedem credenciais a um servidor de metadados do GKE em vez de alcançar a conta de
  serviço do próprio nó.
- **Mais de um pool** é como um cluster oferece mais de um tipo de máquina. O redimensionamento de
  fotos da loja, que é trabalho em lote que pode ser interrompido, cabe num segundo pool de nós Spot
  com um taint, para que só pods que toleram interrupção caiam ali; a lição 6 explica por que Spot
  combina com esse trabalho, e a lição 14 mostra o Autopilot fazendo a mesma escolha por pod.

Trocar o tipo de máquina de um pool não é uma edição no lugar. O GKE cria nós novos e drena os
antigos, que é a mesma maquinaria de uma atualização, e o motivo de as configurações de
atualização de um pool importarem até para uma equipe que nunca atualiza à mão.
