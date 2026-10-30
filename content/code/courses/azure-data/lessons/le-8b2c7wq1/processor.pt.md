---
title: Um processador que guarda o lugar num blob
version: 1
---

**Um programa que lê o feed uma vez é um script; um que o lê para sempre, retomando de onde parou, é um
processador**, e a diferença toda é onde ele guarda o lugar. O token de continuação da primeira seção é
esse lugar. Um processador o salva depois de cada lote, e a próxima execução, nesta máquina ou em outra,
começa dele. Esta seção constrói o menor que está correto: ele transforma os pedidos da Quitanda em
quanto cada cliente gastou, e guarda tanto a visão quanto o token como blobs no Azurite. Ele precisa do
emulador do Cosmos DB e do Azurite, ligados juntos:

```sh
docker compose --profile cosmos up -d
```

Salve como `processor.py`:

```schooling-example
{"language": "python", "file": "processor.py", "parts": [
{"code": "import json\nimport os\n\nfrom azure.core.exceptions import ResourceNotFoundError\nfrom azure.cosmos import CosmosClient\nfrom azure.storage.blob import BlobServiceClient\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\norders = CosmosClient(\"http://localhost:8081\", KEY).get_database_client(\"quitanda\").get_container_client(\"orders\")\nstate = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\nstate = state.get_container_client(\"processor\")\nif not state.exists():\n    state.create_container()\n", "note": "Dois clientes: o contêiner de pedidos no Cosmos DB, e um contêiner de blobs no Azurite chamado `processor` que guarda o estado do processador. A string de conexão do armazenamento é a que todo terminal deste curso exporta."},
{"code": "\n\ndef load(name, default):\n    try:\n        return state.download_blob(name).readall().decode()\n    except ResourceNotFoundError:\n        return default\n", "note": "O `load` lê um blob como texto, ou responde um padrão quando o blob ainda não existe, que é a primeira execução."},
{"code": "\n\nspend = json.loads(load(\"spend.json\", \"{}\"))\ntoken = load(\"checkpoint\", None)\nif token:\n    changes = orders.query_items_change_feed(continuation=token)\nelse:\n    changes = orders.query_items_change_feed(start_time=\"Beginning\")\n", "note": "O estado são dois blobs: `spend.json`, a visão sendo construída, e `checkpoint`, o token de continuação da última execução. Com um token, o feed retoma depois dele; sem, começa do início."},
{"code": "\napplied = 0\nfor change in changes:\n    mine = spend.setdefault(change[\"customerId\"], {})\n    if change.get(\"deleted\"):\n        mine.pop(change[\"id\"], None)\n    else:\n        mine[change[\"id\"]] = change[\"totalCents\"]\n    applied += 1\n", "note": "A visão tem chave pelo id do pedido dentro de cada cliente. **Aplicar uma mudança define um valor, não soma um**, então aplicar a mesma mudança duas vezes deixa a mesma visão. Um pedido marcado como apagado é removido."},
{"code": "\nstate.upload_blob(\"spend.json\", json.dumps(spend, sort_keys=True), overwrite=True)\nif os.environ.get(\"CRASH\") == \"before-checkpoint\":\n    raise SystemExit(f\"applied {applied} and stopped before the checkpoint\")\nstate.upload_blob(\"checkpoint\", orders.client_connection.last_response_headers[\"etag\"], overwrite=True)\n", "note": "A visão é salva primeiro e o token depois. Entre os dois é onde uma queda deixa o processador; `CRASH=before-checkpoint` o para exatamente ali, para ver o que acontece depois."},
{"code": "\nprint(f\"applied {applied} changes\")\nfor customer, by_order in sorted(spend.items()):\n    print(f\"  {customer}  {len(by_order)} orders  {sum(by_order.values()) / 100:8.2f}\")\n", "note": "O que ele aplicou, e a visão."}
]}
```

E um jeito de uma linha de fazer um pedido, salvo como `order.py`:

`order.py`:

```python
import sys

from azure.cosmos import CosmosClient

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
orders = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda").get_container_client("orders")
order_id, customer, cents = sys.argv[1], sys.argv[2], int(sys.argv[3])
orders.upsert_item({"id": order_id, "customerId": customer, "status": "paid", "totalCents": cents})
```

```
ana@laptop:~/azure$ python processor.py
applied 3 changes
  c-7  1 orders     48.90
  c-9  1 orders     21.00
ana@laptop:~/azure$ python processor.py
applied 0 changes
  c-7  1 orders     48.90
  c-9  1 orders     21.00
ana@laptop:~/azure$ python order.py o-5 c-8 990 && CRASH=before-checkpoint python processor.py
applied 1 and stopped before the checkpoint
ana@laptop:~/azure$ python processor.py
applied 1 changes
  c-7  1 orders     48.90
  c-8  1 orders      9.90
  c-9  1 orders     21.00
```

**A primeira execução aplicou três mudanças**: `o-1`, `o-4` e `o-3`. O emulador ainda listava a última
versão de `o-3`, marcada como apagada, depois que o time to live a tinha removido; o processador viu a
marca e a deixou fora da visão, e é por isso que `c-7` tem um pedido. Se o Azure ainda lista a última
versão de um item expirado não é algo que este curso conseguiu conferir, e o projeto não deve depender
disso: o time to live é longo o bastante para todo leitor ver a marca primeiro. **A segunda execução não
aplicou nada**, porque o token dizia onde a primeira tinha parado.

**Depois, a queda.** Um pedido novo de `c-8` foi feito, e o processador o aplicou, salvou a visão e
parou antes de salvar o token. A execução seguinte começou do token velho, leu `o-5` de novo e o aplicou
de novo, e `c-8` mostra 9.90 e não 19.80:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"O laço do processador em quatro passos: ler o feed a partir do checkpoint, aplicar as mudanças definindo valores, salvar a visão em spend.json, salvar o token em checkpoint. Uma quebra âmbar entre salvar a visão e salvar o token marca onde CRASH=before-checkpoint o para. Uma seta tracejada volta do fim para o começo: a próxima execução começa do último token salvo, então uma queda na quebra relê mudanças que já estão na visão.\" data-fig=\"l14-loop\"><defs><marker id=\"l14-p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--phosphor)\"/></marker><marker id=\"l14-w-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">ler o feed</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do checkpoint</text><line x1=\"162\" y1=\"78\" x2=\"193\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"195\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"265\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">aplicar as mudanças</text><text x=\"265\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">definir, nunca somar</text><line x1=\"337\" y1=\"78\" x2=\"368\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"370\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"440\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">salvar a visão</text><text x=\"440\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">spend.json</text><line x1=\"512\" y1=\"78\" x2=\"543\" y2=\"78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l14-p-ah)\"/><rect x=\"545\" y=\"50\" width=\"140\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"615\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">salvar o token</text><text x=\"615\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checkpoint</text><path d=\"M528,30 L534,40 L522,48 L534,58 L522,68 L534,78 L522,88 L534,98 L522,108 L528,120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"528\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">CRASH=before-checkpoint</text><path d=\"M650,108 C650,190 90,190 90,110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-w-ah)\"/><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a próxima execução começa do último token salvo</text><text x=\"370\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Uma queda na linha âmbar relê mudanças já na visão. Definir valores é inofensivo; somar contaria duas vezes.</text></svg>", "caption": "Trabalho primeiro, checkpoint depois: a ordem que não perde nada e repete alguma coisa."}
```

**Salvar a visão primeiro e o token depois é a única ordem que não perde nada**: ao contrário, uma queda
entre os dois registraria uma posição além de mudanças que nunca chegaram à visão, e elas nunca seriam
lidas de novo. O preço da ordem segura é que algumas mudanças são lidas duas vezes, o que se chama
entrega pelo menos uma vez. O processador sobrevive a isso porque cada mudança define `spend[c-8][o-5]`
como 990 em vez de somar 990 a um total, então fazer duas vezes é o mesmo que fazer uma. A lição 24 é
sobre essa propriedade, a idempotência, e todo consumidor de um feed ou de um stream precisa dela.

Duas coisas que este processador não faz, e um de verdade tem de fazer. Ele lida com uma cópia de si
mesmo: dois processos iniciados juntos leriam do mesmo token e sobrescreveriam a visão um do outro. E ele
lê o feed inteiro como uma faixa só, onde um contêiner com muitas partições físicas pode ser lido em
paralelo, faixa por faixa. As duas coisas são para o que serve o processador do change feed da última
seção.
