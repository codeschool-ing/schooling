---
title: Instâncias mínimas e o impulso de CPU na subida
version: 1
---

Quando uma partida a frio não fica curta o bastante, duas configurações impedem os usuários de
encontrá-la. **Um número mínimo de instâncias mantém algumas quentes o tempo todo, e o impulso de
CPU na subida dá a uma instância que está subindo mais CPU do que ela vai ter depois.** A primeira
custa dinheiro toda hora; a segunda custa um pouco a cada subida.

## Um mínimo quente

`min_instance_count = 1` mantém uma instância viva quando não há tráfego. Com cobrança por
requisição ela é cobrada, enquanto espera, pela taxa de ociosidade que a tabela lista: 0,0000025
dólar por vCPU-segundo, cerca de um décimo da taxa ativa, e os mesmos 0,0000025 por GiB-segundo de
memória. A coluna do meio do programa da seção 03 é esse custo: **uma instância de 1 vCPU e 512 MiB
mantida quente enquanto ociosa 95% do mês custa 9,36 dólares**, além do que ela custa atendendo.

Se isso vale a pena depende de quantas vezes uma requisição esperaria sem ela. Um serviço chamado
algumas vezes por hora, cada chamada depois de as instâncias ociosas terem sido desligadas, sobe a
frio quase toda vez; dez dólares por mês para tirar isso é barato. Um serviço com tráfego constante
sempre tem uma instância rodando, e um mínimo só acrescenta custo. E **um mínimo é por serviço e por
revisão com tráfego**, então uma divisão da lição 9 entre duas revisões pode manter duas quentes.

## Impulso de CPU na subida

Muitos runtimes fazem o trabalho mais pesado na subida: o Python importando, o Java compilando, um
framework varrendo as rotas. **Com `startup_cpu_boost = true`, o Cloud Run dá à instância CPU extra
enquanto ela sobe** e por um tempo curto depois, e então a tira. A documentação do Google descreve o
impulso e como ele é cobrado; este laboratório não consegue medi-lo, e o curso não cita ganho
nenhum.

## As configurações, por escrito

Salve isto como `tuning/main.tf` em `~/gcp`:

```hcl
# tuning/main.tf
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

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }
    }
  }
}
```

Em `~/gcp/tuning`, `terraform init` e o plan:

```
ana@laptop:~/gcp/tuning$ terraform plan -no-color | grep -E 'concurrency|cpu_idle|startup_cpu_boost|min_instance_count|^Plan'
          + max_instance_request_concurrency = 80
                  + cpu_idle          = true
                  + startup_cpu_boost = true
              + min_instance_count = 1
Plan: 1 to add, 0 to change, 0 to destroy.
```

Cada linha é uma decisão desta lição: **80 requisições por instância**, porque o serviço de pedidos
espera em vez de calcular; **`cpu_idle = true`**, cobrança por requisição, porque o serviço fica
ocupado uma pequena parte do dia; **uma instância quente**, porque a primeira requisição da manhã
não deve esperar; e **um impulso na subida**, porque os imports do Python são o momento mais pesado
dele.

## A ordem em que decidir

1. **A concorrência primeiro**, a partir de uma medição como a da seção 02, porque ela define por
   quantas instâncias todo o resto é multiplicado.
2. **A alocação de CPU em segundo**, pela parte ocupada e pela conta da seção 03.
3. **Encurtar a partida a frio** no programa, seção 04.
4. **Só então um mínimo e um impulso**, para a partida a frio que sobrar e ainda importar.
