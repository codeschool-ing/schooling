---
title: O laboratório: o OpenSearch ao lado do banco
version: 1
---

**Esta é a terceira das aulas pesadas de que a aula 1 avisou**: o OpenSearch roda na máquina virtual Java
e precisa de cerca de um gigabyte de memória só para ele. Pare antes o que tiver sobrado de aulas
anteriores; o `docker ps` não deve listar nada.

O laboratório é o catálogo da Quitanda no PostgreSQL, um nó OpenSearch, e dois programas pequenos: um que
copia o catálogo para o índice de busca, e um que faz o papel da caixa de busca da loja. Ele fica em
`~/lab/search`:

```sh
mkdir -p ~/lab/search && cd ~/lab/search
```

`seed.sql`:

```schooling-example
{"language": "sql", "file": "seed.sql", "parts": [{"code": "CREATE TABLE products (\n    id          int PRIMARY KEY,\n    name        text NOT NULL,\n    category    text NOT NULL,\n    description text NOT NULL,\n    cents       int NOT NULL,\n    updated_at  timestamptz NOT NULL DEFAULT now()\n);\nINSERT INTO products (id, name, category, description, cents) VALUES\n (1, 'Café torrado em grãos', 'café', 'Café arábica do sul de Minas, torra média, grãos inteiros.', 3490),\n (2, 'Café moído tradicional', 'café', 'Café torrado e moído para coador, torra escura.', 2190),\n (3, 'Café em cápsulas', 'café', 'Dez cápsulas de café espresso, torra intensa.', 2890),\n (4, 'Café descafeinado', 'café', 'Café moído sem cafeína, torra média.', 2690),\n (5, 'Chá verde', 'chá', 'Folhas de chá verde em sachês, vinte unidades.', 1290),\n (6, 'Chá de camomila', 'chá', 'Flores de camomila secas, para infusão.', 990),\n (7, 'Chá mate tostado', 'chá', 'Erva-mate tostada a granel, para chá gelado.', 890),\n (8, 'Arroz branco tipo 1', 'grãos', 'Arroz agulhinha, pacote de cinco quilos.', 2590),\n (9, 'Arroz integral', 'grãos', 'Arroz integral, pacote de um quilo.', 890),\n (10, 'Feijão carioca', 'grãos', 'Feijão carioca tipo 1, pacote de um quilo.', 790),\n (11, 'Feijão preto', 'grãos', 'Feijão preto tipo 1, pacote de um quilo.', 850),\n (12, 'Lentilha', 'grãos', 'Lentilha seca, pacote de quinhentos gramas.', 990),\n (13, 'Pão de queijo congelado', 'padaria', 'Pão de queijo mineiro, pacote de um quilo, para assar.', 2490),\n (14, 'Pão francês', 'padaria', 'Pão francês fresco, assado de manhã.', 90),\n (15, 'Bolo de fubá', 'padaria', 'Bolo de fubá caseiro com erva-doce.', 1890),\n (16, 'Queijo minas frescal', 'laticínios', 'Queijo fresco de Minas, peça de quinhentos gramas.', 2290),\n (17, 'Leite integral', 'laticínios', 'Leite integral longa vida, um litro.', 590),\n (18, 'Manteiga com sal', 'laticínios', 'Manteiga de primeira qualidade, duzentos gramas.', 1190),\n (19, 'Requeijão cremoso', 'laticínios', 'Requeijão cremoso em copo, duzentos gramas.', 890),\n (20, 'Açúcar cristal', 'mercearia', 'Açúcar cristal, pacote de um quilo.', 490),\n (21, 'Açúcar mascavo', 'mercearia', 'Açúcar mascavo orgânico, quinhentos gramas.', 990),\n (22, 'Farinha de mandioca', 'mercearia', 'Farinha de mandioca torrada, quinhentos gramas.', 690),\n (23, 'Doce de leite', 'mercearia', 'Doce de leite cremoso, quatrocentos gramas.', 1490),\n (24, 'Goiabada cascão', 'mercearia', 'Goiabada cascão artesanal, para comer com queijo.', 1290);", "note": "O catálogo como o banco da loja o guarda, a fonte de verdade. O índice de busca vai ser uma cópia destas linhas; `updated_at` é como o alimentador acha as que mudaram. Os produtos são da Quitanda, então os nomes são em português, que é também o que torna a busca interessante."}]}
```

`index.json`:

```schooling-example
{"language": "json", "file": "index.json", "parts": [{"code": "{\n  \"settings\": {\n    \"number_of_shards\": 1,\n    \"number_of_replicas\": 0,\n    \"refresh_interval\": \"5s\",\n    \"analysis\": {\n      \"analyzer\": {\n        \"portuguese_folded\": {\n          \"tokenizer\": \"standard\",\n          \"filter\": [\"lowercase\", \"asciifolding\", \"brazilian_stem\"]\n        }\n      },\n      \"filter\": {\n        \"brazilian_stem\": {\"type\": \"stemmer\", \"language\": \"brazilian\"}\n      }\n    }\n  },\n  \"mappings\": {\n    \"properties\": {\n      \"name\":        {\"type\": \"text\", \"analyzer\": \"portuguese_folded\"},\n      \"description\": {\"type\": \"text\", \"analyzer\": \"portuguese_folded\"},\n      \"category\":    {\"type\": \"keyword\"},\n      \"cents\":       {\"type\": \"integer\"}\n    }\n  }\n}", "note": "A definição do índice. Um shard e nenhuma réplica, porque o laboratório tem um nó, e um refresh a cada cinco segundos em vez do padrão de um, para a aula conseguir ver a lacuna que um refresh deixa. O analisador é o que o motor de busca faz com um texto antes de guardá-lo e antes de buscá-lo: dividir em palavras, pôr em minúsculas, tirar acentos, e cortar cada palavra até o radical, com as regras do português do Brasil."}]}
```

`feed.py`:

```schooling-example
{"language": "python", "file": "feed.py", "parts": [{"code": "\"\"\"Copy changed products from PostgreSQL into the search index.\"\"\"\nimport json, os, urllib.error, urllib.request\nimport psycopg\n\nSEARCH = \"http://search:9200\"\nMARK = \"/data/fed-until\"\n\n\ndef call(method, path, body=None, ndjson=False):\n    req = urllib.request.Request(SEARCH + path, method=method, data=body.encode() if body else None,\n                                 headers={\"Content-Type\": \"application/x-ndjson\" if ndjson else \"application/json\"})\n    with urllib.request.urlopen(req) as r:\n        data = r.read()\n    return json.loads(data) if data else None\n\n\ntry:\n    call(\"HEAD\", \"/products\")\nexcept urllib.error.HTTPError:\n    call(\"PUT\", \"/products\", open(\"index.json\").read())\n    print(\"created index products\")\n\nsince = open(MARK).read() if os.path.exists(MARK) else \"-infinity\"\ndb = psycopg.connect(\"host=db user=postgres password=quitanda\")\nrows = db.execute(\"SELECT id, name, category, description, cents, updated_at FROM products \"\n                  \"WHERE updated_at > %s ORDER BY updated_at\", (since,)).fetchall()\nif rows:\n    lines = []\n    for id_, name, category, description, cents, _ in rows:\n        lines.append(json.dumps({\"index\": {\"_index\": \"products\", \"_id\": id_}}))\n        lines.append(json.dumps({\"name\": name, \"category\": category, \"description\": description,\n                                 \"cents\": cents}))\n    result = call(\"POST\", \"/_bulk\", \"\\n\".join(lines) + \"\\n\", ndjson=True)\n    if result[\"errors\"]:\n        raise SystemExit(f\"some documents were refused: {result}\")\n    open(MARK, \"w\").write(rows[-1][5].isoformat())\nprint(f\"fed {len(rows)} products\")", "note": "O alimentador, que mantém o índice de busca como cópia do banco. Ele cria o índice na primeira vez, depois manda todo produto mudado desde a última execução, numa requisição em lote, e guarda num arquivo até onde chegou. É a projeção da aula 13 com outro modelo de leitura no fim."}]}
```

`search.py`:

```schooling-example
{"language": "python", "file": "search.py", "parts": [{"code": "\"\"\"Search the catalogue the way the shop's search box does.\"\"\"\nimport json, sys, urllib.request\n\nwords = \" \".join(a for a in sys.argv[1:] if not a.startswith(\"--\"))\nmatch = {\"multi_match\": {\"query\": words, \"fields\": [\"name^3\", \"description\"]}}", "note": "A caixa de busca da loja. Ela pede ao índice produtos que combinem com as palavras no nome e na descrição, com o nome valendo três vezes mais, e uma contagem dos resultados em cada categoria, que uma loja mostra como filtros ao lado dos resultados."}, {"code": "if \"--fuzzy\" in sys.argv:\n    match[\"multi_match\"][\"fuzziness\"] = \"AUTO\"\nbody = {\"query\": match, \"size\": 5, \"aggs\": {\"categories\": {\"terms\": {\"field\": \"category\"}}}}\nreq = urllib.request.Request(\"http://search:9200/products/_search\", data=json.dumps(body).encode(),\n                             headers={\"Content-Type\": \"application/json\"})\nwith urllib.request.urlopen(req) as r:\n    result = json.load(r)\ntotal = result[\"hits\"][\"total\"][\"value\"]\nprint(f\"{total} {'match' if total == 1 else 'matches'}\")\nfor hit in result[\"hits\"][\"hits\"]:\n    print(f\"  {hit['_score']:5.2f}  {hit['_source']['name']}\")\nprint(\"categories: \" + \", \".join(f\"{b['key']} ({b['doc_count']})\"\n                                for b in result[\"aggregations\"][\"categories\"][\"buckets\"]))", "note": "`--fuzzy` deixa cada palavra ter até duas letras de diferença, para o cliente que digita \"cafe torado\"."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir \"psycopg[binary]==3.3.6\"\nWORKDIR /app\nCOPY *.py index.json .", "note": "Python e psycopg, como nas aulas 10, 13 e 16."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  db:\n    image: postgres:17\n    environment:\n      POSTGRES_PASSWORD: quitanda\n    volumes:\n      - ./seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro", "note": "O banco da loja, carregado com o catálogo na primeira partida."}, {"code": "  search:\n    image: opensearchproject/opensearch:2.19.1\n    environment:\n      discovery.type: single-node\n      plugins.security.disabled: \"true\"\n      DISABLE_INSTALL_DEMO_CONFIG: \"true\"\n      OPENSEARCH_JAVA_OPTS: \"-Xms512m -Xmx512m\"\n    ports:\n      - \"127.0.0.1:9200:9200\"", "note": "O OpenSearch, num nó. O plugin de segurança fica desligado **só no laboratório**: é ele que faz o OpenSearch exigir TLS e senhas, e toda instalação de verdade o mantém ligado. O heap fica em 512 MB para o laboratório caber em 8 GB; a porta 9200 é publicada no loopback da máquina para o `curl`."}, {"code": "  tools:\n    build: .\n    profiles: [\"tools\"]\n    volumes:\n      - data:/data\nvolumes:\n  data:", "note": "O alimentador e a caixa de busca, rodados quando pedidos, com um volume para o marcador do alimentador."}]}
```

Suba tudo e dê ao OpenSearch uns quarenta segundos; ele responde na porta 9200 quando está pronto. Depois
guarde numa variável o comando que roda um programa:

```sh
docker compose up -d
R="docker compose --progress quiet run --rm tools python"
```

```
ana@vm:~/lab/search$ curl -s "localhost:9200/?filter_path=version.distribution,version.number,version.lucene_version"; echo
{
  "version" : {
    "distribution" : "opensearch",
    "number" : "2.19.1",
    "lucene_version" : "9.12.1"
  }
}
```
