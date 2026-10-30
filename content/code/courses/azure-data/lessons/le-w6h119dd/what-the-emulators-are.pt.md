---
title: O que são os emuladores, e onde eles param
version: 1
---

**Todo emulador deste curso é da própria Microsoft, ou é o motor de código aberto que o Azure roda
como serviço gerenciado.** Essa é a boa notícia: um blob que o Azurite guarda, um documento que o
emulador do Cosmos DB devolve e um evento que o emulador do Event Hubs entrega voltam pelo mesmo
protocolo, pelas mesmas bibliotecas e pela mesma linha de comando que no Azure. Um código que funciona
contra eles precisa de outra connection string e de nada mais para rodar contra uma conta de verdade.

A má notícia está no que eles deixam de fora, e é sempre a mesma coisa: **um emulador responde ao
plano de dados de um serviço, e a nada acima dele.** Não há assinatura, nem grupo de recursos, nem
conta de armazenamento para criar, nem papel para atribuir, nem regra de rede, nem métrica, nem
fatura. Isso é o plano de controle, o Azure Resource Manager, e nenhum emulador em lugar nenhum
responde a ele.

## O que responde, e o que não responde

| serviço | neste curso | o que ele responde | o que ele não responde |
|---|---|---|---|
| Blob Storage, Queue, Table | Azurite 3.37.0 | contêineres, blobs, camadas, SAS | regras de ciclo de vida, exclusão reversível, versionamento, o endpoint do Data Lake |
| Cosmos DB | o emulador vNext | bancos, contêineres, itens, consultas, change feed | níveis de consistência, unidades de requisição reais, throttling, regiões |
| Event Hubs | o emulador 2.2.1 | partições, grupos de consumidores, envio, leitura | captura para o armazenamento, unidades de throughput, a escala compatível com Kafka |
| Azure SQL, Managed Instance | SQL Server 2025 | o motor, o T-SQL, os planos de consulta | modelos de compra, pausa do serverless, pools elásticos, failover |
| PostgreSQL servidor flexível | PostgreSQL 17.6 | o motor | alta disponibilidade, os parâmetros do servidor que o Azure trava |
| Azure Cache for Redis | Redis 8.2.2 | o motor | camadas, clustering entre shards, aplicação de patches |
| Synapse, Fabric, Databricks, Data Factory, Stream Analytics, Purview | nada | | tudo |

**A última linha são sete das vinte e seis lições do curso, e elas são ensinadas a partir da
documentação da Microsoft, marcadas como não executadas.** Onde uma delas trabalha com um formato de
arquivo ou uma ideia que roda num notebook, como Parquet, Delta Lake ou uma janela sobre um stream, a
lição roda essa parte com uma ferramenta aberta e diz claramente qual ferramenta fez isso. Nenhuma
seção deste curso mostra uma resposta que parece a do Azure e foi produzida por outra coisa.

## Responder não é conferir

A lacuna mais perigosa é mais quieta. **Um emulador pode aceitar uma requisição e não fazer o que
prometeu**, e o único sintoma é que nada dá errado. Dois exemplos, um de cada ponta do curso.

O emulador do Cosmos DB informa um custo de requisição em toda resposta, que é como o Azure cobra um
banco de dados, em unidades de requisição. Este programa grava um documento pequeno e depois roda uma
consulta que precisa ler todas as partições, o que no Azure é cobrado pelo trabalho feito, partição
por partição:

`ru.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"))

orders.upsert_item({"id": "o-1", "customerId": "c-7", "totalCents": 4890})
print("write:", orders.client_connection.last_response_headers["x-ms-request-charge"])

found = list(orders.query_items("SELECT * FROM c WHERE c.totalCents > 100",
                                enable_cross_partition_query=True))
print("query across partitions:", orders.client_connection.last_response_headers["x-ms-request-charge"])
```

A chave é a do próprio emulador, publicada pela Microsoft e a mesma em todo computador. Ligue o
emulador, que leva uns dez segundos para responder, e rode o programa:

```
ana@laptop:~/azure$ docker compose --profile cosmos up -d 2>&1 | tail -1
 Container azure-cosmos-1 Started 
ana@laptop:~/azure$ python ru.py
write: 1
query across partitions: 1
```

**Uma unidade de requisição para as duas operações, e para tudo o mais que você perguntar.** O número
é um marcador de lugar, não uma medida. A lição 13 é sobre unidades de requisição e as ensina a partir
da documentação da Microsoft exatamente por isso: o emulador ensinaria que toda operação custa o
mesmo, que é a única crença que faz de uma fatura do Cosmos DB uma surpresa.

O Azurite faz o mesmo com o tempo. Um blob movido para a camada de arquivo no Azure leva até quinze
horas para voltar; no Azurite ele volta no momento em que você pede, como mostra a lição 4. Nenhum dos
dois emuladores está errado em fazer isso. Eles são feitos para testar a lógica de um programa,
rápido, e deixam custo e tempo de fora de propósito. **Este curso aponta cada um desses lugares onde
encontra um**, sob um título que diz isso. E a regra para ler qualquer transcrição dele é sempre a
mesma: **um sucesso aqui prova que o seu comando ou o seu programa está bem formado, nunca que o Azure
cobraria, esperaria ou permitiria o que o emulador fez.**
