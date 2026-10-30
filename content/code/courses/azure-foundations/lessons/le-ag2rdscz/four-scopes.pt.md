---
title: Quatro escopos para onde uma implantação pode mirar
version: 1
---

**Todo pedido para criar alguma coisa no Azure mira num escopo, e o escopo é uma das quatro caixas.**
Um grupo de gerenciamento é criado no escopo do tenant, um grupo de recursos no escopo de uma
assinatura, uma rede no escopo de um grupo de recursos. O Bicep faz do escopo a primeira linha de um
arquivo, e o compilador dele recusa um recurso mirado no escopo errado, então esta é a parte da
hierarquia que o laboratório consegue conferir de verdade.

## A árvore, em Bicep

Bicep é uma linguagem para descrever recursos do Azure, e o `az bicep build` compila um arquivo
`.bicep` num **template ARM**, o documento JSON que o Resource Manager de fato recebe. A lição 26 o
compara com as outras portas de entrada; aqui ele é um jeito de escrever a árvore da loja. Salve isto
como `tree.bicep` em `~/azure/hierarchy`:

```bicep
targetScope = 'tenant'

@description('The id of the management group the shop hangs under: the tenant root, by default.')
param rootId string = tenant().tenantId

resource shop 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'mg-shop'
  properties: {
    displayName: 'Shop'
    details: {
      parent: {
        id: '/providers/Microsoft.Management/managementGroups/${rootId}'
      }
    }
  }
}

resource prod 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'mg-shop-prod'
  properties: {
    displayName: 'Shop production'
    details: {
      parent: {
        id: shop.id
      }
    }
  }
}
```

`targetScope = 'tenant'` diz para onde a implantação mira. Cada `resource` cita um tipo, uma **versão
da sua API** depois do `@`, e as propriedades. O pai de `mg-shop` é, por padrão, a raiz, cujo id é o
id do tenant, e o pai de `mg-shop-prod` é o próprio id de `mg-shop`, que o Bicep calcula. Compile e
olhe três coisas no template:

```
ana@laptop:~/azure/hierarchy$ az bicep build --file tree.bicep --stdout | jq '{schema: ."$schema", resources: [.resources[] | {type, name, parent: .properties.details.parent.id}]}'
{
  "schema": "https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#",
  "resources": [
    {
      "type": "Microsoft.Management/managementGroups",
      "name": "mg-shop",
      "parent": "[format('/providers/Microsoft.Management/managementGroups/{0}', parameters('rootId'))]"
    },
    {
      "type": "Microsoft.Management/managementGroups",
      "name": "mg-shop-prod",
      "parent": "[tenantResourceId('Microsoft.Management/managementGroups', 'mg-shop')]"
    }
  ]
}
```

**O `$schema` diz o escopo**: um template mirado no tenant é um `tenantDeploymentTemplate`. E os pais
não são valores, e sim **expressões entre colchetes**, `format(...)` e `tenantResourceId(...)`. Elas
são avaliadas pelo Resource Manager quando o template chega, porque só o Resource Manager sabe o id do
tenant. Essa é a linha entre o que o laboratório consegue conferir e o que não consegue: o formato se
resolve aqui, os valores lá.

## Um grupo de recursos, no escopo de uma assinatura

Salve isto como `rg.bicep`:

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-shop-prod'
  location: 'brazilsouth'
  tags: {
    environment: 'prod'
  }
}

output id string = rg.id
```

E depois o mesmo grupo num arquivo que não diz nada sobre o escopo, salvo como `wrong.bicep`:

```bicep
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-shop-prod'
  location: 'brazilsouth'
}
```

```
ana@laptop:~/azure/hierarchy$ az bicep build --file rg.bicep --stdout | jq -c '."$schema", .outputs'
"https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
{"id":{"type":"string","value":"[subscriptionResourceId('Microsoft.Resources/resourceGroups', 'rg-shop-prod')]"}}
ana@laptop:~/azure/hierarchy$ az bicep build --file wrong.bicep --stdout
ERROR: /home/ana/azure/hierarchy/wrong.bicep(1,63) : Error BCP135: Scope "resourceGroup" is not valid for this resource type. Permitted scopes: "subscription". [https://aka.ms/bicep/core-diagnostics#BCP135]
```

O primeiro é um `subscriptionDeploymentTemplate`, e a saída dele é uma expressão que vai virar
`/subscriptions/<a assinatura>/resourceGroups/rg-shop-prod` quando rodar. **O segundo foi recusado,
com a regra na mensagem**: um arquivo sem `targetScope` mira num grupo de recursos, e um grupo de
recursos não pode ser criado dentro de um grupo de recursos. `BCP135` é o código, e o endereço depois
dele é a documentação.

Implantar qualquer um dos arquivos é um comando por escopo, cada um recebendo o arquivo e o lugar para
onde ele mira:

| escopo | comando |
|---|---|
| tenant | `az deployment tenant create --location brazilsouth --template-file tree.bicep` |
| grupo de gerenciamento | `az deployment mg create --management-group-id mg-shop --location brazilsouth --template-file ...` |
| assinatura | `az deployment sub create --location brazilsouth --template-file rg.bicep` |
| grupo de recursos | `az deployment group create --resource-group rg-shop-prod --template-file ...` |

**Nenhum dos quatro foi executado**, pelo mesmo motivo do `az group create`: cada um é um pedido ao
Resource Manager. O `--location` dos três primeiros não é para onde os recursos vão; é onde o Azure
guarda o registro da própria implantação, já que um tenant ou uma assinatura não têm localização
própria.

## A mesma árvore, em Terraform

O Terraform descreve os mesmos recursos na sua própria linguagem, com o provider da Microsoft
fornecendo os tipos. Crie um diretório para ele e salve isto como `main.tf`:

```sh
mkdir -p ~/azure/hierarchy/tf && cd ~/azure/hierarchy/tf
```

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

resource "azurerm_management_group" "shop" {
  name         = "mg-shop"
  display_name = "Shop"
}

resource "azurerm_management_group" "prod" {
  name                       = "mg-shop-prod"
  display_name               = "Shop production"
  parent_management_group_id = azurerm_management_group.shop.id
}

resource "azurerm_management_group_subscription_association" "prod" {
  management_group_id = azurerm_management_group.prod.id
  subscription_id     = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
}

resource "azurerm_resource_group" "prod" {
  name     = "rg-shop-prod"
  location = "brazilsouth"
}
```

O Terraform não tem `targetScope`: cada tipo de recurso sabe o próprio escopo, e a associação entre
uma assinatura e um grupo de gerenciamento é um recurso à parte. O `init` busca o provider, na
primeira vez no registro da HashiCorp e depois no cache que o `env.sh` configurou; o `validate` confere
cada bloco contra o esquema do provider; e o `plan` é onde ele perguntaria ao Azure o que existe:

```
ana@laptop:~/azure/hierarchy/tf$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/hierarchy/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/hierarchy/tf$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azurerm"],
│   on main.tf line 10, in provider "azurerm":
│   10: provider "azurerm" {
│ 
╵
```

O `validate` passou e o `plan` parou na primeira coisa de que precisava do Azure: uma identidade, que
ele pede à CLI do Azure. **A mesma linha divide as duas ferramentas**: as duas conferem o formato no
seu computador, e as duas precisam do Resource Manager para tudo o que vem depois.
