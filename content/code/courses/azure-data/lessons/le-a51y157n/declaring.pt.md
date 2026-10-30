---
title: Declarando o workspace e o pool
version: 1
---

**O workspace, o lago dele e o pool dedicado são três recursos, e o pool é o que custa dinheiro por
hora.** Esta seção os declara para a Quitanda e confere a declaração com o Terraform, que lê o arquivo e
o provedor do Azure e não pergunta nada ao Azure, como explicou a lição 1. Nada é criado. Crie um
diretório para ele e salve o arquivo abaixo:

```sh
mkdir -p ~/azure/tf/synapse && cd ~/azure/tf/synapse
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

resource "azurerm_storage_account" "lake" {
  name                     = "stquitandalakeprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "lake" {
  name               = "lake"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_synapse_workspace" "analytics" {
  name                                 = "synw-quitanda-prd"
  resource_group_name                  = azurerm_resource_group.data.name
  location                             = azurerm_resource_group.data.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.lake.id
  sql_administrator_login              = "quitanda-admin"
  sql_administrator_login_password     = var.sql_admin_password

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "warehouse" {
  name                 = "dw_quitanda"
  synapse_workspace_id = azurerm_synapse_workspace.analytics.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "LRS"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}
```

```
ana@laptop:~/azure/tf/synapse$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/synapse$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/synapse$ sed -i 's/DW100c/DW150c/' main.tf && terraform validate -no-color

Error: expected sku_name to be one of ["DW100c" "DW200c" "DW300c" "DW400c" "DW500c" "DW1000c" "DW1500c" "DW2000c" "DW2500c" "DW3000c" "DW5000c" "DW6000c" "DW7500c" "DW10000c" "DW15000c" "DW30000c"], got DW150c

  with azurerm_synapse_sql_pool.warehouse,
  on main.tf line 49, in resource "azurerm_synapse_sql_pool" "warehouse":
  49:   sku_name             = "DW150c"
```

**O workspace precisa de um Data Lake, e é por isso que a conta de armazenamento diz
`is_hns_enabled = true`**: o namespace hierárquico da lição 3, que o Synapse exige do sistema de
arquivos que recebe como padrão. A senha do administrador vem de uma variável marcada `sensitive`,
nunca do arquivo, porque um arquivo vai para o repositório e uma senha não pode ir. O pool serverless
não precisa de declaração nenhuma: todo workspace tem o `Built-in`.

**`sku_name` é o tamanho, e o provedor conhece todo tamanho que existe**: a lista que ele imprimiu para
o `DW150c` que não existe vai de `DW100c` a `DW30000c`. **`storage_account_type` é para onde vão os
backups do pool**, e o provedor oferece só `LRS` e `GRS` para ele; o `GRS` os copia para a região par,
nos Estados Unidos no caso da `brazilsouth`, então o arquivo da Quitanda diz `LRS`.

O que a declaração não consegue dizer é quando o pool roda. **Pausar é uma operação, não uma
propriedade**: é feito por um agendamento, um pipeline ou uma pessoa, fora deste arquivo, e um pool
declarado aqui e nunca pausado é cobrado a cada hora a partir do momento em que o `apply` o cria. Para
um relatório que roda uma hora por noite, a pausa é a maior economia disponível, e o Data Factory da
lição 19 é um dos lugares comuns para agendá-la.
