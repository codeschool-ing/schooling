---
title: Um consumidor que cai, contado duas vezes e depois uma
version: 1
---

**Esta seção faz um duplicado acontecer e depois o torna inofensivo, num programa que você pode
rodar.** O cenário são os pagamentos da Quitanda: um stream do Kinesis com um registro por pedido pago,
e um consumidor que mantém o total acumulado de cada cliente no DynamoDB. Os totais são o tipo de
número que alguém reporta ao financeiro, então contar um pedido duas vezes não é erro de
arredondamento; é uma fatura errada.

O terminal é o da lição 1, com o moto vazio. Um stream de um shard, e duas tabelas, uma para os totais
e uma para os ids de pedido já processados:

```sh
aws kinesis create-stream --stream-name payments --shard-count 1
aws dynamodb create-table --table-name quitanda-totals --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=customer_id,AttributeType=S \
  --key-schema AttributeName=customer_id,KeyType=HASH > /dev/null
aws dynamodb create-table --table-name quitanda-processed --billing-mode PAY_PER_REQUEST \
  --attribute-definitions AttributeName=order_id,AttributeType=S \
  --key-schema AttributeName=order_id,KeyType=HASH > /dev/null
```

## O produtor, com um retry dentro

Salve-o como `~/aws/pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "import json\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\n\n", "note": "Um shard basta para mostrar tudo de que esta lição trata, e deixa o consumidor com um iterador só. O stream é criado pelos comandos acima deste bloco."}, {"code": "PAYMENTS = [\n    ('o-301', 'c-17', 4590), ('o-302', 'c-02', 12800), ('o-303', 'c-17', 990),\n    ('o-304', 'c-05', 2350), ('o-305', 'c-02', 1500), ('o-306', 'c-17', 7200),\n]\n", "note": "Seis pagamentos de três clientes. A chave de idempotência é o id do pedido: um pedido é pago uma vez, então um segundo registro do mesmo pedido é um duplicado, seja qual for a causa."}, {"code": "RETRIED = {'o-303'}\n\nfor order, customer, cents in PAYMENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'cents': cents}).encode()\n    for _ in range(2 if order in RETRIED else 1):\n        r = kinesis.put_record(StreamName='payments', PartitionKey=customer, Data=data)\n        print(f\"{order} {customer} {cents:>6}  seq {r['SequenceNumber']}\")\n", "note": "**`o-303` é mandado duas vezes**, como um produtor faz quando o primeiro `PutRecord` estourou o tempo e ele não sabe se o registro foi escrito. O Kinesis dá à segunda cópia um número de sequência próprio."}]}
```
```
ana@laptop:~/aws$ python3 pay.py
o-301 c-17   4590  seq 1
o-302 c-02  12800  seq 2
o-303 c-17    990  seq 3
o-303 c-17    990  seq 4
o-304 c-05   2350  seq 5
o-305 c-02   1500  seq 6
o-306 c-17   7200  seq 7
```

**Sete registros para seis pagamentos.** Os números de sequência 3 e 4 guardam o mesmo pagamento, e os
totais certos são as somas dos seis: 12.780 centavos para `c-17`, 14.300 para `c-02` e 2.350 para
`c-05`. São esses os números a comparar abaixo.

## O consumidor

Salve-o como `~/aws/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\ndynamodb = boto3.client('dynamodb')\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\nSHARD = 'shardId-000000000000'\n\n", "note": "**Um consumidor que soma cada pagamento ao total do cliente.** `plain` soma todo registro que lê; `dedupe` primeiro registra o id do pedido e só soma se aquele pedido nunca foi visto. Um segundo argumento o faz cair depois de tantos registros, do jeito que um processo morre quando a máquina dele é trocada."}, {"code": "if os.path.exists('checkpoint.txt'):\n    start = {'ShardIteratorType': 'AFTER_SEQUENCE_NUMBER',\n             'StartingSequenceNumber': open('checkpoint.txt').read()}\nelse:\n    start = {'ShardIteratorType': 'TRIM_HORIZON'}\nit = kinesis.get_shard_iterator(StreamName='payments', ShardId=SHARD, **start)['ShardIterator']\n\n", "note": "O checkpoint é o número de sequência do último registro terminado, guardado num arquivo. Sem checkpoint o consumidor começa em `TRIM_HORIZON`; com um, logo depois dele. A Kinesis Client Library guarda a mesma coisa numa tabela do DynamoDB."}, {"code": "add = {'TableName': 'quitanda-totals',\n       'UpdateExpression': 'ADD cents :c'}\n\n\n", "note": "`ADD` é o destino que não é idempotente: aplicado duas vezes, conta duas vezes."}, {"code": "def apply(e):\n    key = {'customer_id': {'S': e['customer_id']}}\n    value = {':c': {'N': str(e['cents'])}}\n    if mode == 'plain':\n        dynamodb.update_item(Key=key, ExpressionAttributeValues=value, **add)\n        return 'added'\n    try:\n        dynamodb.transact_write_items(TransactItems=[\n            {'Put': {'TableName': 'quitanda-processed',\n                     'Item': {'order_id': {'S': e['order_id']}},\n                     'ConditionExpression': 'attribute_not_exists(order_id)'}},\n            {'Update': {'Key': key, 'ExpressionAttributeValues': value, **add}},\n        ])\n        return 'added'\n    except dynamodb.exceptions.TransactionCanceledException:\n        return 'duplicate, skipped'\n\n\n", "note": "**A deduplicação e o efeito são uma transação só.** O `Put` em `quitanda-processed` leva `attribute_not_exists`, então falha se o id do pedido já está lá, e quando qualquer parte de uma transação falha, nada dela acontece. Duas escritas separadas deixariam um buraco: uma queda entre elas contaria um pedido sem registrá-lo, ou o registraria e nunca o contaria."}, {"code": "done, last = 0, None\nwhile it:\n    out = kinesis.get_records(ShardIterator=it)\n    for rec in out['Records']:\n        if crash_after is not None and done == crash_after:\n            print(f'crash after {done} records, before the checkpoint')\n            os._exit(1)\n        e = json.loads(rec['Data'])\n        print(f\"seq {rec['SequenceNumber']}  {e['order_id']} {e['customer_id']} {e['cents']:>6}  {apply(e)}\")\n        done, last = done + 1, rec['SequenceNumber']\n    if not out['Records'] and out['MillisBehindLatest'] == 0:\n        break\n    it = out.get('NextShardIterator')\nif last:\n    open('checkpoint.txt', 'w').write(last)\n    print(f'checkpoint at seq {last}')\n", "note": "O laço lê até o fim do shard, como o `consumer.py` da lição 20 fazia. **O checkpoint é escrito uma vez, no fim**, e é isso que faz disto pelo menos uma vez: tudo o que foi lido antes de uma queda é lido de novo."}]}
```

## Sem a deduplicação

`plain`, mandado cair depois de quatro registros, e depois ligado de novo, como um supervisor reinicia
um processo que morreu:

```
ana@laptop:~/aws$ python3 totals.py plain 4
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  added
crash after 4 records, before the checkpoint
ana@laptop:~/aws$ ls checkpoint.txt
ls: cannot access 'checkpoint.txt': No such file or directory
ana@laptop:~/aws$ python3 totals.py plain
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  added
seq 5  o-304 c-05   2350  added
seq 6  o-305 c-02   1500  added
seq 7  o-306 c-17   7200  added
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	27100
c-05	2350
c-17	20340
```

**Todos os números estão errados, e nada imprimiu um erro.** A primeira execução somou quatro
registros e morreu antes de escrever um checkpoint, então o `checkpoint.txt` não existe e a segunda
execução começou em `TRIM_HORIZON`, somando esses quatro de novo. `c-17` deu 20.340 em vez de 12.780:
`o-301` contado duas vezes pelo reprocessamento, e `o-303` quatro vezes, duas pelo retry do produtor e
mais duas pelo reprocessamento. `c-02` deu 27.100 em vez de 14.300. Só `c-05` está certo, porque o
pagamento dele veio depois da queda. Isso é entrega pelo menos uma vez funcionando exatamente como
projetada, num destino que não é idempotente.

## Com a deduplicação

As mesmas duas execuções no modo `dedupe`, a partir de uma tabela de totais nova e sem checkpoint. O
moto respondeu ao `delete-table` com `ACTIVE`, onde a AWS responde `DELETING` e leva um instante; a
tabela tinha sumido de qualquer jeito quando foi criada de novo:

```
ana@laptop:~/aws$ rm checkpoint.txt && aws dynamodb delete-table --table-name quitanda-totals --query TableDescription.TableStatus
"ACTIVE"
ana@laptop:~/aws$ aws dynamodb create-table --table-name quitanda-totals --billing-mode PAY_PER_REQUEST --attribute-definitions AttributeName=customer_id,AttributeType=S --key-schema AttributeName=customer_id,KeyType=HASH --query TableDescription.TableStatus
"ACTIVE"
ana@laptop:~/aws$ python3 totals.py dedupe 4
seq 1  o-301 c-17   4590  added
seq 2  o-302 c-02  12800  added
seq 3  o-303 c-17    990  added
seq 4  o-303 c-17    990  duplicate, skipped
crash after 4 records, before the checkpoint
ana@laptop:~/aws$ python3 totals.py dedupe
seq 1  o-301 c-17   4590  duplicate, skipped
seq 2  o-302 c-02  12800  duplicate, skipped
seq 3  o-303 c-17    990  duplicate, skipped
seq 4  o-303 c-17    990  duplicate, skipped
seq 5  o-304 c-05   2350  added
seq 6  o-305 c-02   1500  added
seq 7  o-306 c-17   7200  added
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	14300
c-05	2350
c-17	12780
```

**Os totais são os certos**, 12.780, 14.300 e 2.350, passando pelo mesmo retry do produtor e pela mesma
queda. Na primeira execução, a segunda cópia de `o-303` falhou a condição, porque o id do pedido já
estava em `quitanda-processed`, e a transação cancelou as duas escritas dela. Na segunda execução, o
reprocessamento dos quatro primeiros registros falhou do mesmo jeito, um por um, e só os três
registros que ninguém tinha processado foram somados. O consumidor continua pelo menos uma vez; o
efeito agora é exatamente uma vez.

**E ele aguenta o pior caso, reprocessar o stream inteiro:**

```
ana@laptop:~/aws$ rm checkpoint.txt && python3 totals.py dedupe
seq 1  o-301 c-17   4590  duplicate, skipped
seq 2  o-302 c-02  12800  duplicate, skipped
seq 3  o-303 c-17    990  duplicate, skipped
seq 4  o-303 c-17    990  duplicate, skipped
seq 5  o-304 c-05   2350  duplicate, skipped
seq 6  o-305 c-02   1500  duplicate, skipped
seq 7  o-306 c-17   7200  duplicate, skipped
checkpoint at seq 7
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text
c-02	14300
c-05	2350
c-17	12780
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda-processed --select COUNT --query Count
6
```

Sete registros lidos, sete pulados, os totais iguais, e seis ids de pedido registrados, um por
pagamento. **É isso que idempotente quer dizer: rodar de novo não muda nada.** É também o que torna
seguro reprocessar. O conselho da lição 20 de guardar uma semana de retenção como segunda chance é só
metade da história; a outra metade é um consumidor que pode ser apontado de volta para o
`TRIM_HORIZON` sem corromper o que já escreveu.

## Quanto custa a tabela de deduplicação

**Uma escrita a mais por registro, e uma tabela que cresce.** Todo pagamento agora custa um `Put`
condicional e um `Update` dentro de uma transação, e o DynamoDB cobra uma escrita transacional pelo dobro de uma comum. Então a conta de escrita do consumidor fica cerca de quatro vezes a do `plain`; os
preços da lição 11 fazem disso um número para um dado volume. A tabela de ids processados cresce um
item por evento para sempre, a não ser que cada item leve um tempo de vida (TTL) um pouco maior que o
reprocessamento mais longo que alguém faria, como a retenção do stream mais uma folga, depois do qual o
DynamoDB o apaga de graça. Um duplicado mais velho que essa janela deixa de ser pego, que é a troca, e
ela é feita de propósito ao escolher a janela.
