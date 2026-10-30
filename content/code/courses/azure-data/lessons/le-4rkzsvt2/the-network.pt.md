---
title: Dentro da sua rede, numa sub-rede só dela
version: 1
---

**Uma Managed Instance mora dentro da sua rede virtual**, numa sub-rede entregue a ela, e responde num
endereço privado ali. O Azure SQL Database começa na internet e é puxado para dentro com um private
endpoint; a Managed Instance começa dentro e é deixada sair, se for o caso, por um endpoint público que
você liga. Para uma empresa cuja equipe de segurança pergunta primeiro onde o banco responde, essa
costuma ser a linha que decide.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** A declaração é conferida pelo Terraform, offline.

## A sub-rede, e o que mora nela

**A sub-rede é delegada a `Microsoft.Sql/managedInstances`**, o que a entrega ao serviço: o Azure põe
as máquinas da instância ali e anexa as rotas e as regras de segurança de rede de que o serviço precisa
para gerenciá-las. Nada mais pode ser posto nessa sub-rede. Uma sub-rede pode guardar várias
instâncias, e a documentação a dimensiona por quantas e de que tamanho, então ela é escolhida com
espaço para crescer; uma sub-rede pequena demais para a próxima instância é uma migração para outra
sub-rede.

**Criar ou redimensionar uma instância é uma operação demorada**, porque o Azure monta o grupo de
máquinas que a hospedam, o cluster virtual, dentro da sua sub-rede antes de a instância responder. A
documentação dá a duração esperada de cada tipo de operação, e um plano que redimensiona a instância
durante o expediente precisa lê-la antes.

**O endpoint público fica desligado a não ser que você o ligue.** Ligado, ele responde na porta 3342,
não na 1433, e só as regras de rede que você escreve deixam alguém alcançá-lo. Deixá-lo desligado, e
chegar à instância de dentro da rede ou por uma VPN, é o arranjo que as lições 16 e 23 de
`azure-foundations` descrevem para qualquer serviço privado.

## A declaração

Uma rede virtual, uma sub-rede delegada e uma instância. Num diretório novo:

```sh
mkdir -p ~/azure/tf/sqlmi && cd ~/azure/tf/sqlmi
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

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "data" {
  name                = "vnet-quitanda-data-prd"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "mi" {
  name                 = "snet-sqlmi"
  resource_group_name  = azurerm_resource_group.data.name
  virtual_network_name = azurerm_virtual_network.data.name
  address_prefixes     = ["10.20.1.0/24"]

  delegation {
    name = "sqlmi"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
    }
  }
}

resource "azurerm_mssql_managed_instance" "orders" {
  name                         = "sqlmi-quitanda-prd"
  resource_group_name          = azurerm_resource_group.data.name
  location                     = azurerm_resource_group.data.location
  subnet_id                    = azurerm_subnet.mi.id
  sku_name                     = "GP_Gen5"
  vcores                       = 8
  storage_size_in_gb           = 256
  license_type                 = "BasePrice"
  administrator_login          = "quitanda"
  administrator_login_password = var.sql_admin_password
  public_data_endpoint_enabled = false
}
```

**O nome é o nível e o hardware, e os vCores são um número à parte**, diferente do `GP_Gen5_2` da
lição 8. `storage_size_in_gb` é comprado separado da computação, como no modelo vCore.
`license_type = "BasePrice"` é o Azure Hybrid Benefit, o preço sem a licença; `LicenseIncluded` é o
outro valor. E `public_data_endpoint_enabled = false` escreve o padrão, para que quem revisa o arquivo
veja a decisão.

```
ana@laptop:~/azure/tf/sqlmi$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/sqlmi$ terraform validate -no-color
Success! The configuration is valid.

```

Escreva aqui o nome da lição 8 e o provider diz o que espera no lugar:

```
ana@laptop:~/azure/tf/sqlmi$ sed -i.bak 's/"GP_Gen5"/"GP_Gen5_8"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: expected sku_name to be one of ["BC_Gen4" "BC_Gen5" "BC_Gen8IH" "BC_Gen8IM" "GP_Gen4" "GP_Gen5" "GP_Gen8IH" "GP_Gen8IM"], got GP_Gen5_8

  with azurerm_mssql_managed_instance.orders,
  on main.tf line 50, in resource "azurerm_mssql_managed_instance" "orders":
  50:   sku_name                     = "GP_Gen5_8"

```

```
ana@laptop:~/azure/tf/sqlmi$ sed -i.bak 's/"BasePrice"/"BringYourOwn"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected license_type to be one of ["LicenseIncluded" "BasePrice"], got BringYourOwn
```

**`GP_Gen5_8` é um nome válido para um banco e inválido para uma instância**, e a lista do provider diz
por quê: uma instância nomeia só o nível e o hardware. A lista de licenças tem dois valores, e o Hybrid
Benefit é o que se chama `BasePrice`, um nome que ninguém adivinharia pelo marketing.
