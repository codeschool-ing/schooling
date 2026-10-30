---
title: O que o Google assume
version: 1
---

A lição 13 terminou com um cluster cujos nós são seus: o tipo de máquina, a quantidade por zona,
as atualizações, a conta de cada hora em que existem. **O Autopilot muda essa linha. O Google roda
os nós além do plano de controle, e você descreve pods em vez de máquinas.** Você continua
escrevendo Deployments e Services; o que some é toda decisão sobre node pools que a lição 13
levantou.

## O mesmo cluster, com uma linha diferente

Crie uma pasta `autopilot` em `~/gcp` e salve isto como `main.tf`:

```hcl
# autopilot/main.tf
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
  name                = "shop-autopilot"
  location            = "southamerica-east1"
  enable_autopilot    = true
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }
}
```

Não há node pool, tipo de máquina nem manutenção de nós ali. Depois do `terraform init`, o plan:

```
ana@laptop:~/gcp/autopilot$ terraform plan -no-color | grep -E '^  #|autopilot|\+ location|^Plan'
  # google_container_cluster.shop will be created
      + autopilot_privileged_admission           = (known after apply)
      + enable_autopilot                         = true
      + location                                 = "southamerica-east1"
      + name                                     = "shop-autopilot"
      + autopilot_cluster_policy_config (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`enable_autopilot = true` é toda a diferença**, e o plan já traz atributos que um cluster
Standard não tem, como `autopilot_cluster_policy_config`, conhecidos só depois que o Google cria o
cluster. Um cluster Autopilot é sempre regional, e vem com o Workload Identity, assunto da lição
15, já ligado.

## A linha, desenhada

| | Standard | Autopilot |
|---|---|---|
| plano de controle | Google | Google |
| escolher tipos de máquina | você, por node pool | o Google, pelo que os pods pedem |
| quantos nós | você, com limites de autoscaling | o Google, conforme os pods são agendados |
| atualizações e reparos dos nós | você define a estratégia | Google |
| configurações de segurança dos nós | você | o Google, fixas e endurecidas |
| o que você paga | os nós, cheios ou vazios | o que os pods requisitam, enquanto rodam |

Duas linhas importam mais. **O Google escolhe e escala os nós**, então não há nada a dimensionar e
nada rodando vazio de madrugada. E **você paga pods em vez de nós**, então o formato da conta muda,
o que a seção 03 trabalha com números.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois painéis com os mesmos cinco pods. À esquerda, Standard: três nós, um em cada zona, com os pods ocupando parte de cada nó e o resto marcado como pago e vazio; a conta são os três nós. À direita, Autopilot: os mesmos cinco pods sem nó desenhado em volta; a conta é o que os pods requisitam.\"><defs><marker id=\"l14b-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard: você paga os nós</text><rect x=\"24\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona a</text><rect x=\"34\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"34\" y=\"114\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"80\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pago, vazio</text><rect x=\"148\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona b</text><rect x=\"158\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"158\" y=\"114\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"204\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pago, vazio</text><rect x=\"272\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"328\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona c</text><rect x=\"282\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"328\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"328\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pago, vazio</text><text x=\"24\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 nós, seja o que for que tenham</text><text x=\"420\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Autopilot: você paga as requisições</text><rect x=\"420\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"516\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"612\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"654\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"420\" y=\"130\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"516\" y=\"130\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"420\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5 pods, enquanto rodam</text></svg>", "caption": "Os mesmos pods, cobrados de dois jeitos. O Standard cobra pelas caixas, cheias ou não; o Autopilot cobra pelo que está dentro delas."}
```

## O que continua seu

O Autopilot não roda a sua aplicação por você. Os Deployments, a quantidade de réplicas, as
requisições que cada contêiner declara, os PodDisruptionBudgets que tornam uma atualização segura,
os Services e o Gateway que a lição 16 põe na frente: tudo isso é o mesmo trabalho que no Standard.
Um pod com uma réplica continua fora do ar enquanto o nó dele é trocado, e no Autopilot você não
opina sobre quando esse nó é trocado além da janela de manutenção do cluster.

**As requisições são a parte que fica mais importante.** No Standard uma requisição é uma dica
para o agendamento e a conta são os nós; no Autopilot a requisição é a conta. Um contêiner que pede
duas vCPUs e usa um décimo de uma custa duas vCPUs, toda hora que roda.
