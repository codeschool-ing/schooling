---
title: Cache-aside, e a cópia que fica velha
version: 1
---

**O padrão que quase todo cache usa se chama cache-aside**: o programa pergunta primeiro ao cache, e só
numa falta pergunta ao banco de dados, e depois deixa uma cópia no cache para a próxima vez. O cache
nunca fala com o banco sozinho; ele fica de lado, que é de onde vem o nome. É o padrão desta seção e da
maior parte do código que usa os serviços de Redis do Azure.

Os programas falam com o Redis no protocolo dele, por um cliente de umas vinte linhas escrito aqui
porque o laboratório não instalou biblioteca de Redis. Salve como `resp.py` em `~/azure`:

```schooling-example
{"language": "python", "file": "resp.py", "parts": [
{"code": "import socket\n", "note": "Nada além da biblioteca padrão. O laboratório do curso não tem biblioteca de Redis instalada, e o protocolo do Redis, o RESP, é simples o bastante para que escrever o cliente seja o jeito mais rápido de ver o que toda biblioteca faz."},
{"code": "\n\nclass Redis:\n    def __init__(self, host=\"127.0.0.1\", port=6379):\n        self.sock = socket.create_connection((host, port))\n        self.replies = self.sock.makefile(\"rb\")\n", "note": "Uma conexão é um socket, e um arquivo em volta dele para as respostas poderem ser lidas uma linha de cada vez."},
{"code": "\n    def __call__(self, *args):\n        request = b\"*%d\\r\\n\" % len(args)\n        for arg in args:\n            arg = str(arg).encode()\n            request += b\"$%d\\r\\n%s\\r\\n\" % (len(arg), arg)\n        self.sock.sendall(request)\n        return self.reply()\n", "note": "Um comando é mandado como um array de strings: `*` e o número de itens, depois para cada um `$`, o tamanho em bytes, e os bytes. `SET product:1 x` é `*3`, depois `$3 SET`, `$9 product:1` e `$1 x`, cada linha terminando em retorno de carro e quebra de linha."},
{"code": "\n    def reply(self):\n        line = self.replies.readline()[:-2]\n        kind, rest = line[:1], line[1:].decode()\n        if kind == b\"+\":\n            return rest\n        if kind == b\"-\":\n            raise RuntimeError(rest)\n        if kind == b\":\":\n            return int(rest)\n        if kind == b\"$\":\n            return None if rest == \"-1\" else self.replies.read(int(rest) + 2)[:-2].decode()\n        if kind == b\"*\":\n            return [self.reply() for _ in range(int(rest))]\n        raise RuntimeError(f\"unexpected reply {line!r}\")\n", "note": "O primeiro byte de uma resposta diz o que ela é: `+` uma string curta como `OK`, `-` um erro, `:` um inteiro, `$` uma string do tamanho dado, ou `-1` para nenhuma, e `*` um array de outras respostas. Um erro vira exceção, que é como a seção de despejo vai encontrar um."}
]}
```

Depois o cache na frente do Cosmos DB, salvo como `cache.py` ao lado:

```schooling-example
{"language": "python", "file": "cache.py", "parts": [
{"code": "import json\n\nfrom azure.cosmos import CosmosClient, PartitionKey\n\nfrom resp import Redis\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\ndb = CosmosClient(\"http://localhost:8081\", KEY).create_database_if_not_exists(\"quitanda\")\nproducts = db.create_container_if_not_exists(\"products\", PartitionKey(\"/category\"))\ncache = Redis()\n", "note": "O contêiner products da lição 13 e o cliente do arquivo acima. As duas conexões são abertas uma vez, para o programa inteiro."},
{"code": "\n\ndef product(sku, category):\n    cached = cache(\"GET\", f\"product:{sku}\")\n    if cached is not None:\n        return json.loads(cached), \"cache\"\n    item = products.read_item(sku, partition_key=category)\n    found = {\"name\": item[\"name\"], \"priceCents\": item[\"priceCents\"]}\n    cache(\"SET\", f\"product:{sku}\", json.dumps(found), \"EX\", 300)\n    return found, \"database\"\n", "note": "**Cache-aside**: perguntar ao Redis primeiro, e numa falta ler o Cosmos DB, guardar a resposta sob `product:` e o código do produto por 300 segundos, e devolvê-la. A função diz de onde veio cada resposta."},
{"code": "\n\ndef set_price(sku, category, cents, invalidate):\n    item = products.read_item(sku, partition_key=category)\n    item[\"priceCents\"] = cents\n    products.upsert_item(item)\n    if invalidate:\n        cache(\"DEL\", f\"product:{sku}\")\n", "note": "Uma mudança de preço. A escrita vai para o Cosmos DB, que é a verdade; `invalidate` decide se a cópia em cache é apagada ao mesmo tempo."},
{"code": "\n\ndef show(when):\n    found, source = product(\"cafe-500g\", \"mercearia\")\n    ttl = cache(\"TTL\", \"product:cafe-500g\")\n    print(f\"{when:28} {found['priceCents'] / 100:6.2f}  from the {source:8}  ttl {ttl}\")\n", "note": "Uma requisição do café, impressa com a origem da resposta e quantos segundos a cópia dela ainda tem."},
{"code": "\n\nproducts.upsert_item({\"id\": \"cafe-500g\", \"category\": \"mercearia\", \"name\": \"Café 500 g\", \"priceCents\": 2490})\ncache(\"DEL\", \"product:cafe-500g\")\nshow(\"first request\")\nshow(\"second request\")\nset_price(\"cafe-500g\", \"mercearia\", 2690, invalidate=False)\nshow(\"price raised, cache kept\")\nset_price(\"cafe-500g\", \"mercearia\", 2790, invalidate=True)\nshow(\"price raised, key deleted\")\nshow(\"next request\")\n", "note": "O roteiro: duas requisições, uma mudança de preço que deixa o cache em paz, e uma que apaga a chave."}
]}
```

```
ana@laptop:~/azure$ python cache.py
first request                 24.90  from the database  ttl 300
second request                24.90  from the cache     ttl 300
price raised, cache kept      24.90  from the cache     ttl 300
price raised, key deleted     27.90  from the database  ttl 300
next request                  27.90  from the cache     ttl 300
```

**A primeira requisição foi ao Cosmos DB e a segunda não.** A cópia foi guardada com time to live de
300 segundos, e toda requisição nos cinco minutos seguintes é respondida da memória, ao custo de uma ida
e volta ao Redis em vez de uma ao banco. Nas páginas de produto da Quitanda, em que algumas centenas de
produtos são lidos o dia todo, isso é a maioria das requisições.

**Depois o preço subiu para 26,90, e a página continuou dizendo 24,90.** Nada avisou o cache. A cópia
fica errada até expirar, o que aqui é até cinco minutos e em geral é o que o time to live disser. Esse é
o preço do cache-aside, e ele tem duas partes a escolher: por quanto tempo uma cópia pode estar errada,
que é o time to live, e se uma escrita avisa o cache, que é o que o `invalidate` faz. **A segunda mudança
de preço apagou a chave**, e a requisição seguinte foi ao banco e viu 27,90.

Apagar é melhor que gravar o valor novo no cache, por um motivo que vale conhecer: dois escritores
correndo podem deixar o valor mais antigo no cache por último, enquanto uma exclusão só consegue causar
uma falta a mais. E o time to live fica mesmo quando toda escrita apaga a chave, porque uma escrita que
falha depois do Cosmos DB e antes do Redis deixa uma cópia velha que só o time to live vai remover.

**Um cache também pode errar no outro sentido.** Quando uma chave popular expira, toda requisição que
chega antes de a primeira recarregá-la vai ao banco ao mesmo tempo. Numa página movimentada isso é uma
rajada de leituras idênticas no momento em que o cache menos ajuda; os remédios comuns são renovar as
chaves populares antes de expirarem, ou deixar uma requisição recarregar a chave enquanto as outras
esperam ou levam a cópia antiga.
