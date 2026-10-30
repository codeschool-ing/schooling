---
title: Regiões, e a declaração que define o nível
version: 1
---

**O nível, as regiões e se mais de uma região recebe escritas são todos definidos na conta**, numa
declaração só, e essa declaração é o único lugar onde lê-los. Esta seção confere uma com o Terraform,
que lê o arquivo e o provedor do Azure e não pergunta nada ao Azure, como na lição 1. Nada é criado,
porque nenhum emulador responde ao plano de controle.

O arquivo abaixo é a conta que a Quitanda considerou e não construiu: os pedidos em `brazilsouth`,
com uma segunda cópia, só de leitura, em `southcentralus`, a região que a lição 1 apontou como par da
Brazil South. Crie um diretório para ela:

```sh
mkdir -p ~/azure/tf/cosmos && cd ~/azure/tf/cosmos
```

e salve isto nele:

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

resource "azurerm_cosmosdb_account" "app" {
  name                = "cosmos-quitanda-app-prd"
  location            = azurerm_resource_group.data.location
  resource_group_name = azurerm_resource_group.data.name
  offer_type          = "Standard"

  consistency_policy {
    consistency_level = "Session"
  }

  multiple_write_locations_enabled = false

  geo_location {
    location          = "brazilsouth"
    failover_priority = 0
    zone_redundant    = true
  }

  geo_location {
    location          = "southcentralus"
    failover_priority = 1
  }
}
```

**`consistency_policy` é o nível**, e `geo_location` é uma região, um bloco cada. A região com
`failover_priority` 0 é para onde vão as escritas; as outras são cópias, na ordem em que assumiriam.
`multiple_write_locations_enabled` é a chave entre uma região que escreve e todas. Confira, e depois
tente dois valores que o Azure recusaria:

```
ana@laptop:~/azure/tf/cosmos$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/cosmos$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/cosmos$ sed -i 's/"Session"/"BoundedStaleness"\n    max_interval_in_seconds = 1/' main.tf && terraform validate -no-color

Error: expected consistency_policy.0.max_interval_in_seconds to be in the range (5 - 86400), got 1

  with azurerm_cosmosdb_account.app,
  on main.tf line 27, in resource "azurerm_cosmosdb_account" "app":
  27:     max_interval_in_seconds = 1

ana@laptop:~/azure/tf/cosmos$ sed -i 's/"Session"/"Strong"/; s/_enabled = false/_enabled = true/' main.tf && terraform validate -no-color
Success! The configuration is valid.
```

**A primeira recusa é do provedor**: a desatualização limitada não pode ter limite de um segundo, e o
começo da faixa que ele cita, 5 segundos, é o mínimo documentado para uma conta numa região. Ele
aponta a linha, como o da lição 1. **O segundo sucesso é o perigoso.** Consistência forte com
escritas em duas regiões é a combinação que a seção anterior disse que o Cosmos DB não oferece, e o
`validate` a aceitou, porque a regra é do Azure e não mora em esquema nenhum. Ela falharia quando o
`terraform apply` pedisse ao Azure para criar a conta, o que nada neste curso faz, então a resposta
que o Azure daria não aparece aqui. O mesmo vale para desatualização limitada em 5 segundos neste
arquivo de duas regiões: o provedor aceita, e o mínimo documentado para várias regiões é 300.

**Então a declaração é onde um revisor lê o nível, e a documentação é onde ele o confere.** O que
procurar, em ordem:

- `consistency_level`, e se alguma coisa na aplicação pede mais que ele;
- o número de blocos `geo_location`, porque cada um é uma cópia de todo item e uma parte da conta;
- `multiple_write_locations_enabled`, e se for verdadeiro, que o nível não seja forte e que alguém
  tenha escolhido a política de conflitos;
- na desatualização limitada, `max_interval_in_seconds` e `max_staleness_prefix`, contra os mínimos
  para o número de regiões.

A conta da própria Quitanda é este arquivo sem o segundo bloco `geo_location`: uma região, redundante
entre zonas, em sessão.
