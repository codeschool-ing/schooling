---
title: Uma atribuição elegível, por escrito
version: 1
---

**O PIM costuma ser operado pelo portal, e não precisa ser.** Uma atribuição elegível é um recurso do
Resource Manager como qualquer outro, `Microsoft.Authorization/roleEligibilityScheduleRequests`, e o
provider de Terraform da Microsoft tem um recurso para ela. Escrever a elegibilidade da loja num
arquivo a põe onde um pull request consegue revisá-la, e essa revisão é mais uma pessoa concordando.

## A elegibilidade da loja, em Terraform

Crie o diretório da lição e salve isto como `main.tf` nele:

```sh
mkdir -p ~/azure/pim && cd ~/azure/pim
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

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff"
}

resource "azurerm_pim_eligible_role_assignment" "ana_prod" {
  scope              = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod"
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
  justification      = "On call for the shop's production"

  schedule {
    expiration {
      duration_days = 180
    }
  }
}
```

Esta deixa `ana` elegível a Contributor no `rg-shop-prod`. Três peças carregam o sentido. O **bloco
`data`** procura um papel pelo nome num escopo: o Terraform pergunta ao Resource Manager o id do
Contributor quando planeja, em vez de o arquivo carregar o GUID. O **recurso** junta uma entidade, um
papel e um escopo, exatamente como a atribuição da lição 9, com uma palavra a mais no tipo. E o
**`schedule`** é a duração da elegibilidade, aqui 180 dias: o formato com prazo que a primeira seção
recomendou. A entidade é o object id de `ana` no tenant, um valor inventado no padrão da
documentação.

Rode `terraform init` uma vez no diretório, depois confira o arquivo:

```
ana@laptop:~/azure/pim$ terraform validate
Success! The configuration is valid.
```

## Dizendo uma vez só quando ela acaba

Uma elegibilidade acaba depois de um número de dias ou numa data, e um arquivo que diz as duas coisas
é um arquivo cujo sentido depende de qual delas vence. Acrescente uma data de fim debaixo da duração:

```sh
sed -i 's/      duration_days = 180/      duration_days = 180\n      end_date_time = "2027-04-30T00:00:00Z"/' main.tf
```

```
ana@laptop:~/azure/pim$ terraform validate
╷
│ Error: Conflicting configuration arguments
│ 
│   with azurerm_pim_eligible_role_assignment.ana_prod,
│   on main.tf line 27, in resource "azurerm_pim_eligible_role_assignment" "ana_prod":
│   27:       duration_days = 180
│ 
│ "schedule.0.expiration.0.duration_days": conflicts with
│ schedule.0.expiration.0.end_date_time
╵
╷
│ Error: Conflicting configuration arguments
│ 
│   with azurerm_pim_eligible_role_assignment.ana_prod,
│   on main.tf line 28, in resource "azurerm_pim_eligible_role_assignment" "ana_prod":
│   28:       end_date_time = "2027-04-30T00:00:00Z"
│ 
│ "schedule.0.expiration.0.end_date_time": conflicts with
│ schedule.0.expiration.0.duration_days
╵
```

**O provider recusa o par**, nas duas linhas, antes de qualquer coisa ser mandada a lugar nenhum. É o
tipo de erro que um esquema pega, e ele o pega no seu computador. Tire a linha de novo com
`sed -i '/end_date_time/d' main.tf` e o arquivo volta a ser válido.

## Onde o laboratório para

```
ana@laptop:~/azure/pim$ terraform plan -input=false

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

O `plan` precisaria do Resource Manager duas vezes aqui: uma para a identidade de quem o roda, e uma
para o bloco `data`, que pergunta qual é o id do Contributor. Ele parou na primeira, por falta de
login, então **a elegibilidade nunca foi criada**, nem a ativação que ela permitiria.

As configurações da seção anterior, a duração máxima, os aprovadores, o segundo fator, são **um
objeto separado**: uma role management policy, presa ao papel num escopo. O provider da Microsoft tem
um recurso para isso também, `azurerm_role_management_policy`, e uma equipe que declara as
elegibilidades num arquivo deveria declarar as políticas ao lado delas. Ela não foi escrita aqui,
porque uma política de ativação que nunca foi testada contra um tenant real é o tipo de arquivo cujos
erros só o tenant mostra.

**Uma elegibilidade do PIM não substitui o papel estreito.** Tornar o Owner elegível em vez de ativo é
uma boa mudança. Tornar o `Shop App Restarter` elegível em vez de distribuir Owner é uma melhor. A
lição 9 decide quanto poder um papel tem; esta lição decide por quantas horas.
