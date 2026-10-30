---
title: Um workspace na sua própria rede, declarado e conferido
version: 1
---

**Um workspace do Databricks é criado pelo Azure Resource Manager, então a declaração dele pode ser
conferida do jeito que a lição 1 conferiu uma conta de armazenamento**: offline, pelo Terraform,
contra o schema do provider. Nada é criado e nenhum workspace existe depois. Esta declaração põe os
clusters do workspace numa rede que é da Quitanda, sem endereços públicos, e dá ao Unity Catalog uma
identidade para chegar ao lago. Crie o diretório e salve o arquivo:

```sh
mkdir -p ~/azure/tf/databricks && cd ~/azure/tf/databricks
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

resource "azurerm_resource_group" "analytics" {
  name     = "rg-quitanda-analytics-prd"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "dbw" {
  name                = "vnet-quitanda-dbw-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_network_security_group" "dbw" {
  name                = "nsg-quitanda-dbw-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location
}

resource "azurerm_subnet" "dbw" {
  for_each             = { host = "10.20.1.0/24", container = "10.20.2.0/24" }
  name                 = "snet-dbw-${each.key}"
  resource_group_name  = azurerm_resource_group.analytics.name
  virtual_network_name = azurerm_virtual_network.dbw.name
  address_prefixes     = [each.value]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "dbw" {
  for_each                  = azurerm_subnet.dbw
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.dbw.id
}

resource "azurerm_databricks_access_connector" "unity" {
  name                = "dbac-quitanda-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_workspace" "dbw" {
  name                        = "dbw-quitanda-prd"
  resource_group_name         = azurerm_resource_group.analytics.name
  location                    = azurerm_resource_group.analytics.location
  sku                         = "premium"
  managed_resource_group_name = "rg-quitanda-dbw-managed-prd"

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.dbw.id
    public_subnet_name                                   = azurerm_subnet.dbw["host"].name
    private_subnet_name                                  = azurerm_subnet.dbw["container"].name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.dbw["host"].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.dbw["container"].id
  }
}
```

Lido de cima para baixo, o arquivo declara primeiro a rede e por último o workspace, porque o
workspace cita tudo o que vem antes:

- **uma rede virtual e duas sub-redes**, `snet-dbw-host` e `snet-dbw-container`, escritas uma vez com
  `for_each`. Cada uma é **delegada** a `Microsoft.Databricks/workspaces`, o que deixa o workspace
  gerir as configurações de rede das máquinas que põe ali, e cada uma tem o mesmo network security
  group;
- **um access connector**, `azurerm_databricks_access_connector`, que existe só para guardar uma
  identidade gerenciada atribuída pelo sistema. O Unity Catalog usa essa identidade para ler e gravar
  na conta de armazenamento, então nenhuma chave do lago é entregue ao Databricks; a identidade ainda
  precisa de um papel na conta, como a factory da lição 19 precisava;
- **o workspace**, no tier `premium`, com o grupo de recursos gerenciado nomeado em vez de deixado
  para o Azure, e `custom_parameters` que o injetam na rede: a rede virtual, os nomes das duas
  sub-redes, as duas associações com o security group, e `no_public_ip = true`.

```
ana@laptop:~/azure/tf/databricks$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/databricks$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/databricks$ sed -i 's/= "premium"/= "gold"/' main.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= "gold"/= "premium"/' main.tf
Error: expected sku to be one of ["standard" "premium" "trial"], got gold
ana@laptop:~/azure/tf/databricks$ terraform fmt -check && echo formatted
formatted
```

**Os três tiers são a lista do provider**, e o arquivo está disposto do jeito que o `terraform fmt` o
disporia. O que o `validate` não consegue saber é tudo o que o Azure confere na criação: se as duas
sub-redes são grandes o bastante, se o security group tem as regras de que o Databricks precisa, se
o nome está livre. Isso falha no `apply`, contra uma assinatura, que este curso nunca usa.

## O que um workspace não declara

**Quase nada do que acontece dentro do workspace é um recurso do Azure.** Clusters, jobs, SQL
warehouses, notebooks, os catálogos e os grants do Unity Catalog vivem todos no plano de controle, e o
Azure Resource Manager não os vê. Eles são declarados com o provider do próprio Databricks para o
Terraform, `databricks/databricks`, que fala com a API do workspace com um token ou uma identidade do
Entra ID, e que este curso não instala: sem um workspace para responder, o `validate` dele conferiria
só a grafia. Um time que declara a plataforma no Terraform roda então dois providers, `azurerm` para o
workspace, a rede e a identidade, e o do Databricks para tudo o que está dentro, a mesma divisão que a
lição 17 encontrou no Fabric entre a capacidade e os workspaces dela.
