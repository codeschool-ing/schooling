---
title: Todas as versões e exclusões
version: 1
---

**O segundo modo do feed guarda toda mudança, exclusões inclusive**: todas as versões e exclusões. Cada
entrada traz o item como ele ficou, a operação que o fez, `create`, `replace` ou `delete`, e a posição
dela no log. É o que uma trilha de auditoria ou uma cópia para outro sistema precisa, e é o modo em que
o `paid`, o `packed` e o `delivered` de um pedido são três entradas e não uma.

**Ele precisa ser ligado no contêiner, e não guarda mudanças para sempre.** No emulador a chave é uma
política de change feed com um período de retenção em minutos, definida quando o contêiner é criado. No
Azure a documentação amarra o modo ao backup contínuo da conta, e só guarda mudanças pelo tempo de
retenção desse backup, então um leitor que fica mais atrasado que isso perde o que aconteceu no meio.
Um leitor também não pode começar este modo do início, só de agora ou de um token salvo, como diz a
própria descrição de `query_items_change_feed` na biblioteca Python, porque não há início de onde
começar: o histórico só existe a partir de quando foi ligado.

Esta parte é praticada. O `versions.py` primeiro pergunta ao contêiner `orders` das seções anteriores,
que não tem política, e depois cria o `orders-audited` com uma, tentando 60 minutos de retenção antes de
10. Ele pega um token em "agora", e grava, muda e apaga um pedido. Salve e rode:

`versions.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")

orders = db.get_container_client("orders")
try:
    list(orders.query_items_change_feed(mode="AllVersionsAndDeletes", start_time="Now"))
except Exception as e:
    print("orders:", e.message.splitlines()[0])

try:
    db.create_container_if_not_exists("orders-audited", PartitionKey("/customerId"),
                                      change_feed_policy={"retentionDuration": 60})
except Exception as e:
    print("60 minutes:", e.message.splitlines()[0])
audit = db.create_container_if_not_exists("orders-audited", PartitionKey("/customerId"),
                                          change_feed_policy={"retentionDuration": 10})
list(audit.query_items_change_feed(mode="AllVersionsAndDeletes", start_time="Now"))
token = audit.client_connection.last_response_headers["etag"]

audit.upsert_item({"id": "o-6", "customerId": "c-7", "status": "paid", "totalCents": 3100})
audit.upsert_item({"id": "o-6", "customerId": "c-7", "status": "packed", "totalCents": 3100})
audit.delete_item("o-6", partition_key="c-7")

for change in audit.query_items_change_feed(continuation=token):
    meta, now, before = change["metadata"], change.get("current"), change.get("previous")
    print(f"lsn {meta['lsn']}  {meta['operationType']:8} now: {now and now['status']}, before: {before and before['status']}")
```

```
ana@laptop:~/azure$ python versions.py
orders: (BadRequest) All versions and deletes requires an enabled changeFeedPolicy.
60 minutes: (BadRequest) 'changeFeedPolicy.retentionDuration' must be an integer from 1 through 10, or 0 to disable.
lsn 10  create   now: paid, before: None
lsn 11  replace  now: packed, before: paid
lsn 12  delete   now: None, before: packed
```

**O contêiner sem política recusou o modo**, com uma frase que diz exatamente o que falta. **O que tem
política devolveu três entradas para um pedido**: a criação, a substituição de `paid` para `packed`, e a
exclusão, que não traz item atual, só o anterior. Essa última entrada é o que a última versão nunca
consegue dar, e é por isso que uma exclusão não precisa mais da dança de marca e time to live da seção
anterior quando este modo está disponível.

**O período de retenção tem uma regra própria do emulador**: com 60 minutos pedidos, ele respondeu que
`retentionDuration` precisa estar entre 1 e 10, então o `versions.py` pede de novo com 10. Esse limite é
do emulador. No Azure a retenção é o período de backup contínuo da conta, e nada neste curso o mediu. A
imagem `previous` na substituição também é resposta do emulador; confira numa conta que a sua versão do
serviço a devolve antes de um projeto depender dela.
