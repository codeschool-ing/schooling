---
title: Soft delete, e a exclusão que dá para desfazer
version: 1
---

**A lição 2 terminou com uma sobrescrita que destruiu seis linhas de log, e nada conseguiu trazê-las
de volta.** O Blob Storage tem três recursos que mudam isso, e esta lição os trata na ordem em que as
pessoas costumam ligá-los: o soft delete, que guarda o que foi apagado por um tempo; o versionamento,
que guarda o que foi sobrescrito; e a imutabilidade, que recusa a exclusão e a sobrescrita de saída.
Nenhum deles funciona no Azurite, como mostra a última seção da lição, então esta seção e quase toda a
próxima foram escritas a partir da documentação da Microsoft e conferidas com o Terraform, que lê a
declaração e não pergunta nada ao Azure.

## O que o soft delete guarda

**O soft delete de blob guarda um blob apagado por um número de dias que você escolhe.** Nesse tempo
dá para desfazer a exclusão. Durante esses dias o blob fica invisível numa listagem comum, aparece numa que
pede os apagados e é cobrado como se ainda estivesse lá. Depois deles some de vez. A Microsoft
documenta a retenção de 1 a 365 dias. Documenta também que, sem versionamento, o soft delete protege
uma sobrescrita: o conteúdo substituído é guardado como um snapshot apagado de forma reversível, o
primo mais antigo e manual das versões da próxima seção.

**O soft delete de contêiner é uma chave separada** e protege o outro tipo de erro: um contêiner
inteiro apagado, com tudo dentro. Um contêiner apagado volta com os blobs como estavam. Os dois são
independentes, e um desenho que liga só um deles está protegido contra só um dos dois erros.

As pessoas esperam que o soft delete seja uma lixeira que dá para abrir e navegar. Ele está mais
perto de uma regra de retenção. Nada é movido: o blob fica onde estava, marcado como apagado, e volta
com o mesmo nome. E **ele não impede uma exclusão**. Um programa com permissão para apagar continua
apagando; o soft delete só dá uma janela para perceber, medida em dias, em que a restauração é uma
requisição só.

## Declarando

O soft delete e o versionamento são propriedades do serviço de blob da conta, então ficam no plano de
controle e o Terraform os declara. Crie um diretório para as declarações desta lição:

```sh
mkdir -p ~/azure/tf/protect && cd ~/azure/tf/protect
```

`account.tf`:

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

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }

    container_delete_retention_policy {
      days = 14
    }
  }
}
```

```
ana@laptop:~/azure/tf/protect$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/days = 14/days = 400/' account.tf && terraform validate -no-color

Error: expected blob_properties.0.delete_retention_policy.0.days to be in the range (1 - 365), got 400

  with azurerm_storage_account.data,
  on account.tf line 31, in resource "azurerm_storage_account" "data":
  31:       days = 400


Error: expected blob_properties.0.container_delete_retention_policy.0.days to be in the range (1 - 365), got 400

  with azurerm_storage_account.data,
  on account.tf line 35, in resource "azurerm_storage_account" "data":
  35:       days = 400
```

Esta é a conta de exportações da lição 1, `stquitandadataprd`, com um bloco `blob_properties` a mais.
**Duas políticas de retenção de 14 dias**, uma para blobs e outra para contêineres. Duas semanas
cobrem uma exportação que sumiu e foi notada na conferência semanal seguinte, e são curtas o bastante
para a Quitanda não pagar meses de arquivos apagados. O erro é a cerca do próprio provedor, os 1 a 365
dias da documentação. O `versioning_enabled` é a próxima seção.
