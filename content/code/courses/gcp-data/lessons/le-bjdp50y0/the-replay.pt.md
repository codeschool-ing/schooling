---
title: Um consumidor que cai, contado duas vezes e depois uma
version: 1
---

**Esta seção faz duplicados acontecerem e depois os torna inofensivos, em programas que você roda.** O
cenário são os pagamentos da Quitanda: um tópico com uma mensagem por pedido pago, e um consumidor que
mantém o total corrente de cada cliente num banco de dados. Os totais são o tipo de número que alguém
reporta ao financeiro, então contar um pedido duas vezes não é erro de arredondamento; é uma fatura
errada.

O emulador é o da seção anterior, ainda rodando. Um tópico, a sua única assinatura, e um **snapshot**
da assinatura tirado antes de qualquer publicação, que é o que deixa cada execução abaixo recomeçar das
mesmas mensagens:

```sh
gcloud pubsub topics create payments
gcloud pubsub subscriptions create totals --topic=payments
gcloud pubsub snapshots create totals-start --subscription=totals
```

## O publicador, com uma nova tentativa dentro

Salve como `~/gcp/pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "import json\n\nfrom google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'payments')\n\n", "note": "O tópico `payments` é criado pelos comandos acima deste bloco, com a sua única assinatura."}, {"code": "PAYMENTS = [\n    ('o-301', 'c-17', 4590), ('o-302', 'c-02', 12800), ('o-303', 'c-17', 990),\n    ('o-304', 'c-05', 2350), ('o-305', 'c-02', 1500), ('o-306', 'c-17', 7200),\n]\nRETRIED = {'o-303'}\n\n", "note": "Seis pagamentos de três clientes. **A chave de idempotência é o id do pedido**: um pedido é pago uma vez, então uma segunda mensagem para o mesmo pedido é um duplicado, seja qual for a causa."}, {"code": "for order, customer, cents in PAYMENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'cents': cents}).encode()\n    for _ in range(2 if order in RETRIED else 1):\n        message_id = publisher.publish(topic, data, order_id=order).result()\n        print(f'{order} {customer} {cents:>6}  id {message_id}')\n", "note": "**`o-303` é publicado duas vezes**, como faz um publicador quando a primeira tentativa estourou o tempo e ele não sabe se a mensagem foi guardada. O Pub/Sub dá à segunda cópia um id de mensagem próprio. O id do pedido também vai como atributo, onde um consumidor o lê sem interpretar o corpo."}]}
```

```
ana@laptop:~/gcp$ python3 pay.py
o-301 c-17   4590  id 3
o-302 c-02  12800  id 4
o-303 c-17    990  id 5
o-303 c-17    990  id 6
o-304 c-05   2350  id 7
o-305 c-02   1500  id 8
o-306 c-17   7200  id 9
```

**Sete mensagens para seis pagamentos.** Os ids 5 e 6 guardam o mesmo pagamento, e os totais corretos
são as somas dos seis: 12.780 centavos para `c-17`, 14.300 para `c-02` e 2.350 para `c-05`. São esses os
números contra os quais conferir cada execução abaixo.

## O consumidor

Salve como `~/gcp/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sqlite3\nimport sys\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', 'totals')\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\n\n", "note": "**Um consumidor que soma cada pagamento ao total do cliente.** O modo escolhe o que ele confere antes de somar: nada, o id da mensagem ou o id do pedido. Um segundo argumento o faz cair depois de tantas mensagens, como um processo morre quando a máquina dele é tirada."}, {"code": "db = sqlite3.connect('totals.db')\ndb.execute('CREATE TABLE IF NOT EXISTS totals (customer_id TEXT PRIMARY KEY, cents INTEGER)')\ndb.execute('CREATE TABLE IF NOT EXISTS processed (key TEXT PRIMARY KEY)')\n\nADD = '''INSERT INTO totals VALUES (?, ?)\n         ON CONFLICT (customer_id) DO UPDATE SET cents = cents + excluded.cents'''\n\n\n", "note": "O destino é o SQLite, o banco num arquivo que vem com o Python. `totals` guarda as somas correntes e `processed` as chaves já aplicadas. `ADD` soma a um total, então **não é idempotente**: rodado duas vezes, conta duas vezes."}, {"code": "def apply(message, e):\n    with db:\n        if mode != 'plain':\n            key = message.message_id if mode == 'by-message-id' else e['order_id']\n            try:\n                db.execute('INSERT INTO processed VALUES (?)', (key,))\n            except sqlite3.IntegrityError:\n                return 'duplicate, skipped'\n        db.execute(ADD, (e['customer_id'], e['cents']))\n        return 'added'\n\n\n", "note": "**A deduplicação e o efeito são uma transação só**: `with db` confirma as duas escritas juntas ou nenhuma. Uma chave que já está em `processed` viola a chave primária, o insert falha, e nada é somado. Dois commits separados deixariam uma brecha, em que uma queda entre eles conta um pedido sem registrá-lo, ou o registra e nunca o conta."}, {"code": "done = 0\nwhile received := subscriber.pull(subscription=path, max_messages=10, timeout=5).received_messages:\n    for r in received:\n        if crash_after is not None and done == crash_after:\n            print(f'crash after {done} messages, before the ack')\n            os._exit(1)\n        e = json.loads(r.message.data)\n        print(f\"id {r.message.message_id:>2}  {e['order_id']} {e['customer_id']} {e['cents']:>6}  {apply(r.message, e)}\")\n        done += 1\n    subscriber.acknowledge(subscription=path, ack_ids=[r.ack_id for r in received])\nprint(f'{done} messages, acknowledged')\n", "note": "Ele puxa lotes de até dez até um pull voltar vazio, e **confirma cada lote depois de aplicá-lo**. Essa ordem, o trabalho e depois o ack, é o que o faz pelo menos uma vez: tudo o que foi puxado antes de uma queda volta."}]}
```

## Sem deduplicação

`plain`, mandado cair depois de quatro mensagens, e depois iniciado de novo, como um supervisor
reinicia um processo que morreu. O primeiro reinício é imediato:

```
ana@laptop:~/gcp$ python3 totals.py plain 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
crash after 4 messages, before the ack
ana@laptop:~/gcp$ python3 totals.py plain
0 messages, acknowledged
ana@laptop:~/gcp$ sleep 10; python3 totals.py plain
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 27100), ('c-05', 2350), ('c-17', 20340)]
```

**O reinício que veio na hora não achou nada, e o de dez segundos depois achou tudo.** A primeira
execução pegou as sete mensagens num pull só, somou quatro e morreu antes do ack, então as sete ainda
estavam emprestadas a um processo que não existia mais. O reinício imediato pediu, recebeu um pull
vazio e parou; o prazo não tinha acabado. Dez segundos depois, as sete foram entregues de novo.

**Todo total está errado, e nada imprimiu erro.** `c-17` saiu 20.340 em vez de 12.780: `o-301` contado
duas vezes pela nova entrega, e `o-303` quatro vezes, duas pela nova tentativa do publicador e mais duas
pela nova entrega. `c-02` deu 27.100 em vez de 14.300. Só `c-05` está certo, porque o pagamento dele não
estava entre os quatro aplicados antes da queda. É a entrega pelo menos uma vez funcionando como
projetada, num destino que não é idempotente.

## O reprocessamento, e uma deduplicação pelo id da mensagem

**O snapshot dá à execução uma segunda chance com as mesmas mensagens.** O seek de `totals` para
`totals-start` marca as sete mensagens como sem ack de novo, como o seek da aula 19 fez com
`analytics`, e apagar o `totals.db` começa as somas do zero. A chave óbvia para deduplicar é a que o
Pub/Sub dá a toda mensagem, o id dela:

```
ana@laptop:~/gcp$ rm totals.db && gcloud pubsub subscriptions seek totals --snapshot=totals-start
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
ana@laptop:~/gcp$ python3 totals.py by-message-id 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
crash after 4 messages, before the ack
ana@laptop:~/gcp$ sleep 10; python3 totals.py by-message-id
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 13770)]
```

**A nova entrega foi pega e a nova tentativa do publicador não.** Na segunda execução, os ids 3 a 6
foram recusados um a um, porque a primeira os tinha registrado em `processed` na mesma transação dos
totais. Mas os ids 5 e 6 são duas mensagens para um pagamento, e as duas foram somadas na primeira
execução: `c-17` dá 13.770, que é 12.780 mais um segundo `o-303`. Um id de mensagem identifica a
mensagem de uma entrega, não o evento que ela relata.

## Uma deduplicação pelo id do pedido

```
ana@laptop:~/gcp$ rm totals.db && gcloud pubsub subscriptions seek totals --snapshot=totals-start
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
ana@laptop:~/gcp$ python3 totals.py by-order-id 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  duplicate, skipped
crash after 4 messages, before the ack
ana@laptop:~/gcp$ sleep 10; python3 totals.py by-order-id
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 12780)]
```

**Os totais são os corretos**, 12.780, 14.300 e 2.350, com a mesma nova tentativa e a mesma queda. Na
primeira execução, a mensagem 6 falhou na deduplicação porque o id do pedido dela já tinha sido
registrado pela mensagem 5, e nada foi somado por ela. Na segunda execução, as quatro mensagens
entregues de novo falharam do mesmo jeito, e só as três que ninguém tinha aplicado foram somadas. O
consumidor continua pelo menos uma vez; o efeito agora é exatamente uma vez.

**E ele sobrevive ao pior caso, um reprocessamento da assinatura inteira:**

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek totals --snapshot=totals-start && python3 totals.py by-order-id
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  duplicate, skipped
id  8  o-305 c-02   1500  duplicate, skipped
id  9  o-306 c-17   7200  duplicate, skipped
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; db = sqlite3.connect('totals.db'); print(db.execute('SELECT * FROM totals ORDER BY 1').fetchall(), db.execute('SELECT count(*) FROM processed').fetchone())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 12780)] (6,)
```

Sete mensagens lidas, sete puladas, os totais iguais, e seis ids de pedido registrados, um por
pagamento. **É isso que idempotente quer dizer: rodar de novo não muda nada.** É também o que torna
seguro usar o seek da aula 19. Guardar uma semana de retenção para reprocessar um deploy ruim é só
metade da segunda chance; a outra metade é um consumidor que pode ser apontado uma semana para trás sem
estragar o que já gravou.

## O que a deduplicação custa

**Uma escrita a mais por mensagem, e uma tabela que cresce.** Todo pagamento agora custa um insert em
`processed` ao lado da atualização do total, e a tabela ganha uma linha por evento para sempre. A saída é apagar
as chaves antigas depois de uma janela um pouco maior que o reprocessamento mais longo que alguém
faria, como a retenção do tópico mais uma margem. Um duplicado mais velho que essa
janela não é mais pego, e essa é a troca, feita ao escolher a janela. Num banco gerenciado, a escrita a
mais é uma linha na conta: o preço por escrita de documento do Firestore, da aula 10, ou uma linha no
Cloud SQL, da aula 6.
