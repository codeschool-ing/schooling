---
title: O feed, lido do início e a partir de um token
version: 1
---

**Todo contêiner do Cosmos DB mantém um change feed, e nada precisa ser ligado para isso.** O feed são
os itens do contêiner listados na ordem em que foram gravados pela última vez, e um programa o lê do
jeito que lê uma consulta: em páginas, pagando unidades de requisição por elas. É assim que alguma
coisa fora do contêiner fica sabendo que um pedido foi pago sem perguntar a cada poucos segundos se há
algo novo. A Quitanda o usa para manter uma segunda visão dos pedidos, quanto cada cliente gastou, que
esta lição constrói.

**A ordem é garantida dentro de uma chave de partição e em nenhum outro lugar.** Duas mudanças nos
pedidos do cliente `c-7` saem na ordem em que foram feitas; uma mudança de `c-7` e uma de `c-8` saem na
ordem em que as partições delas forem lidas. É a chave de partição da lição 11 decidindo mais uma coisa,
e é o motivo de um consumidor do feed nunca depender de duas chaves chegarem numa ordem específica.

Esta seção é praticada. Com o emulador do Cosmos DB ligado como na lição 12, salve isto como `feed.py`
em `~/azure`. Ele grava seis vezes, depois lê o feed três vezes:

`feed.py`:

```python
import base64
import json

from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"), default_ttl=-1)

orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "paid", "totalCents": 4890})
orders.upsert_item({"id": "o-2", "customerId": "c-8", "status": "paid", "totalCents": 1250})
orders.upsert_item({"id": "o-3", "customerId": "c-7", "status": "paid", "totalCents": 7300})
orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "packed", "totalCents": 4890})
orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "delivered", "totalCents": 4890})
orders.delete_item("o-2", partition_key="c-8")
print("six writes: three creates, two updates of o-1, one delete of o-2")

for change in orders.query_items_change_feed(start_time="Beginning"):
    print("  from the beginning:", change["id"], change["status"], "lsn", change["_lsn"])
token = orders.client_connection.last_response_headers["etag"]
print("continuation:", json.loads(base64.b64decode(token))["continuation"]["continuation"])

print("again from the token:", list(orders.query_items_change_feed(continuation=token)))
orders.upsert_item({"id": "o-4", "customerId": "c-9", "status": "paid", "totalCents": 2100})
print("after one more write:", [c["id"] for c in orders.query_items_change_feed(continuation=token)])
```

```
ana@laptop:~/azure$ python feed.py
six writes: three creates, two updates of o-1, one delete of o-2
  from the beginning: o-3 paid lsn 3
  from the beginning: o-1 delivered lsn 5
continuation: [{'token': '"5"', 'range': {'min': '', 'max': 'FF', 'isMinInclusive': True, 'isMaxInclusive': False}}]
again from the token: []
after one more write: ['o-4']
```

**Seis escritas entraram e duas entradas saíram.** Esse é o assunto da próxima seção, e a versão curta
é que o feed lista cada item uma vez, como ele está agora: `o-1` como `delivered`, nunca como `paid` ou
`packed`, e `o-2` nem aparece, porque não existe mais. **Cada entrada traz `_lsn`, a posição dela no log
da partição**, 3 para `o-3` e 5 para `o-1`, o mesmo contador que o token de sessão da lição 12 nomeava.

**O token de continuação é onde o leitor parou, e é só dado.** A biblioteca o entrega no cabeçalho
`etag` da última página, JSON codificado em base64, e a linha que o decodifica mostra o que tem dentro:
para cada faixa do feed, o intervalo de hashes de chave de partição que ela cobre e a posição alcançada
nela, `"5"`. O emulador tem uma faixa do feed cobrindo todas as chaves, de `''` a `FF`. Um contêiner no
Azure com várias partições físicas tem uma entrada por faixa, e é assim que um token consegue dizer onde
o leitor está em cada uma ao mesmo tempo.

**Leia de novo a partir do token, e nada volta**; grave mais um pedido, e só ele volta. Esse é o
contrato sobre o qual o resto desta lição é construído. Um leitor que salva o token depois de cada lote
e o passa na vez seguinte vê cada mudança uma vez no caso normal, e nunca precisa perguntar ao
contêiner o que há de novo.

## Por onde um leitor pode começar

| `start_time` ou `continuation` | começa em |
|---|---|
| `"Beginning"` | a entrada mais antiga que o feed ainda tem |
| `"Now"` | a próxima mudança gravada depois da requisição |
| um `datetime` | a primeira mudança gravada naquele horário ou depois |
| um token salvo | logo depois da posição que o token registra |

Um consumidor novo de um contêiner existente escolhe entre os dois primeiros: do início, ele constrói a
visão a partir de todo item que existe; de agora, ele só se importa com o que acontecer daqui para
frente.
