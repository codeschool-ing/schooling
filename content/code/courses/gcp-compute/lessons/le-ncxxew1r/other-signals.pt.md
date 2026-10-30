---
title: Sinais além da CPU
version: 1
---

A CPU é um bom sinal para trabalho que é quase só cálculo e um sinal ruim para todo o resto. **Um
serviço que passa o tempo esperando um banco ou uma fila pode ficar sobrecarregado com a CPU parecendo
ociosa**, e um autoscaler olhando a CPU vai manter o grupo pequeno enquanto os usuários esperam. O
autoscaler do Compute Engine consegue seguir outros dois tipos de sinal, sozinhos ou juntos.

## A medida do próprio balanceador

Quando o grupo fica atrás de um balanceador HTTP(S), o balanceador sabe quantas requisições cada
máquina está atendendo contra uma capacidade que você declarou para ela. A **utilização de
balanceamento** escala por essa razão. É o sinal certo para um serviço web cujo custo por requisição
é mais ou menos constante e cujo limite é quantas requisições ele segura ao mesmo tempo, e não quão
pesado ele calcula. Ele é escrito como um bloco `load_balancing_utilization` no lugar de
`cpu_utilization` ou ao lado dele, e só faz sentido depois que o balanceador da lição 20 do
`gcp-foundations` estiver na frente do grupo.

## Uma métrica sua

Qualquer métrica do Cloud Monitoring pode guiar o grupo, e a que melhor serve a um worker é o tamanho
da fila que ele esvazia. A regra então não é "manter cada máquina 60% ocupada" e sim **"manter mais ou
menos tantas mensagens por máquina"**:

```hcl
# autoscale/queue.tf
resource "google_compute_region_autoscaler" "photos" {
  name   = "photos"
  region = "southamerica-east1"
  target = "projects/planner-dev/regions/southamerica-east1/instanceGroupManagers/photos"

  autoscaling_policy {
    min_replicas = 0
    max_replicas = 20

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.labels.subscription_id = photos-resize"
      single_instance_assignment = 50
    }
  }
}
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E '^  #|single_instance_assignment|num_undelivered|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_autoscaler.photos will be created
              + name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
              + single_instance_assignment = 50
  # google_compute_region_autoscaler.web will be created
  # google_compute_region_instance_group_manager.web will be created
Plan: 4 to add, 0 to change, 0 to destroy.
```

`single_instance_assignment = 50` é a regra: cinquenta mensagens não entregues por máquina. Um acúmulo
de 400 pede oito workers; uma fila vazia não pede nenhum, e é por isso que `min_replicas` pode ser 0
aqui e não podia no grupo web. **Uma fila é o único sinal que mede o trabalho esperando, e não o
trabalho sendo feito**, então ela escala antes de alguém ficar lento, e leva um worker a zero quando
não há nada a fazer, o que nenhuma meta de CPU consegue.

## Quando vários sinais discordam

Um autoscaler pode ter mais de um sinal. Ele calcula um tamanho para cada e **fica com o maior**, então
acrescentar um sinal só pode deixar o grupo maior num dado momento, nunca menor. Essa é a direção
segura, e significa que um sinal sempre alto, uma métrica presa num valor velho, segura o grupo no
máximo até alguém notar a conta.
