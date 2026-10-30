---
title: Definindo um tier, no upload e depois
version: 1
---

**Um tier é definido quando o blob é enviado, ou trocado num blob que já existe, e nos dois casos é
uma requisição.** Nada é copiado na troca: o blob mantém o nome, o ETag continua valendo e o conteúdo
não é mandado de novo. Esta seção faz as duas coisas no Azurite, que aceita os tiers e os registra, e
lê de volta o que ele registrou.

Crie uma exportação de setembro e ponha num contêiner novo duas vezes, uma sem tier e outra em cool:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n09-1,c-17,4590\n09-2,c-03,12800\n' > export/orders-2026-09.csv
```

```
ana@laptop:~/azure$ az storage container create -n orders-archive -o none
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n orders/2026-09/default.csv -f export/orders-2026-09.csv --no-progress -o none
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n orders/2026-09/cool.csv -f export/orders-2026-09.csv --tier Cool --no-progress -o none
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Hot
true
2026-10-30T18:48:26+00:00
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Cool
false
2026-10-30T18:48:27+00:00
```

**`blobTierInferred` é a diferença.** O primeiro blob não recebeu tier, então informa o padrão da
conta, `Hot`, e diz que o tier foi inferido. O segundo recebeu `Cool` e diz que não foi. A distinção
importa no Azure quando o padrão da conta muda: um tier inferido acompanha o padrão novo, e um tier
definido no blob fica onde está. O terceiro valor é quando o tier mudou pela última vez, em UTC.

## Trocando

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Cold
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Cold
false
2026-10-30T18:48:29+00:00
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Frozen 2>&1 | cut -d, -f1-4
ERROR: Unknown block blob tier name. Choose among ARCHIVE, COLD, COOL, HOT
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n logs/app.log -f export/orders-2026-09.csv --type append --no-progress -o none
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n logs/app.log --tier Cool 2>&1 | grep ErrorCode
ErrorCode:AccessTierNotSupportedForBlobType
```

O `set-tier` moveu o blob de hot para cold, e a hora da troca andou junto. O terceiro comando pediu um
tier que não existe, e a linha de comando o recusou antes de mandar qualquer coisa. O `cut` guarda os
quatro primeiros nomes, porque o resto da mensagem lista, por um defeito da própria linha de comando,
os métodos de uma string do Python. **Hot, cool, cold e archive são os quatro.** Os dois últimos
comandos criam um append blob, que é o que `--type append` pede, e tentam pôr um tier nele: o Azurite
recusa com `AccessTierNotSupportedForBlobType`, como o Azure faz.

A Microsoft documenta quanto custa uma troca, e é a parte desta seção para guardar. Mover um blob para
um tier mais frio é cobrado como uma escrita no tier para onde ele vai. Movê-lo para um mais quente é
cobrado como uma leitura no tier de onde ele sai, com o preço por gigabyte lido daquele tier. E tirar
um blob de cool, cold ou archive antes dos dias mínimos conta como saída antecipada. Uma troca de tier
é barata para um blob e uma linha de verdade na conta para dez milhões.

## O padrão da conta, declarado

O padrão é uma propriedade da conta, então fica com o plano de controle, e o Terraform confere a
declaração. Crie um diretório como na lição 1 e salve a conta com padrão cool:

```sh
mkdir -p ~/azure/tf/tiers && cd ~/azure/tf/tiers
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

resource "azurerm_resource_group" "archive" {
  name     = "rg-quitanda-archive-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "archive" {
  name                     = "stquitandaarchiveprd"
  resource_group_name      = azurerm_resource_group.archive.name
  location                 = azurerm_resource_group.archive.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}
```

```
ana@laptop:~/azure/tf/tiers$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/tiers$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/tiers$ sed -i 's/"Cool"/"Archive"/' main.tf && terraform validate -no-color

Error: expected access_tier to be one of ["Cold" "Cool" "Hot" "Premium" "Smart"], got Archive

  with azurerm_storage_account.archive,
  on main.tf line 26, in resource "azurerm_storage_account" "archive":
  26:   access_tier              = "Archive"
```

**O padrão da conta não pode ser archive**, e a lista do provedor diz isso: `Cold`, `Cool`, `Hot`,
`Premium` e `Smart`. O archive só é definido blob a blob, de propósito, porque um blob que cai no
archive por padrão é um blob que ninguém consegue ler na manhã seguinte. `Premium` é o valor para
contas premium. Esta conta é `LRS` em vez do `ZRS` da lição 1 por um motivo que a próxima seção dá.
