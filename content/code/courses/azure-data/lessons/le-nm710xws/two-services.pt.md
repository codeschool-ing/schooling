---
title: Dois serviços para um motor
version: 1
---

**Um Redis gerenciado é a máquina de outra pessoa rodando um servidor chave-valor em memória, e a parte
que a Microsoft gerencia é a máquina, não as suas chaves.** Ela instala o servidor, aplica correções,
troca um nó que falha e promove uma réplica. O que entra no cache, por quanto tempo, e o que acontece
quando ele enche continuam sendo decisões do seu programa, e são a maior parte desta lição. A imagem
errada é a de um banco de dados mais rápido: um cache guarda cópias, tem permissão para esquecê-las, e
um programa que não sobrevive ao cache esvaziar durante a noite transformou o cache num banco de dados
sem as garantias de um.

Esta seção é ensinada a partir da documentação da Microsoft, com uma declaração conferida pelo
Terraform. Nenhum emulador responde a nenhum dos dois serviços; o resto da lição roda o próprio motor
do Redis.

## Azure Cache for Redis, o serviço que está sendo aposentado

**O Azure Cache for Redis é o serviço mais antigo, e a Microsoft anunciou a aposentadoria dele**, com o
Azure Managed Redis apontado como o serviço para onde ir. O título desta lição mantém o nome antigo
porque é o que a maioria das implantações existentes, dos documentos e dos anúncios de vaga ainda usa.
Os níveis dele valem a pena conhecer exatamente por isso, porque um cache já rodando em algum lugar está
num deles:

| nível | o que é |
|---|---|
| Basic | um nó, sem réplica e sem acordo de nível de serviço; para desenvolvimento |
| Standard | um primário e uma réplica, com failover |
| Premium | o Standard em máquinas mais rápidas, mais clusterização, persistência em disco, isolamento de rede e geo-replicação |
| Enterprise, Enterprise Flash | o software Redis Enterprise, com os módulos dele e geo-replicação ativa |

**Dois padrões dele importam para um programa.** A política de despejo padrão documentada é
`volatile-lru`, que a seção de despejo abaixo testa, e a porta de texto puro 6379 vem desligada por
padrão, então os clientes conectam com TLS na 6380. Vários comandos de administração, entre eles o
`CONFIG`, são bloqueados, porque as opções do servidor pertencem ao serviço.

## Azure Managed Redis, o que escolher agora

**O Azure Managed Redis roda o software Redis Enterprise em todos os níveis**, e os níveis dele têm o
nome do que a memória equilibra, não de quantos recursos eles liberam. O provedor que o Terraform usa
lista todo tamanho que aceita, o que o torna o jeito mais rápido de conferir os nomes: Memory Optimized,
Balanced, Compute Optimized e Flash Optimized, cada um em tamanhos. O Flash Optimized guarda parte dos
dados em disco rápido em vez de memória.

**Clusterização aqui não é recurso premium: os dados sempre ficam espalhados em shards**, e o que você
escolhe é como os clientes os veem. Na política de clusterização OSS um cliente fala direto com cada
shard e precisa entender o Redis Cluster, os slots de hash da última seção. Na política Enterprise o
serviço apresenta um endpoint só e roteia pelo cliente. Alta disponibilidade, uma réplica de cada shard,
vem ligada a menos que você a desligue, o que só faz sentido em desenvolvimento.

Os preços são por hora do tamanho escolhido, e a tabela de preços da lição 1 os imprime: nenhum é
citado aqui.

## A declaração

O cache de catálogo da Quitanda, como o Terraform o declararia. Crie um diretório, salve o arquivo nele,
e confira:

```sh
mkdir -p ~/azure/tf/redis && cd ~/azure/tf/redis
```

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_managed_redis" "catalogue" {
  name                      = "redis-quitanda-catalogue-prd"
  resource_group_name       = azurerm_resource_group.data.name
  location                  = azurerm_resource_group.data.location
  sku_name                  = "Balanced_B1"
  high_availability_enabled = true

  default_database {
    clustering_policy = "OSSCluster"
    eviction_policy   = "VolatileLRU"
  }
}
```

```
ana@laptop:~/azure/tf/redis$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/redis$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/redis$ sed -i 's/"VolatileLRU"/"volatile-lru"/' main.tf && terraform validate -no-color

Error: expected default_database.0.eviction_policy to be one of ["AllKeysLFU" "AllKeysLRU" "AllKeysRandom" "NoEviction" "VolatileLFU" "VolatileLRU" "VolatileRandom" "VolatileTTL"], got volatile-lru

  with azurerm_managed_redis.catalogue,
  on main.tf line 28, in resource "azurerm_managed_redis" "catalogue":
  28:     eviction_policy   = "volatile-lru"
```

**`sku_name` é o nível e o tamanho numa string só, `Balanced_B1`**, e a lista que o provedor imprimiu
quando recebeu uma política de despejo errada são as oito políticas do Redis, escritas do jeito que o
Azure as escreve: `VolatileLRU` para o `volatile-lru` do Redis. As duas coisas são conferidas contra o
esquema do provedor e nada mais. `OSSCluster` é a política de clusterização que faz os clientes verem
os shards, que a última seção desta lição explica; `high_availability_enabled` dá uma réplica a cada
shard. Se o `Balanced_B1` é oferecido em `brazilsouth` é pergunta para o Azure, e o `validate` não
consegue fazê-la.
