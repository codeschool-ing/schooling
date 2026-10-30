---
title: O nível da conta, e pedir menos
version: 1
---

**O nível é uma propriedade da conta, e um cliente só pode pedir menos.** Toda leitura e toda
consulta é servida no padrão da conta, a não ser que a requisição diga outra coisa, e a documentação
da Microsoft permite que uma requisição peça um nível mais fraco que o padrão e nunca um mais forte.
Uma conta em sessão pode servir a página do catálogo em eventual, sem economizar unidades de
requisição mas lendo da cópia que estiver mais perto. Uma conta em eventual não pode servir uma
leitura em forte, porque as escritas nunca foram confirmadas do jeito que o forte precisa.

**As escritas ignoram a opção.** Uma escrita é confirmada do jeito que o nível da conta exige, diga a
requisição o que disser, e é por isso que a escolha por requisição vale só para leituras.

## No emulador

O `overriding.py` pergunta à conta do emulador o nível padrão dela, e depois lê um pedido por quatro
clientes, cada um criado num nível diferente. O último nem é um nível:

`overriding.py`:

```python
from azure.cosmos import CosmosClient

URL = "http://localhost:8081"
KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="

account = CosmosClient(URL, KEY).get_database_account()
print("the account's default:", account.ConsistencyPolicy["defaultConsistencyLevel"])

for level in ["Eventual", "Session", "Strong", "Linearizable"]:
    client = CosmosClient(URL, KEY, consistency_level=level)
    orders = client.get_database_client("quitanda").get_container_client("orders")
    orders.read_item("o-1002", "c-7")
    charge = orders.client_connection.last_response_headers["x-ms-request-charge"]
    print(f"{level:13} read answered, request charge {charge}")
```

Rode depois do `session.py`, que gravou o pedido que ele lê:

```
ana@laptop:~/azure$ python overriding.py
the account's default: Eventual
Eventual      read answered, request charge 1
Session       read answered, request charge 1
Strong        read answered, request charge 1
Linearizable  read answered, request charge 1
```

**Quatro respostas, uma unidade de requisição cada, e nenhuma delas foi conferida.** A conta do
emulador diz `Eventual`, que não é o que o Azure dá a uma conta nova: lá o padrão é sessão. Uma
leitura forte numa conta eventual é a requisição que a documentação da Microsoft diz que não pode ser
feita, e o emulador a serviu. `Linearizable` é uma palavra da teoria de sistemas distribuídos e não é
um dos níveis do Cosmos DB; a biblioteca a mandou como o cabeçalho `x-ms-consistency-level` e o
emulador serviu essa também. A cobrança de um é de novo o marcador da lição 1. No Azure aquela
leitura forte, numa conta em eventual, nem teria sido servida; numa conta em forte, teria custado
cerca do dobro da leitura de sessão, como a seção anterior explicou.

Então **o nível em que um programa roda é aquele com que a conta foi criada, menos o que o cliente
pediu para abrir mão**, e o emulador não confirma nenhuma das duas metades. Leia o nível da conta na
declaração dela, que é a próxima seção, e trate o `consistency_level` de um cliente como um jeito de
abrir mão de alguma coisa, nunca de ganhar alguma coisa.

## Onde a biblioteca recebe o nível

Na versão 4.17.1 da biblioteca Python o nível é um argumento do `CosmosClient`, como acima, e vale
para toda requisição que aquele cliente faz. O `read_items`, que lê vários itens numa chamada, aceita
um próprio; o `read_item` e o `query_items` não listam nenhum na documentação da biblioteca. Um
programa que precisa de dois níveis guarda então dois clientes, e um cliente é caro de criar, então
ele os mantém pela vida inteira em vez de criar um por requisição.
