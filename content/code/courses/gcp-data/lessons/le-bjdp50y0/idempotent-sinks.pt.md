---
title: Destinos que não ligam para quantas vezes são escritos
version: 1
---

**A tabela de deduplicação da seção anterior é uma resposta; um destino idempotente por natureza é a
mais barata.** Uma tabela de deduplicação lembra cada evento para poder recusar uma segunda escrita.
Um destino idempotente não precisa de memória, porque escrever a mesma coisa duas vezes já cai no
mesmo lugar com o mesmo resultado. O teste de um destino é uma pergunta: se esta escrita se repetir, o
resultado muda? Somar a um total responde que sim. Dois tipos de escrita respondem que não, e são os
dois que este curso mais usa.

## Um upsert, não um incremento

Salve como `~/gcp/sink.py`:

```schooling-example
{"language": "python", "file": "sink.py", "parts": [{"code": "import sqlite3\nimport sys\n\ndb = sqlite3.connect('sink.db')\ndb.execute('CREATE TABLE IF NOT EXISTS balances (customer_id TEXT PRIMARY KEY, cents INTEGER)')\nhow, customer, cents = sys.argv[1], sys.argv[2], int(sys.argv[3])\n\n", "note": "Uma escrita, escolhida na linha de comando, numa tabela de saldos."}, {"code": "with db:\n    if how == 'add':\n        db.execute('INSERT INTO balances VALUES (?, ?) ON CONFLICT (customer_id) '\n                   'DO UPDATE SET cents = cents + excluded.cents', (customer, cents))\n", "note": "`add` muda o valor por uma quantia, a escrita que o `totals.py` faz."}, {"code": "    else:\n        db.execute('INSERT INTO balances VALUES (?, ?) ON CONFLICT (customer_id) '\n                   'DO UPDATE SET cents = excluded.cents', (customer, cents))\n", "note": "**`put` define o valor**: um upsert. Os dois comandos diferem por uma expressão, `cents +`, e essa expressão é toda a diferença entre um destino que conta duas vezes e um que não conta."}, {"code": "print(customer, db.execute('SELECT cents FROM balances WHERE customer_id = ?', (customer,)).fetchone()[0])\n", "note": "E ele imprime o que a linha guarda depois."}]}
```

```
ana@laptop:~/gcp$ python3 sink.py add c-08 500
c-08 500
ana@laptop:~/gcp$ python3 sink.py add c-08 500
c-08 1000
ana@laptop:~/gcp$ python3 sink.py put c-09 500
c-09 500
ana@laptop:~/gcp$ python3 sink.py put c-09 500
c-09 500
```

**`add` duas vezes fez 1.000 de 500; `put` duas vezes deixou 500.** Um upsert troca o valor pelo que foi
dado, então repeti-lo é inofensivo, e o mesmo vale para o `INSERT ... ON CONFLICT DO UPDATE` do
PostgreSQL, para o `MERGE`, que o `sql-databases` cobre, e para um `set()` do Firestore num documento
nomeado pela chave. O porém é que um upsert precisa carregar o **estado inteiro**, o próprio saldo em
vez da quantia a somar, e o publicador precisa conhecer esse estado. Isso serve a um fluxo de retratos,
como "o saldo do cliente `c-09` agora é 500", e não serve a um fluxo de mudanças, como "some 500", que é
o que os pagamentos são. Um fluxo de mudanças num destino que soma é o caso que precisa da deduplicação
da seção anterior.

**Desenhe os eventos para facilitar o destino.** Se um publicador consegue mandar o estado novo em vez
da diferença, todo consumidor adiante pode fazer upsert e esquecer os duplicados. Quando o evento
precisa ser uma diferença, ele carrega um id, e o destino ou registra o id junto com o efeito, como o
`totals.py` faz, ou é reconstruído depois a partir do histórico deduplicado.

## Um objeto nomeado pelo conteúdo, não pelo momento

Um consumidor que junta mensagens em arquivos no Cloud Storage precisa de um nome para cada objeto. O
nome tentador é o horário da escrita; o idempotente é derivado do que o arquivo guarda. Isto precisa do
fake-gcs-server da aula 1 rodando num terminal só dele, com o comando de "Two terminals" da aula 1. Um
lote pequeno, escrito duas vezes com cada tipo de nome:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ printf '%s\n' '{"order_id": "o-301", "cents": 4590}' '{"order_id": "o-302", "cents": 12800}' > batch.json
ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-time/1793386454387317596.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-time/1793386455620381634.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-content/$(sha256sum batch.json | cut -c1-16).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-content/$(sha256sum batch.json | cut -c1-16).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
  

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-raw-prod/raw/**
gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
gs://quitanda-raw-prod/raw/payments-by-time/1793386454387317596.json
gs://quitanda-raw-prod/raw/payments-by-time/1793386455620381634.json
```

**O lote nomeado pelo horário agora está duas vezes no lago; o nomeado pelo conteúdo está uma vez.** A
segunda cópia para `9a93139ad353bd4a.json` sobrescreveu um objeto idêntico com bytes idênticos, o que
não muda nada, então um consumidor que caiu depois de escrever o objeto e antes do ack pode escrevê-lo
de novo na nova entrega sem dano. Com os nomes por horário, a mesma nova entrega deixa dois objetos com
os mesmos dois pagamentos, e toda consulta ao lago conta os dois. O aviso da aula 1 de que uma
sobrescrita é silenciosa e definitiva é, aqui, exatamente a propriedade que se quer.

**Isso só funciona se uma nova entrega remontar o mesmo lote**, e no Pub/Sub essa é a parte difícil.
Uma assinatura não tem posições pelas quais agrupar: uma nova entrega chega nos grupos que os pulls
devolverem, misturada com mensagens que vieram depois, então o arquivo da segunda tentativa é um
conjunto de mensagens diferente do primeiro. Um consumidor que quer arquivos nomeados pelo conteúdo os
nomeia por algo estável, como um arquivo por pedido, ou os ids ordenados dos eventos dentro dele, e
aceita que o mesmo evento pode então ficar em dois arquivos diferentes. **Uma assinatura do Cloud
Storage**, que a aula 19 citou, escreve arquivos nomeados por horário como o primeiro tipo, então um
duplicado que ela escreve fica no lago até um job posterior tirá-lo. É por isso que tabelas do lago
alimentadas pelo Pub/Sub são deduplicadas pela chave de idempotência quando compactadas na camada
curada, numa consulta que mantém uma linha por id de pedido.
