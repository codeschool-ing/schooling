---
title: Chaves de partição hierárquicas, para o cliente que não cabe numa
version: 1
---

**Uma chave de partição hierárquica é uma chave de até três níveis**, como `/customerId` e depois
`/orderMonth`, e existe para o caso que a seção anterior deixou de lado: um único valor que passa de
20 GB, ou da carga que uma partição física aguenta. Com uma chave simples, todo pedido do cliente mais
ativo é uma partição lógica, que nunca pode ser dividida. Com uma chave hierárquica, cada par de
cliente e mês é uma partição lógica própria, então o histórico do cliente mais ativo pode se espalhar
por muitas partições físicas. Uma consulta que nomeia só o cliente continua sendo enviada às partições
que guardam aquele cliente e a nenhuma outra.

Os clientes empresariais da Quitanda, os restaurantes do topo da tabela anterior, são o motivo de ela
considerar uma. O emulador aceita o tipo de chave que o Azure chama de `MultiHash`. Salve isto como
`~/azure/hier.py`:

`hier.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")
by_month = db.create_container_if_not_exists(
    "orders_by_month", PartitionKey(path=["/customerId", "/orderMonth"], kind="MultiHash"))
print(by_month.read()["partitionKey"])

for n, month in enumerate(["2026-08", "2026-09", "2026-10", "2026-10"]):
    by_month.upsert_item({"id": f"o-{n}", "customerId": "c-0", "orderMonth": month,
                          "totalCents": 2000 + n})

item = by_month.read_item("o-3", partition_key=["c-0", "2026-10"])
print("point read needs both levels:", item["id"], item["orderMonth"])
october = list(by_month.query_items("SELECT VALUE c.id FROM c", partition_key=["c-0", "2026-10"]))
print("one customer, one month:", october)
everything = list(by_month.query_items("SELECT VALUE c.id FROM c", partition_key=["c-0"]))
print("one customer, by the first level only:", everything)
```

```
ana@laptop:~/azure$ python hier.py
{'kind': 'MultiHash', 'paths': ['/customerId', '/orderMonth'], 'version': 2}
point read needs both levels: o-3 2026-10
one customer, one month: ['o-2', 'o-3']
one customer, by the first level only: ['o-0', 'o-1', 'o-2', 'o-3']
```

**A chave é uma lista de caminhos com `kind` igual a `MultiHash`**, e é fixada na criação como qualquer
outra. Uma leitura pontual precisa de todos os níveis, os dois valores aqui. Uma consulta pode nomear
todos eles, e chegar a uma partição lógica, ou só os primeiros, um **prefixo**, e chegar a toda
partição lógica debaixo daquele cliente: os quatro pedidos de `c-0` em três meses.

**O que esta execução mostra é a forma, não o roteamento.** O emulador tem uma partição física, então
toda consulta aqui foi respondida pela mesma. No Azure, o comportamento documentado é que uma consulta
que nomeia o prefixo vai só às partições físicas que o guardam, e uma consulta que não nomeia nível
nenhum vai a todas. Isso não foi rodado.

## Quando vale a pena

**Uma chave hierárquica cobra uma segunda coisa a saber em toda leitura pontual**, o mês além do
cliente, e esse é um preço que a aplicação paga em toda linha que lê. Vale pagar quando um valor do
primeiro nível vai passar de uma partição lógica, como faz um inquilino de um sistema multi-inquilino
ou um cliente que é uma rede de restaurantes. Para os clientes comuns da Quitanda, algumas centenas de
pedidos cada, o `/customerId` simples da seção anterior é mais simples e basta. O próprio conselho da
documentação é recorrer à hierarquia quando os dados ou a carga de um único valor são o problema, e
não antes.
