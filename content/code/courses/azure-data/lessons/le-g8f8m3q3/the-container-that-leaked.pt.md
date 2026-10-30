---
title: O contêiner que vazou, e como não ter um
version: 1
---

**As exposições de armazenamento que chegam ao jornal são, em regra, uma configuração que alguém
escolheu, não uma invasão.** Ninguém adivinhou uma senha. Um contêiner estava público, ou uma SAS viveu
por anos, ou uma chave de conta estava num arquivo que alguém publicou, e nada que alguém olhasse
dizia isso. Esta seção é o lado de quem defende: os três formatos, as configurações que eliminam cada
um e como perceber um que aconteceu mesmo assim. As configurações são conferidas com o Terraform; o
Defender for Storage e os logs foram escritos a partir da documentação da Microsoft e não foram
rodados.

## Três jeitos de um contêiner vazar

| formato | como acontece | o que impede |
|---|---|---|
| um contêiner público | um nível posto em `blob` ou `container` para um teste, ou para um arquivo público num contêiner de privados | o acesso anônimo da conta em false |
| uma SAS que vive demais | uma URL com validade de um ano, colada num chamado, num chat ou num repositório | validades curtas, políticas armazenadas, SAS de user delegation, uma política de expiração na conta |
| uma chave de conta à vista | uma cadeia de conexão enviada junto com o código, ou impressa num log | acesso por chave compartilhada desligado, Microsoft Entra ID para todo cliente |

**O terceiro é o pior**, porque a primeira seção desta lição mostrou o que uma chave faz, e porque o
único remédio, a rotação, quebra todo cliente honesto que ainda usa a chave antiga.

## A conta, endurecida

Crie um diretório para a declaração:

```sh
mkdir -p ~/azure/tf/hardened && cd ~/azure/tf/hardened
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

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  sas_policy {
    expiration_period = "00.01:00:00"
    expiration_action = "Block"
  }
}
```

```
ana@laptop:~/azure/tf/hardened$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/hardened$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/hardened$ sed -i 's/"TLS1_2"/"TLS1_0"/' main.tf && terraform validate -no-color

Error: expected min_tls_version to be one of ["TLS1_2"], got TLS1_0

  with azurerm_storage_account.data,
  on main.tf line 31, in resource "azurerm_storage_account" "data":
  31:   min_tls_version                 = "TLS1_0"
```

Linha por linha, pelo vazamento que cada uma fecha:

- **`allow_nested_items_to_be_public = false`** é a chave de acesso anônimo da conta, da seção
  anterior, com o nome que o provedor dá a ela. Nenhum contêiner da conta pode ser público.
- **`shared_access_key_enabled = false`** recusa toda requisição assinada com uma chave de conta,
  inclusive toda SAS assinada com uma. Os clientes entram com o Microsoft Entra ID no lugar, e uma SAS
  de user delegation continua funcionando, porque não é assinada com a chave da conta.
  `default_to_oauth_authentication` faz o portal agir do mesmo jeito.
- **`https_traffic_only_enabled` e `min_tls_version`** mantêm os dados cifrados no caminho. O provedor
  deste curso só aceita `TLS1_2`, como mostra a recusa, então as versões mais velhas do protocolo nem
  podem ser declaradas.
- **`sas_policy`** define a maior validade que uma SAS deveria ter, uma hora aqui, no formato
  `dias.horas:minutos:segundos` do provedor. Pela descrição da Microsoft, `Block` recusa uma requisição
  cuja SAS foi assinada por mais tempo, e `Log`, o outro valor do provedor, a deixa passar e registra.

Desligar as chaves compartilhadas é a linha mais forte e a que traz uma migração atrás: todo programa
das lições 2 a 5 assina com a chave, pela cadeia de conexão. Esses programas passariam a entrar com uma
identidade do Entra ID, que as bibliotecas suportam, e nada disso dá para testar contra o Azurite, que
só conhece a chave dele.

## Percebendo um vazamento

**O Defender for Storage** observa as requisições à conta e dispara alertas para padrões que a
Microsoft documenta, como acesso de um lugar incomum ou uma quantidade incomum de dados lidos, e, no
plano mais novo, examina blobs enviados em busca de malware. É um plano pago por conta de
armazenamento e é ligado no Microsoft Defender for Cloud.

**Os logs dizem quem leu o quê, e como.** Uma configuração de diagnóstico manda os logs do serviço de
blob para um workspace do Log Analytics, onde cada requisição vira uma linha na tabela
`StorageBlobLogs`. Uma das colunas, `AuthenticationType`, diz se a requisição foi assinada com a
chave, com uma SAS, com o Entra ID ou por ninguém. Uma consulta deste formato, em Kusto, a linguagem
de consulta do workspace, lista leituras anônimas por blob; ela não foi rodada neste curso:

```
StorageBlobLogs
| where AuthenticationType == "Anonymous" and OperationName == "GetBlob"
| summarize reads = count() by Uri
| order by reads desc
```

**A resposta a um vazamento segue a ordem da tabela acima.** Um contêiner público volta para `off` e a
chave da conta para false. Uma SAS de serviço vazada é revogada apagando a política armazenada dela,
ou, sem uma, girando a chave que a assinou; uma SAS de user delegation, revogando as delegation keys.
Uma chave de conta vazada é regenerada na hora, o que quebra todo cliente que a usa, e essa quebra é o
preço de ter usado a chave. Depois os logs respondem à pergunta que um relatório de incidente precisa
responder: o que foi lido, por quem, entre que horas.
