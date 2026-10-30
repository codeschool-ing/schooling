---
title: Pedindo um diretório ao Azurite, e declarando o lake
version: 1
---

**O Azurite implementa o endpoint de blob e não o do Data Lake**, e o primeiro comando que usa um
diretório mostra como isso aparece. Vale ver uma vez, porque a falha não é a recusa clara que as
pessoas esperam; os comandos que só mexem em contêineres até parecem funcionar. Um file system novo,
`lake2`, vai ao lado do contêiner `lake` da seção anterior:

```
ana@laptop:~/azure$ az storage fs create -n lake2 -o none && az storage container list --query "[].name" -o tsv
lake
lake2
ana@laptop:~/azure$ az storage fs directory create -f lake2 -n raw 2>&1 | tail -2
ERROR: None
ErrorCode:None
ana@laptop:~/azure$ curl -s -i -X PUT -H "x-ms-version: 2026-06-06" "http://127.0.0.1:10000/devstoreaccount1/lake2/raw?resource=directory" | tr -d "\r"
HTTP/1.1 400 Bad Request
Server: Azurite-Blob/3.37.0
Date: Fri, 30 Oct 2026 18:30:58 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 0
```

**O primeiro comando funcionou, e isso não deve tranquilizar ninguém.** `az storage fs create` criou
um file system, que no endpoint do Data Lake é um contêiner, e a biblioteca por trás da linha de
comando o cria pelo endpoint de blob, o que o Azurite tem. A listagem mostra `lake2` ao lado de
`lake`, como contêiner, que é tudo o que ele é. O comando seguinte precisa de um diretório de verdade,
então vai para o protocolo do Data Lake, e o Azurite não o entende. A resposta que a linha de comando
imprimiu, `ERROR: None`, não nomeia erro nenhum.

O último comando manda a mesma requisição à mão para ver a resposta por baixo: `PUT` num caminho com
`?resource=directory`, a operação do Data Lake para criar um diretório. O Azurite respondeu `400 Bad
Request` com corpo vazio, sem código de erro e sem nada para ler. **Um código de erro `None` é a
assinatura de uma operação do Data Lake chegando ao Azurite.** Um programa testado só contra o
emulador nunca leva o código de diretórios, renomeação ou controle de acesso além da primeira chamada,
e esses caminhos são exatamente os de que esta lição trata.

## Declarando o lake

O que dá para conferir sem conta é a declaração de uma conta com o espaço de nomes ligado, e do file
system e do diretório dentro dela. Crie um diretório para ela, como na lição 1:

```sh
mkdir -p ~/azure/tf/lake && cd ~/azure/tf/lake
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
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "lake" {
  name               = "lake"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_storage_data_lake_gen2_path" "raw" {
  path               = "raw"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.lake.name
  storage_account_id = azurerm_storage_account.lake.id
  resource           = "directory"
}
```

```
ana@laptop:~/azure/tf/lake$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/lake$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/lake$ sed -i 's/= "directory"/= "file"/' main.tf && terraform validate -no-color

Error: expected resource to be one of ["directory"], got file

  with azurerm_storage_data_lake_gen2_path.raw,
  on main.tf line 38, in resource "azurerm_storage_data_lake_gen2_path" "raw":
  38:   resource           = "file"
```

**`is_hns_enabled = true` é toda a diferença** entre esta conta e a que a lição 1 declarou, fora o
nome. Os dois recursos depois dela só existem para contas com o espaço de nomes: um file system, e um
caminho dentro dele. A lista do próprio provedor do que um caminho pode ser tem uma entrada só,
`directory`, como mostra a recusa; arquivos são dados, gravados pelos jobs, e nunca declarados. Como
na lição 1, o `validate` não perguntou nada ao Azure e não criou nada.

A Quitanda mantém **duas contas**: `stquitandadataprd`, da lição 1, plana, para as exportações da loja
e tudo o que uma aplicação lê pelo nome; e `stquitandalakeprd`, com o espaço de nomes, para o lake que
os analistas consultam. A última seção desta lição diz por que a divisão é de propósito e não por
arrumação.
