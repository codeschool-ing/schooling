---
title: O Capture, o stream copiado para o armazenamento
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.** O emulador do
Event Hubs não tem Capture, como a lição 1 listou, e a única coisa aqui que rodou é o Terraform
conferindo uma declaração dele sem rede.

**O Capture é um recurso do event hub que grava tudo o que é enviado a ele no Blob Storage ou no Data
Lake Storage, sem nenhum programa seu no meio.** É a resposta para a metade do problema da Quitanda
que é dos analistas: cada clique no lake de manhã, guardado por anos, enquanto o hub os esquece
depois de um dia. Sem ele alguém escreve um leitor como o `checkpointed.py` cujo único trabalho é
acrescentar eventos a arquivos, põe para rodar, vigia e paga por ele; com ele, esse leitor é uma
configuração.

## O que ele grava

**O Capture grava arquivos Avro, uma sequência de arquivos por partição.** Avro é um formato binário
que leva o esquema no topo de cada arquivo, e cada registro de um arquivo do Capture guarda um
evento: o corpo dele em bytes, intocado, ao lado do número de sequência, do offset, do enqueued time
e das propriedades que o serviço e o produtor puseram nele. O Event Hubs continua sem olhar dentro do
corpo, então o JSON do clique está lá como JSON, embrulhado em Avro.

**Um arquivo é fechado por tempo ou por tamanho, o que vier primeiro.** A janela de tempo vai de 1 a
15 minutos e a de tamanho de 10 MB a 500 MB, segundo a documentação; com uma janela de cinco minutos
e o tráfego da Quitanda, cada partição produz um arquivo a cada cinco minutos. Os arquivos são
nomeados por um padrão montado com o namespace, o hub, a partição e a hora:

```
{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}
```

Essas são as partes padrão, todas obrigatórias, e podem ser arrumadas em outra ordem. As partes de
data são o que as lições do lake deste curso precisam: uma consulta sobre um dia lê os diretórios de
um dia, o que a lição 18 chama de poda de partições. Uma janela sem eventos grava um arquivo vazio, a
menos que o hub seja instruído a pular arquivos vazios, e um analista que conta arquivos aprende a
distinguir os dois.

**Avro é um bom formato para escrever e um formato ruim para consultar.** Ele é gravado linha a
linha, e é por isso que o Capture consegue produzi-lo à medida que os eventos chegam, e um motor de
consulta que o lê tem que ler cada byte de cada linha, o oposto dos arquivos Parquet e Delta das
lições 16 a 18. O pipeline de costume deixa o Avro do Capture como a camada bruta e o converte num
horário marcado, o que é um job do Data Factory da lição 19 ou um notebook da lição 20.

## Declarando, e o que o `validate` não vê

A declaração do namespace, do hub com Capture e do grupo `fraud`, em Terraform. A lição 1 mostrou o
padrão: um diretório por assunto, o arquivo abaixo dentro dele, e um `init` uma vez.

```sh
mkdir -p ~/azure/tf/stream && cd ~/azure/tf/stream
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

resource "azurerm_resource_group" "stream" {
  name     = "rg-quitanda-stream-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "lake" {
  name                     = "stquitandalakeprd"
  resource_group_name      = azurerm_resource_group.stream.name
  location                 = azurerm_resource_group.stream.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "capture" {
  name               = "clicks-capture"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_eventhub_namespace" "app" {
  name                     = "evhns-quitanda-app-prd"
  resource_group_name      = azurerm_resource_group.stream.name
  location                 = azurerm_resource_group.stream.location
  sku                      = "Standard"
  capacity                 = 2
  auto_inflate_enabled     = true
  maximum_throughput_units = 6
}

resource "azurerm_eventhub" "clicks" {
  name              = "clicks"
  namespace_id      = azurerm_eventhub_namespace.app.id
  partition_count   = 4
  message_retention = 1

  capture_description {
    enabled             = true
    encoding            = "Avro"
    interval_in_seconds = 300
    size_limit_in_bytes = 314572800
    skip_empty_archives = true

    destination {
      name                = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = azurerm_storage_container.capture.name
      storage_account_id  = azurerm_storage_account.lake.id
    }
  }
}

resource "azurerm_eventhub_consumer_group" "fraud" {
  name                = "fraud"
  namespace_name      = azurerm_eventhub_namespace.app.name
  eventhub_name       = azurerm_eventhub.clicks.name
  resource_group_name = azurerm_resource_group.stream.name
}
```

```
ana@laptop:~/azure/tf/stream$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/stream$ terraform validate -no-color
Success! The configuration is valid.
```

**A capacidade fica no namespace; as partições e o Capture ficam no hub.** `capacity = 2` são duas
unidades de taxa de transferência divididas por todos os hubs do namespace, e o
`auto_inflate_enabled` deixa o Azure subir isso até seis numa noite movimentada; a última seção desta
lição trata das duas coisas. O `is_hns_enabled` faz do destino uma conta do Data Lake Storage, o
namespace hierárquico da lição 3, onde o Capture grava como em qualquer outra. `message_retention = 1`
é um dia, porque a cópia que fica é a que o Capture grava. A janela é de 300 segundos e 314.572.800
bytes, que são 300 MB.

Agora duas mudanças, e o Azure recusaria cada uma delas:

```
ana@laptop:~/azure/tf/stream$ sed -i 's/interval_in_seconds = 300/interval_in_seconds = 30/' main.tf && terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/stream$ sed -i 's/= 30$/= 300/; /sku /s/"Standard"/"Dedicated"/' main.tf && terraform validate -no-color

Error: expected sku to be one of ["Basic" "Premium" "Standard"], got Dedicated

  with azurerm_eventhub_namespace.app,
  on main.tf line 37, in resource "azurerm_eventhub_namespace" "app":
  37:   sku                      = "Dedicated"
```

**A primeira mudança passou e a segunda não, e as duas estão erradas.** Uma janela de 30 segundos
fica abaixo do mínimo documentado de um minuto; o esquema do provider não codifica essa regra, então o
`validate` aceita e o erro viria do Azure, durante o `apply`. `Dedicated` não é uma camada em que se
cria um namespace: um cluster Dedicated é um recurso próprio, `azurerm_eventhub_cluster`, onde os
namespaces são colocados depois, e o provider conhece a lista de valores de `sku` do namespace. O que
a lição 1 ensinou vale aqui também: o `validate` pega o que o esquema conhece, e só um `apply` contra
uma assinatura de verdade pegaria o resto.
