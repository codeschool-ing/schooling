---
title: Conectores de Serverless VPC Access
version: 1
---

Antes de existir a saída direta, o único caminho do Cloud Run para dentro de uma VPC era um
**conector**: um pequeno grupo gerenciado de máquinas virtuais na sua rede, numa `/28` própria,
que recebe o tráfego de saída do serviço e o repassa. Conectores continuam funcionando, muitos
serviços ainda os usam, e algumas situações ainda pedem um. **A diferença que decide a maioria dos
casos é que um conector são máquinas, e máquinas são cobradas passe ou não passe algo por elas.**

## Escrevendo um

Crie uma pasta `run-connector` em `~/gcp` com este `main.tf`. O conector é um recurso próprio, e o
serviço o nomeia no lugar de uma interface de rede:

```hcl
# run-connector/main.tf
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

resource "google_vpc_access_connector" "shop" {
  name          = "shop-connector"
  region        = "southamerica-east1"
  network       = "shop"
  ip_cidr_range = "10.8.0.0/28"
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
    }

    vpc_access {
      connector = google_vpc_access_connector.shop.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }
}
```

Depois do `terraform init`, o plan:

```
ana@laptop:~/gcp/run-connector$ terraform plan -no-color | grep -E '^  #|connector|egress|machine_type|instances|ip_cidr|^Plan'
  # google_cloud_run_v2_service.orders will be created
              + connector = (known after apply)
              + egress    = "PRIVATE_RANGES_ONLY"
  # google_vpc_access_connector.shop will be created
  + resource "google_vpc_access_connector" "shop" {
      + ip_cidr_range      = "10.8.0.0/28"
      + machine_type       = "e2-micro"
      + max_instances      = 3
      + min_instances      = 2
      + name               = "shop-connector"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**O conector são duas a três máquinas `e2-micro`**, e o plan diz isso com as mesmas palavras que
você escreveu. `ip_cidr_range` é uma `/28`, dezesseis endereços, que não pode se sobrepor a nada
mais na VPC. O conector nunca fica abaixo de `min_instances`, então o piso dele é um custo fixo:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E 'per hour|e2-micro'
                                    per hour   per month   Spot/hour
  e2-micro        2 vCPU   1 GiB   0.008376428        6.11           -
```

Duas máquinas a 6,11 por mês cada dão uns 12 dólares por mês antes de qualquer tráfego, para um
conector que pode não carregar nada à noite. Esse é o preço de tabela do Compute Engine para o tipo
de máquina, que é como o Google cobra as instâncias de um conector. Um `machine_type` maior compra
mais vazão e multiplica o piso; e um conector **escala para fora sob carga e não volta sozinho**,
então depois de um pico ele pode ficar no máximo até alguém perceber.

## Um ou outro

Uma revisão usa um conector ou interfaces de rede, nunca os dois. Recoloque um bloco
`network_interfaces` ao lado de `connector` e veja quem percebe:

```
ana@laptop:~/gcp/run-connector$ sed -i 's/^      connector = .*/&\n      network_interfaces {\n        network = "shop"\n      }/' main.tf
ana@laptop:~/gcp/run-connector$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/gcp/run-connector$ terraform plan -no-color | grep -E 'Error|conflicts|^Plan'
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Ninguém percebeu.** O provider tem a regra, mas só consegue aplicá-la a valores que conhece, e
`google_vpc_access_connector.shop.id` é desconhecido até o conector existir. O Terraform não
consegue comparar um valor desconhecido com nada, então o plan passa, e a recusa viria do Cloud Run
ao criar a revisão. Escreva o id do conector como texto literal e a mesma regra dispara na hora:

```
ana@laptop:~/gcp/run-connector$ sed -i 's#google_vpc_access_connector.shop.id#"projects/planner-dev/locations/southamerica-east1/connectors/shop-connector"#' main.tf
ana@laptop:~/gcp/run-connector$ terraform validate -no-color

Error: Conflicting configuration arguments

  with google_cloud_run_v2_service.orders,
  on main.tf line 36, in resource "google_cloud_run_v2_service" "orders":
  36:       connector = "projects/planner-dev/locations/southamerica-east1/connectors/shop-connector"

"template.0.vpc_access.0.connector": conflicts with
template.0.vpc_access.0.network_interfaces

Error: Conflicting configuration arguments

  with google_cloud_run_v2_service.orders,
  on main.tf line 37, in resource "google_cloud_run_v2_service" "orders":
  37:       network_interfaces {

"template.0.vpc_access.0.network_interfaces": conflicts with
template.0.vpc_access.0.connector
```

Os dois blocos aparecem nos dois erros, que é o provider declarando a regra de cada lado. **Um plan
limpo com referências dentro verificou menos do que parece**, e esta é a forma geral do limite da
lição 1: o Terraform verifica o que consegue saber no seu laptop. Escolha um mecanismo por revisão.

## Quando um conector ainda é a resposta

A saída direta cobre o caso comum, e a orientação do próprio Google aponta os serviços novos para
ela. Um conector ainda cabe quando:

- o serviço já passa por um e funciona, e a migração não tem motivo além de arrumação; migrar
  depois é uma revisão nova;
- a sub-rede não tem espaço para os endereços que a saída direta ocuparia no máximo do serviço, e
  uma `/28` para um conector é todo o espaço que a equipe de rede vai ceder;
- algo do lado da rede foi feito em torno da faixa fixa do conector, como uma regra de firewall que
  admite `10.8.0.0/28` e mais nada.

Para a loja, com uma sub-rede vazia separada para o Cloud Run, a saída direta é a escolha óbvia:
nenhum piso na conta, nenhuma máquina presa no máximo.
