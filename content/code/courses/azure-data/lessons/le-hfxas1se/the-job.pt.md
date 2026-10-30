---
title: Um job é uma entrada, uma consulta e uma saída
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi executado contra o
Stream Analytics.** Não existe emulador do serviço. O que rodou foi o Terraform conferindo uma
declaração de job sem rede, e as três seções seguintes executam a ideia por baixo com um programa
curto do próprio curso, que não é o Stream Analytics e diz isso toda vez.

**O Azure Stream Analytics roda uma consulta SQL sobre um stream, continuamente, enquanto o job
estiver iniciado.** Uma consulta em lote lê uma tabela que existe e termina; uma consulta do Stream
Analytics lê eventos que ainda não aconteceram e nunca termina. A resposta dela não é um conjunto de
resultados, mas outro stream: linhas gravadas numa saída toda vez que a consulta tem algo a dizer,
por exemplo a cada minuto para uma contagem por minuto.

O primeiro job da Quitanda conta checkouts por minuto para uma tela na sala de operações. Ele tem
três partes, como todo job:

| parte | o que é | a da Quitanda |
|---|---|---|
| entrada | de onde vêm os eventos | o event hub `clicks`, lido por um grupo de consumidores próprio |
| consulta | uma instrução, ou várias, na linguagem de consulta do Stream Analytics | contar os cliques em `/checkout` por minuto |
| saída | para onde vão as linhas | uma tabela no Azure SQL Database que a tela lê |

**Uma entrada de stream é um event hub, um IoT hub, ou arquivos chegando no Blob Storage ou no Data
Lake Storage.** Um job também pode ter **entradas de referência**, tabelas pequenas com que ele junta
o stream, lidas do Blob Storage ou do Azure SQL Database e atualizadas num horário; uma lista das
lojas da Quitanda com os bairros é o tipo de coisa que vai ali. As saídas são muitas, e o provider do
Azure para Terraform tem um tipo de recurso para cada uma, o que dá uma boa lista delas: Blob
Storage, Event Hubs, filas e tópicos do Service Bus, Table storage, Azure SQL Database, Synapse,
Cosmos DB, Power BI e Azure Functions.

## A consulta

A linguagem é SQL com um punhado de acréscimos para o tempo. O job que conta checkouts:

```sql
SELECT System.Timestamp() AS window_end, COUNT(*) AS checkouts
INTO [checkouts-per-minute]
FROM [clicks] TIMESTAMP BY at
WHERE page = '/checkout'
GROUP BY TumblingWindow(minute, 1)
```

Leia como o SQL de `sql-databases`, com três diferenças. **`FROM [clicks]` e `INTO
[checkouts-per-minute]` nomeiam a entrada e a saída do job** pelos apelidos que receberam quando o
job foi configurado, não tabelas. **`TIMESTAMP BY at` diz qual campo do evento guarda a hora em que
a coisa aconteceu**, e a próxima seção trata de por que essa cláusula decide se a contagem está
certa. **`GROUP BY TumblingWindow(minute, 1)`** agrupa por janelas de um minuto dessa hora, e
`System.Timestamp()` é o fim da janela a que uma linha pertence. Os campos `at` e `page` saem do
corpo JSON de cada evento: o Stream Analytics, ao contrário do Event Hubs, olha dentro dele, e a
entrada diz que o corpo é JSON.

Uma consulta não pode ser testada no serviço sem um job, e um job precisa de uma assinatura. A
Microsoft publica um jeito de testar uma consulta localmente, pela extensão do Stream Analytics para
o Visual Studio Code, que a executa contra um arquivo de eventos de exemplo no seu computador. Este
curso não a instala, porque é uma extensão de editor e não algo que um terminal consiga registrar.

## Declarando o job

O job e a consulta, declarados em Terraform. A consulta fica dentro do arquivo como um bloco de
texto, então revisar a lógica do job é revisar este arquivo. Num diretório próprio, como a lição 1
mostrou:

```sh
mkdir -p ~/azure/tf/asa && cd ~/azure/tf/asa
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

resource "azurerm_stream_analytics_job" "checkouts" {
  name                                     = "asa-quitanda-checkouts-prd"
  resource_group_name                      = azurerm_resource_group.stream.name
  location                                 = azurerm_resource_group.stream.location
  compatibility_level                      = "1.2"
  streaming_units                          = 3
  events_out_of_order_max_delay_in_seconds = 20
  events_out_of_order_policy               = "Adjust"
  events_late_arrival_max_delay_in_seconds = 60
  output_error_policy                      = "Stop"

  transformation_query = <<QUERY
SELECT System.Timestamp() AS window_end, COUNT(*) AS checkouts
INTO [checkouts-per-minute]
FROM [clicks] TIMESTAMP BY at
WHERE page = '/checkout'
GROUP BY TumblingWindow(minute, 1)
QUERY
}
```

```
ana@laptop:~/azure/tf/asa$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/asa$ terraform validate -no-color
Success! The configuration is valid.
```

**Válido, e isso não diz nada sobre a consulta.** Para o provider, `transformation_query` é uma
string; um `TumblingWindw` com erro de digitação também passaria no `validate`, e só o serviço o
recusaria, quando o job fosse criado ou iniciado. As entradas e saídas são recursos próprios,
`azurerm_stream_analytics_stream_input_eventhub` e `azurerm_stream_analytics_output_mssql` entre
eles, e ficaram de fora aqui porque cada uma precisa de uma chave ou senha para aquilo que lê ou
grava, que é assunto da lição 6 e não desta. As três linhas `events_` são as configurações de que
esta lição trata, e a seção sobre dados atrasados volta a elas.
