---
title: Conta, banco, contêiner, item
version: 1
---

**O Cosmos DB guarda documentos JSON, que ele chama de itens, em contêineres, e todo contêiner é
criado com uma chave de partição que ele nunca pode mudar.** As camadas de cima são simples: uma conta
é o endereço e a fatura, `quitanda-prd.documents.azure.com` no Azure, e guarda bancos; um banco é um
espaço de nomes que agrupa contêineres. O contêiner é onde tudo o que importa é decidido, e a chave de
partição, um caminho dentro de cada item como `/customerId`, é a primeira dessas decisões. Esta lição é
sobre essa escolha, porque todas as seguintes, o custo de uma leitura, o limite de uma escrita e a
forma da fatura, saem dela.

O emulador do Cosmos DB da lição 1 responde a tudo isso, menos à conta, que é uma conta fixa que o
emulador sempre tem, como o `devstoreaccount1` do Azurite. Suba-o em `~/azure`; ele leva uns dez
segundos para responder:

```sh
docker compose --profile cosmos up -d
```

Depois, um primeiro contêiner para os pedidos da Quitanda, particionado por cliente, e dois itens.
Salve isto como `~/azure/model.py`:

`model.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey, exceptions

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"))

orders.upsert_item({"id": "o-1001", "customerId": "c-17", "totalCents": 4890})
orders.upsert_item({"id": "o-1001", "customerId": "c-18", "totalCents": 1250})
same = list(orders.query_items("SELECT c.customerId FROM c WHERE c.id = 'o-1001'",
                               enable_cross_partition_query=True))
print("items called o-1001:", same)

try:
    orders.create_item({"id": "o-1001", "customerId": "c-17", "totalCents": 999})
except exceptions.CosmosHttpResponseError as e:
    print("o-1001 again in c-17:", e.status_code, e.reason)

item = orders.read_item("o-1001", partition_key="c-17")
print("system properties:", sorted(k for k in item if k.startswith("_")))

try:
    orders.upsert_item({"id": "o-big", "customerId": "c-17", "note": "x" * 2_100_000})
except exceptions.CosmosHttpResponseError as e:
    print("an item of 2.1 MB:", e.status_code, e.reason)
```

```
ana@laptop:~/azure$ python model.py
items called o-1001: [{'customerId': 'c-17'}, {'customerId': 'c-18'}]
o-1001 again in c-17: 409 Conflict
system properties: ['_attachments', '_etag', '_rid', '_self', '_ts']
an item of 2.1 MB: 413 Payload Too Large
```

**Dois itens chamados `o-1001` moram num contêiner**, porque um `id` só é único dentro de um valor da
chave de partição: o `o-1001` do cliente `c-17` e o `o-1001` do `c-18` são itens diferentes. Escrever
o primeiro de novo com `create_item` é recusado com `409 Conflict`, a resposta que o `upsert_item`
teria evitado substituindo-o. **Então a identidade de um item é o par, o valor da chave de partição e
o `id`**, e uma leitura pontual, `read_item`, precisa dos dois.

As propriedades que começam com sublinhado são do serviço: `_rid` é o id interno, `_self` o endereço,
`_etag` muda a cada escrita e torna possíveis as atualizações condicionais, e `_ts` é o momento da
última escrita, em segundos desde 1970; `_attachments` é uma que este curso não usa. **E um item tem
teto de 2 MB**, que o emulador aplica como o Azure documenta: a nota de 2,1 MB foi recusada com `413`.
Um documento que pode crescer além disso, um pedido com uma lista sem limite de eventos dentro dele, é
um desenho que um dia vai falhar numa escrita.
