---
title: A outbox: mudar um banco e anunciar a mudança numa transação
version: 1
---

**O padrão outbox grava o evento que uma mudança precisa anunciar numa tabela do mesmo banco, na mesma
transação da mudança, e um relay separado copia essa tabela para o Kafka.** Ele resolve o problema do
outro lado do stream: não um consumidor aplicando eventos, mas um programa que muda os próprios dados e
precisa avisar todo mundo.

O jeito errado é o que parece óbvio, e a lição 14 começa por ele: atualizar o banco, depois produzir
no Kafka. Uma queda entre os dois deixa uma mudança de que ninguém fica sabendo; produzir primeiro, e
uma queda deixa o anúncio de uma mudança que nunca aconteceu. É o vão da lição 7 de novo, entre dois
sistemas que não dividem uma transação. A outbox tira um dos dois sistemas do momento que importa:
**a mudança e o evento são linhas do mesmo banco**, então são confirmados juntos ou nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"À esquerda, o programa que repõe o estoque escreve uma transação de banco com duas linhas: a mudança de estoque e o evento na tabela outbox. À direita, um relay separado lê as linhas não enviadas da outbox, manda para o Kafka, espera a confirmação e só então as marca como enviadas. Uma queda antes do commit perde as duas linhas juntas; uma queda no relay depois da confirmação do Kafka manda o evento de novo, com o mesmo id.\" data-fig=\"l8-outbox\"><defs><marker id=\"l8-outbox-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l8-outbox-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l8-outbox-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"240\" height=\"130\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">uma transação de banco</text><rect x=\"40\" y=\"62\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stock: bk-04 +10</text><rect x=\"40\" y=\"108\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">outbox: restocked, id, sent = 0</text><rect x=\"330\" y=\"92\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">relay</text><line x1=\"240\" y1=\"125\" x2=\"328\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l8-outbox-ah-8343)\"></line><text x=\"294\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1  lê as linhas não enviadas</text><rect x=\"560\" y=\"92\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kafka: stock-events</text><line x1=\"440\" y1=\"110\" x2=\"558\" y2=\"110\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l8-outbox-ah-726)\"></line><text x=\"500\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2  produz, espera a confirmação</text><path d=\"M 385 142 Q 300 190 240 140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-outbox-ah-0)\"></path><text x=\"320\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3  marca como enviadas</text><text x=\"560\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma queda aqui repete o passo 2</text><line x1=\"470\" y1=\"125\" x2=\"470\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "A mudança e o evento dela são confirmados juntos. O relay entrega pelo menos uma vez, então o evento carrega um id para os leitores deduplicarem."}
```

## Uma reposição, e o evento dela

Quando chega uma entrega de livros numa loja, o estoque sobe e um evento `restocked` precisa chegar ao
Kafka. Este programa faz as duas metades, como dois comandos. Salve como `~/work/outbox.py`:

```schooling-example
{
  "language": "python",
  "file": "outbox.py",
  "parts": [
    {
      "code": "\"\"\"outbox.py: a restock and the event announcing it, written in one transaction.\n\n    python outbox.py restock BOOK QTY    change the stock and queue the event\n    python outbox.py relay               send what is queued to Kafka, then mark it sent\n\"\"\"\nimport json\nimport sqlite3\nimport sys\nimport uuid\n\nfrom confluent_kafka import Producer\n",
      "note": "Dois comandos: um muda o estoque, o outro faz o relay."
    },
    {
      "code": "db = sqlite3.connect(\"shop.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS outbox (id TEXT PRIMARY KEY, topic TEXT, key TEXT,\n                                       payload TEXT, sent INTEGER NOT NULL DEFAULT 0);\n\"\"\")\n",
      "note": "**A outbox é uma tabela comum**: o id do evento, para onde ele vai, e se já foi enviado."
    },
    {
      "code": "if sys.argv[1] == \"restock\":\n    book, qty = sys.argv[2], int(sys.argv[3])\n    event = {\"event\": str(uuid.uuid4()), \"type\": \"restocked\", \"book\": book, \"qty\": qty}\n    with db:\n        db.execute(\"INSERT INTO stock VALUES (?, ?) ON CONFLICT(book) DO UPDATE SET qty = qty + ?\",\n                   (book, qty, qty))\n        db.execute(\"INSERT INTO outbox (id, topic, key, payload) VALUES (?, 'stock-events', ?, ?)\",\n                   (event[\"event\"], book, json.dumps(event)))\n    print(f\"{book}: +{qty}, event queued\")\n",
      "note": "**O estoque e o evento são gravados numa transação.** O evento recebe o id aqui, uma vez, então toda cópia que o relay mandar carrega o mesmo id."
    },
    {
      "code": "elif sys.argv[1] == \"relay\":\n    producer = Producer({\"bootstrap.servers\": \"localhost:9092\", \"enable.idempotence\": True})\n    rows = db.execute(\"SELECT id, topic, key, payload FROM outbox WHERE sent = 0 ORDER BY rowid\")\n    sent = []\n    for id_, topic, key, payload in rows.fetchall():\n        producer.produce(topic, key=key, value=payload,\n                         on_delivery=lambda err, msg, id_=id_: err or sent.append(id_))\n    producer.flush()\n    with db:\n        db.executemany(\"UPDATE outbox SET sent = 1 WHERE id = ?\", [(i,) for i in sent])\n    print(f\"relayed {len(sent)} events\")",
      "note": "O relay manda toda linha não enviada na ordem em que foi gravada, espera as confirmações do Kafka e **só então marca as linhas confirmadas como enviadas**."
    }
  ]
}
```

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock-events --partitions 1
Created topic stock-events.
ubuntu@stream:~/work$ python outbox.py restock bk-04 10
bk-04: +10, event queued
ubuntu@stream:~/work$ python outbox.py restock bk-07 5
bk-07: +5, event queued
ubuntu@stream:~/work$ python -m sqlite3 shop.db "SELECT id, sent FROM outbox"
('12098da2-b441-40bd-a0d4-ea83a638a598', 0)
('0e605ed6-41ea-49b0-8d81-b5d62bface21', 0)
ubuntu@stream:~/work$ python outbox.py relay
%4|1792112069.651|GETPID|rdkafka#producer-1| [thrd:main]: Failed to acquire idempotence PID from broker localhost:9092/1: Broker: Coordinator load in progress: retrying
relayed 2 events
ubuntu@stream:~/work$ python outbox.py relay
relayed 0 events
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock-events --from-beginning --timeout-ms 5000 2>/dev/null
{"event": "12098da2-b441-40bd-a0d4-ea83a638a598", "type": "restocked", "book": "bk-04", "qty": 10}
{"event": "0e605ed6-41ea-49b0-8d81-b5d62bface21", "type": "restocked", "book": "bk-07", "qty": 5}
```

Cada reposição pôs o evento na fila na mesma transação, e as duas linhas de `outbox` dizem que `sent`
é 0; os ids são aleatórios, então os seus são outros. O primeiro relay mandou os dois, depois da mesma
linha de primeira vez do cliente que a lição 7 mostrou, e os marcou; **o segundo relay não encontrou
nada para mandar**. O tópico tem os dois eventos, cada um com o id que recebeu quando o estoque mudou.

## O que o relay ainda deve

O próprio relay tem o vão da lição 7: uma queda depois de o Kafka confirmar e antes de as linhas serem
marcadas manda esses eventos de novo na execução seguinte. **Uma outbox entrega pelo menos uma vez**, e
é por isso que cada evento carrega um id criado quando a mudança foi feita. Um consumidor de
`stock-events` deduplica por ele, como a segunda seção desta lição fez com os ids das vendas.

Dois pontos práticos. A outbox cresce, então as linhas enviadas são apagadas depois de um tempo, a
mesma pergunta da seção sobre por quanto tempo lembrar. E um relay que consulta uma tabela é a versão
simples; a versão usada em escala lê o próprio log de mudanças do banco em vez de consultar a tabela,
então nada fica consultando e nenhum evento se perde entre duas consultas. Isso é change data capture,
e a lição 14 faz com o Debezium.
