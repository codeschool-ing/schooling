---
title: Em ordem por shard, e só por shard
version: 1
---

**O Kinesis mantém a ordem dos registros dentro de um shard e não promete nada entre shards.** Quem
imagina o stream como uma fila única de eventos, lida de volta na ordem em que aconteceram, um dia vai
processar uma entrega antes do pedido a que ela pertence. O que tem ordem é o log de cada shard, e como
uma chave de partição sempre cai no mesmo shard, o que tem ordem na prática são **os eventos de cada
chave**. Dois programas mostram isso: um escreve os eventos de pedido da Quitanda, o outro os lê de
volta.

## Um produtor

Copie-o para `~/aws/producer.py` com o botão do bloco:

```schooling-example
{"language": "python", "file": "producer.py", "parts": [{"code": "import json\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\nstream = sys.argv[1]\n\n", "note": "O nome do stream vem da linha de comando, então o mesmo programa alimenta todos os streams desta lição. O `boto3` lê o endpoint, as chaves e a região das variáveis que o terminal exportou, exatamente como o `aws` faz."}, {"code": "EVENTS = [\n    ('o-101', 'c-17', 'placed'), ('o-102', 'c-02', 'placed'),\n    ('o-101', 'c-17', 'packed'), ('o-103', 'c-05', 'placed'),\n    ('o-102', 'c-02', 'packed'), ('o-101', 'c-17', 'delivered'),\n    ('o-103', 'c-05', 'cancelled'), ('o-104', 'c-03', 'placed'),\n    ('o-102', 'c-02', 'delivered'), ('o-104', 'c-03', 'packed'),\n]\n\n", "note": "Dez eventos de quatro pedidos de quatro clientes. Um pedido é feito (`placed`), embalado (`packed`) e entregue (`delivered`), ou cancelado (`cancelled`), e a ordem desses eventos é o que um leitor não pode errar."}, {"code": "for order, customer, status in EVENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'status': status})\n    r = kinesis.put_record(StreamName=stream, PartitionKey=customer, Data=data.encode())\n    print(f\"{order} {status:<9} key {customer}  {r['ShardId']}  seq {r['SequenceNumber']}\")\n", "note": "**Um `PutRecord` por evento, com o cliente como chave.** O dado são bytes, aqui uma linha de JSON, e o Kinesis nunca olha dentro dele. A resposta diz o shard para onde o registro foi e o número de sequência que ele recebeu lá."}]}
```
```
ana@laptop:~/aws$ python3 producer.py orders
o-101 placed    key c-17  shardId-000000000000  seq 1
o-102 placed    key c-02  shardId-000000000001  seq 1
o-101 packed    key c-17  shardId-000000000000  seq 2
o-103 placed    key c-05  shardId-000000000001  seq 2
o-102 packed    key c-02  shardId-000000000001  seq 3
o-101 delivered key c-17  shardId-000000000000  seq 3
o-103 cancelled key c-05  shardId-000000000001  seq 4
o-104 placed    key c-03  shardId-000000000000  seq 4
o-102 delivered key c-02  shardId-000000000001  seq 5
o-104 packed    key c-03  shardId-000000000000  seq 5
```

**Todo registro foi para onde o `shard_of.py` previu**: `c-17` e `c-03` para o shard 0, `c-02` e
`c-05` para o shard 1. E cada shard numerou os próprios registros a partir de 1, que é a primeira
coisa a notar sobre um **número de sequência**: ele é uma posição num shard, e dois registros em
shards diferentes com o mesmo número não têm nada a ver um com o outro.

**Os números de sequência do moto são inteiros pequenos, e os da AWS não.** Na AWS um número de
sequência é uma string longa de dígitos decimais, grande demais para um inteiro de 64 bits, único
dentro do shard e crescente com o tempo. Código que guarda um deve guardá-lo como string, e código que
compara dois do mesmo shard deve compará-los como números de tamanho arbitrário, nunca como texto:
como texto, `"9"` fica depois de `"10"`. Um teste contra o moto que passa com `int()` em números
pequenos não diz nada sobre isso.

## Um consumidor

Copie-o para `~/aws/consumer.py`:

```schooling-example
{"language": "python", "file": "consumer.py", "parts": [{"code": "import json\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\nstream = sys.argv[1]\n\n", "note": "O mesmo começo do produtor: um cliente, e o stream nomeado na linha de comando."}, {"code": "for shard in kinesis.list_shards(StreamName=stream)['Shards']:\n    sid = shard['ShardId']\n    print(sid)\n", "note": "**Um consumidor lê shard por shard.** Não existe chamada que leia \"o stream\": o `ListShards` nomeia os shards, e cada um é lido por conta própria, com o seu iterador."}, {"code": "    it = kinesis.get_shard_iterator(StreamName=stream, ShardId=sid,\n                                    ShardIteratorType='TRIM_HORIZON')['ShardIterator']\n", "note": "Um iterador é uma posição num shard. `TRIM_HORIZON` é o registro mais antigo que o shard ainda guarda, então isto lê tudo."}, {"code": "    while it:\n        out = kinesis.get_records(ShardIterator=it, Limit=100)\n        for rec in out['Records']:\n            e = json.loads(rec['Data'])\n            print(f\"  seq {rec['SequenceNumber']:>2}  {e['order_id']} {e['status']:<9} {rec['PartitionKey']}\")\n        if not out['Records'] and out['MillisBehindLatest'] == 0:\n            break\n        it = out.get('NextShardIterator')\n", "note": "Cada `GetRecords` devolve um lote e o iterador do próximo. Um consumidor de verdade fica em laço para sempre e dorme quando um lote vem vazio; este para quando um lote vem vazio e o `MillisBehindLatest` diz que chegou ao fim do shard, para que possa ser rodado e lido."}]}
```
```
ana@laptop:~/aws$ python3 consumer.py orders
shardId-000000000000
  seq  1  o-101 placed    c-17
  seq  2  o-101 packed    c-17
  seq  3  o-101 delivered c-17
  seq  4  o-104 placed    c-03
  seq  5  o-104 packed    c-03
shardId-000000000001
  seq  1  o-102 placed    c-02
  seq  2  o-103 placed    c-05
  seq  3  o-102 packed    c-02
  seq  4  o-103 cancelled c-05
  seq  5  o-102 delivered c-02
```

**Dentro de cada shard a ordem é exatamente a ordem de escrita.** No shard 0, o `o-101` é feito,
embalado e entregue, nessa ordem, e o `o-104` vem depois dele. No shard 1, o `o-102` e o `o-103` se
intercalam do jeito que foram escritos. Leia os eventos de um cliente e eles fazem sentido.

**Entre os shards a ordem se perdeu.** O produtor escreveu `o-102 placed` em segundo lugar, logo
depois de `o-101 placed`, e o consumidor o imprimiu em sexto, depois de tudo do shard 0, porque leu os
shards um depois do outro. Um consumidor que lê os dois shards ao mesmo tempo, como um de verdade faz
com um worker por shard, os intercalaria de algum outro jeito, diferente a cada execução. Nada nos
registros diz qual foi a ordem global, fora o `ApproximateArrivalTimestamp`, que é a hora em que o
Kinesis recebeu cada registro e é, como o nome diz, aproximada. **Se uma pergunta precisa da ordem dos
eventos entre chaves, o stream não sabe responder**; os eventos precisam carregar um horário próprio, e
o leitor precisa ordenar por ele, sabendo que alguns vão chegar atrasados.

## O que a ordem não aguenta

Duas coisas quebram até a ordem dentro de uma chave, e as duas são obra do produtor. A primeira é **um
retry**: quando um `PutRecord` estoura o tempo, o produtor não tem como saber se o registro foi
escrito, então o manda de novo. O shard pode agora ter o mesmo evento duas vezes, ou um evento e
depois um mais antigo que foi reenviado depois dele. A segunda é **escrever em paralelo**: duas
threads pondo registros da mesma chave disputam entre si, e o shard fica com o que chegou primeiro. O
`PutRecord` aceita um `SequenceNumberForOrdering`, o número de sequência do registro anterior, para
manter em ordem estrita os registros de um produtor; o `PutRecords`, que escreve até 500 registros
numa chamada, não promete ordem nenhuma, nem dentro do próprio lote. A lição 23 trata dos duplicados e
do que um consumidor faz com eles.
