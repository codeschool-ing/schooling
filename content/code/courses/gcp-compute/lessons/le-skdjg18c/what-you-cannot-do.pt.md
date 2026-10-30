---
title: O que o Autopilot não deixa fazer
version: 1
---

O Google assume os nós com uma condição: **nada que você publica pode depender de o nó ser seu.**
Então o Autopilot recusa um conjunto de coisas comuns no Standard. A maioria das equipes nunca
sente falta delas; algumas cargas não rodam ali de jeito nenhum, e é melhor descobrir antes de
escolher.

## Node pools, do jeito que o provider vê

Acrescente um node pool ao cluster Autopilot da seção 02, num arquivo `pool.tf` ao lado do
`main.tf`:

```hcl
# autopilot/pool.tf
resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.shop.id
  node_count = 1
}
```

Depois valide e rode o plan:

```
ana@laptop:~/gcp/autopilot$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/gcp/autopilot$ terraform plan -no-color | grep -E '^  #|^Plan'
  # google_container_cluster.shop will be created
  # google_container_node_pool.general will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

**O Terraform não tem objeção.** O pool é um recurso separado, e o provider não consegue saber só
pelo pool que o cluster dele será Autopilot. O GKE o recusaria quando o Terraform tentasse criá-lo,
depois de o cluster existir. Uma configuração no próprio cluster é outra história. Peça ao cluster
para remover o pool padrão, uma ideia do Standard, e o provider sabe na hora:

```
ana@laptop:~/gcp/autopilot$ sed -i 's/^  enable_autopilot    = true$/&\n  remove_default_node_pool = true/' main.tf
ana@laptop:~/gcp/autopilot$ terraform validate -no-color

Error: Conflicting configuration arguments

  with google_container_cluster.shop,
  on main.tf line 20, in resource "google_container_cluster" "shop":
  20:   remove_default_node_pool = true

"remove_default_node_pool": conflicts with enable_autopilot
```

Apague o `pool.tf` e aquela linha antes de seguir. A lição é a mesma da lição 12: o plan pega as
regras que vivem dentro de um recurso e perde as que cruzam entre recursos.

## O que um pod não pode pedir

Estas são recusadas quando o pod é criado, pelos controles de admissão do cluster. Nenhuma pode
ser mostrada aqui, porque não há cluster; são restrições documentadas pelo Google:

- **contêineres privilegiados** e a maioria das capacidades Linux extras. Software que precisa
  carregar módulos do kernel ou gerenciar a rede do host não roda;
- **acesso ao host**: volumes `hostPath` fora de alguns caminhos só de leitura, `hostNetwork`,
  `hostPort` na maioria dos usos;
- **SSH num nó**. Não existe nó em que você possa entrar; a depuração acontece pelo `kubectl`,
  pelos logs e pelas métricas que a plataforma exporta;
- **escolher um nó pelo nome**, ou qualquer coisa que pressuponha uma máquina específica.

Um DaemonSet é permitido, e cobrado como qualquer outro pod em cada nó onde cai, então um agente
de monitoramento que roda em toda parte custa tantas vezes quantos forem os nós que o Google
decidir rodar.

## Como você ainda escolhe hardware

Não escolher um nó não quer dizer não escolher hardware. Um pod pede o que precisa, e o Autopilot
escolhe um nó que combine:

- uma **compute class**, por um node selector, para outro equilíbrio entre processador e preço,
  como uma para CPU mais pesada ou para Arm;
- uma **GPU**, pedindo-a nos recursos do pod, para o trabalho com aceleradores que a lição 2
  descreve;
- **capacidade Spot**, pelo seletor `cloud.google.com/gke-spot: "true"`, para pods que podem ser
  interrompidos.

Essa última é como o redimensionamento de fotos da loja ganha preço Spot no Autopilot sem um pool
próprio: a mesma escolha que a lição 13 fez com um node pool com taint, feita por pod.
