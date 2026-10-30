---
title: Três leituras, e o único número que o emulador erra
version: 1
---

**Uma leitura pontual, uma consulta numa partição e uma consulta entre partições são três operações
diferentes**, e no Azure têm três preços diferentes. Esta seção roda as três contra o emulador, conta o
que cada uma envia e lê a cobrança que o Cosmos DB anexa a toda resposta. Salve isto como
`~/azure/reads.py`:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"Three ways to read Quitanda's orders, and what each one sends.\"\"\"\nimport collections\nfrom azure.cosmos import CosmosClient, PartitionKey\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\nsent = collections.Counter()\n\n\ndef count(request):\n    sent[\"requests\"] += 1\n\n\nclient = CosmosClient(\"http://localhost:8081\", KEY, raw_request_hook=count)\ndb = client.create_database_if_not_exists(\"quitanda\")\norders = db.create_container_if_not_exists(\"orders\", PartitionKey(\"/customerId\"))\n", "note": "**O mesmo gancho do `count.py` da lição 7**, porque a biblioteca do Cosmos DB é construída sobre o mesmo núcleo que a do Blob Storage: toda requisição HTTP que ela envia passa antes pelo `count`. O contêiner é o da seção anterior, particionado por cliente."}, {"code": "\nfor n in range(1000):\n    orders.upsert_item({\"id\": f\"o-{n}\", \"customerId\": f\"c-{n % 100}\",\n                        \"totalCents\": 1500 + n * 37 % 30000})\n", "note": "Mil pedidos de cem clientes, dez cada, escritos uma requisição por vez."}, {"code": "\n\ndef measure(name, read):\n    sent.clear()\n    items = read()\n    charge = orders.client_connection.last_response_headers[\"x-ms-request-charge\"]\n    print(f\"{name:<26}{sent['requests']:>2} request(s){charge:>6} RU{len(items):>5} item(s)\")\n", "note": "**Toda resposta do Cosmos DB carrega o próprio preço num cabeçalho**, `x-ms-request-charge`, em request units. O `measure` roda uma leitura e imprime as requisições que ela levou, a cobrança da última resposta e os itens que voltaram."}, {"code": "\n\nmeasure(\"point read\", lambda: [orders.read_item(\"o-17\", partition_key=\"c-17\")])\nmeasure(\"query in one partition\", lambda: list(orders.query_items(\n    \"SELECT * FROM c WHERE c.customerId = 'c-17'\", partition_key=\"c-17\")))\nmeasure(\"query across partitions\", lambda: list(orders.query_items(\n    \"SELECT * FROM c WHERE c.totalCents > 30000\", enable_cross_partition_query=True)))\nprint(\"feed ranges in the container:\", len(list(orders.read_feed_ranges())))\n", "note": "**Três leituras, do tipo mais barato ao mais caro.** Uma leitura pontual nomeia o `id` e a chave de partição. Uma consulta que nomeia o valor da chave é respondida dentro de uma partição lógica. Uma consulta por qualquer outro campo tem de perguntar a toda partição física, e a biblioteca se recusa a enviá-la a não ser que `enable_cross_partition_query` diga que foi de propósito. A última linha pergunta quantas faixas do hash, partições físicas, o contêiner tem."}]}
```

```
ana@laptop:~/azure$ python reads.py
point read                 1 request(s)     1 RU    1 item(s)
query in one partition     1 request(s)     1 RU   11 item(s)
query across partitions    1 request(s)     1 RU   40 item(s)
feed ranges in the container: 1
```

**Uma requisição cada, uma request unit cada, e uma feed range.** Os itens estão certos: um pedido,
depois os onze do cliente `c-17`, os dez escritos aqui e o `o-1001` da seção anterior, depois os 40
pedidos acima de 30.000 centavos. Todo o resto dessas linhas é simplificação do emulador, e a seção é
sobre ler além dela.

## O que o Azure cobra em vez disso

**Esta parte é ensinada a partir da documentação da Microsoft, e não foi rodada.** No Azure:

- **uma leitura pontual de um item de 1 KB custa 1 request unit**, a base documentada que define a
  própria unidade, e cresce com o tamanho do item. É a leitura mais barata que o Cosmos DB tem, e
  precisa do `id` e do valor da chave de partição;
- **uma consulta numa partição custa mais que uma leitura pontual do mesmo item**, porque o motor de
  consultas tem de interpretá-la, planejá-la e usar o índice, e a cobrança cresce com os itens que ela
  lê e devolve;
- **uma consulta entre partições é enviada a toda partição física**, cada resposta carrega a sua
  cobrança, e a biblioteca as soma. Um contêiner com quatro partições físicas responde quatro vezes.
  Conforme o contêiner cresce e o Azure o divide, a mesma consulta, devolvendo os mesmos itens, custa
  mais a cada ano.

**O emulador tem uma partição física**, que é o que `feed ranges in the container: 1` diz, e cobra 1
por tudo, como a lição 1 descobriu. Então ele não consegue mostrar o espalhamento e não consegue mostrar
o preço. Ele mostra o que o código precisa dizer para conseguir cada tipo de leitura: a leitura pontual
precisou das duas metades da identidade, a consulta numa partição nomeou o valor, e a terceira
consulta teve de ser permitida explicitamente. **`enable_cross_partition_query=True` num programa é a
linha a procurar numa revisão**: ela marca uma leitura que vai custar mais conforme os dados crescem, e
no caminho quente de uma aplicação costuma ser uma chave escolhida para a pergunta errada.

A lição 13 mede request units de verdade, a partir da documentação, com o throttling que vem quando um
contêiner fica sem elas.
