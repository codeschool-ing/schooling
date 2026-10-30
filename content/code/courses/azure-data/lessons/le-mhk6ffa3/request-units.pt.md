---
title: A unidade de requisição, e o que a move
version: 1
---

**O Cosmos DB não cobra por requisição, por tempo ou por bytes lidos; cobra por unidades de
requisição**, um número por operação que representa o processador, a memória e a entrada e saída que
a operação usou. A Microsoft fixa um ponto na escala e deixa o resto para a medição: **ler um item de
1 KB pelo id e pela chave de partição custa uma unidade de requisição.** Isso é uma leitura pontual, a
coisa mais barata que o Cosmos DB faz, e todo o resto tem preço em relação a ela.

Esta seção é ensinada a partir da documentação da Microsoft, com um programa rodado no emulador para
mostrar por que o emulador não consegue ensiná-la.

## O que faz uma operação custar mais

Não existe fórmula publicada, só os fatores, e eles se somam:

| fator | por que custa |
|---|---|
| o tamanho do item | um item de 9 KB são mais bytes para ler, gravar e indexar que um de 1 KB |
| a indexação | toda propriedade é indexada por padrão, e cada propriedade indexada é trabalho em toda escrita |
| o tipo de operação | uma escrita custa mais que uma leitura do mesmo item, e um update é uma escrita |
| a consistência | leituras em forte e em desatualização limitada custam cerca do dobro, como mostrou a lição 12 |
| a consulta | os filtros e funções dela, quantos itens ela lê e devolve, e quantas partições ela visita |

**Uma consulta que nomeia a chave de partição vai para uma partição física; uma que não nomeia é
mandada para todas**, e cada uma responde com a sua cobrança. O espalhamento é o argumento da lição 11
a favor da chave de partição, visto pela conta. E a cobrança é determinística: a mesma operação nos
mesmos dados custa o mesmo toda vez, e é isso que faz valer a pena medir uma vez e multiplicar.

## Onde está o número

**Toda resposta traz a cobrança no cabeçalho `x-ms-request-charge`.** A biblioteca Python guarda os
cabeçalhos da última resposta na conexão do cliente do contêiner, como o `ru.py` da lição 1 os leu.
Numa conta real esse cabeçalho é a medição de onde toda estimativa desta lição deve partir: grave um
item realista, leia-o, rode cada consulta que a aplicação roda, e anote os números.

No emulador ele não é uma medição. Este programa grava um produto de cerca de 1 KB e um de cerca de
9 KB, lê os dois, e roda uma consulta dentro de uma partição e outra através de todas. Salve como
`charges.py` em `~/azure`, com o emulador ligado como na lição 12:

`charges.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
products = db.create_container_if_not_exists("products", PartitionKey("/category"))


def charge(what):
    print(f"{what:34}", products.client_connection.last_response_headers["x-ms-request-charge"])


small = {"id": "cafe-500g", "category": "mercearia", "description": "x" * 900}
large = {"id": "cafe-1kg", "category": "mercearia", "description": "x" * 9000}
products.upsert_item(small); charge("write, about 1 KB")
products.upsert_item(large); charge("write, about 9 KB")
products.read_item("cafe-500g", "mercearia"); charge("point read, about 1 KB")
products.read_item("cafe-1kg", "mercearia"); charge("point read, about 9 KB")
list(products.query_items("SELECT * FROM p WHERE p.category = 'mercearia'",
                          partition_key="mercearia")); charge("query inside one partition")
list(products.query_items("SELECT * FROM p WHERE CONTAINS(p.description, 'y')",
                          enable_cross_partition_query=True)); charge("query across partitions")
```

```
ana@laptop:~/azure$ python charges.py
write, about 1 KB                  1
write, about 9 KB                  1
point read, about 1 KB             1
point read, about 9 KB             1
query inside one partition         1
query across partitions            1
```

**Seis operações, seis uns.** No Azure a primeira leitura pontual seria a unidade que a Microsoft
fixa, a leitura de 9 KB custaria mais, as duas escritas custariam mais que qualquer das leituras, e a
consulta entre partições somaria uma cobrança para cada partição visitada. O emulador informa o
cabeçalho com o nome certo, no lugar certo, guardando um marcador, que é o número errado mais
convincente que um notebook consegue produzir. **Neste curso as unidades de requisição são contadas no
papel, a partir da âncora da Microsoft e de cobranças que você mede numa conta, e nunca lidas no
emulador.**

A Microsoft também publica um planejador de capacidade, um formulário na web que estima unidades de
requisição a partir de tamanhos de item e contagens de operações. Ele não foi usado aqui, e a resposta
dele também é uma estimativa: o cabeçalho numa conta real é o único número que não é.
