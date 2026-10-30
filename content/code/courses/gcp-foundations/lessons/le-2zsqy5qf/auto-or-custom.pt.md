---
title: Modo automático ou personalizado
version: 1
---

**O modo automático é conveniente uma vez e caro depois.** Uma rede em modo automático ganha uma sub-rede em
cada região, cada uma um `/20` cortado do mesmo bloco, `10.128.0.0/9`, e a própria ajuda do gcloud o chama de
*the recommended selection*. É uma boa rede para aprender. É uma rede ruim para construir uma empresa em cima,
por um motivo:

**toda rede em modo automático tem as mesmas faixas.** Duas delas não podem ser unidas por peering nem por uma
VPN, lições 18 e 21, porque os mesmos endereços estariam dos dois lados. Nem uma rede automática pode ser
unida a um escritório cuja rede use qualquer coisa em `10.128.0.0/9`. Uma rede automática pode ser convertida
para o modo personalizado uma vez, e uma rede personalizada nunca volta a ser automática; a conversão mantém as
faixas, então é uma saída das regiões que ninguém usa, não da sobreposição.

A **rede padrão** que um projeto novo recebe é uma rede automática chamada `default`, com regras de firewall
que a deixam ser alcançada em algumas portas, lição 16. A organização do planner define a restrição booleana
`compute.skipDefaultNetworkCreation`, a maquinaria da lição 4, para que os projetos comecem sem rede nenhuma e
toda rede neles seja uma que alguém escreveu.

## A rede do planner, escrita

Modo personalizado, uma sub-rede em São Paulo e uma em Santiago, e roteamento global, que decide até onde
chegam as rotas aprendidas de fora, lição 21. Substitua o `~/gcp/network/network.tf` por isto, que tem um erro
na última sub-rede:

```hcl
resource "google_compute_network" "planner" {
  project                 = "planner-dev"
  name                    = "planner"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "sao_paulo" {
  project       = "planner-dev"
  name          = "planner-sao-paulo"
  network       = google_compute_network.planner.id
  region        = "southamerica-east1"
  ip_cidr_range = "10.10.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }
}

resource "google_compute_subnetwork" "santiago" {
  project       = "planner-dev"
  name          = "Planner_Santiago"
  network       = google_compute_network.planner.id
  region        = "southamerica-west1"
  ip_cidr_range = "10.11.0.0/33"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color 2>&1 | grep -E "^Error"
Error: "name" ("Planner_Santiago") doesn't match regexp "^(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$"
Error: "ip_cidr_range" is not a valid IP CIDR range: invalid CIDR address: 10.11.0.0/33
```

Duas recusas do provider, antes de qualquer pedido ao Google: o nome de uma sub-rede segue a mesma regra do
de uma rede, letras minúsculas, dígitos e hífens, e `/33` nem é um comprimento de prefixo. Troque o nome para
`planner-santiago` e a faixa para `10.11.0.0/20`, e planeje de novo:

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|ip_cidr_range|auto_create|routing_mode"
  # google_compute_network.planner will be created
      + auto_create_subnetworks                   = false
      + routing_mode                              = "GLOBAL"
  # google_compute_subnetwork.santiago will be created
      + ip_cidr_range                    = "10.11.0.0/20"
  # google_compute_subnetwork.sao_paulo will be created
      + ip_cidr_range                    = "10.10.0.0/20"
          + ip_cidr_range = "10.20.0.0/16"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três recursos: a rede e as duas sub-redes. A **faixa secundária** na sub-rede de São Paulo é um segundo bloco
de endereços para coisas que não são máquinas, os pods de um cluster Kubernetes sendo o caso comum; ela
pertence à sub-rede, na mesma região, e os endereços dela também não podem se sobrepor a nada.
