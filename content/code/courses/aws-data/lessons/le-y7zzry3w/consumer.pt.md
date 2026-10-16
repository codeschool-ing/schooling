---
title: Um consumidor que mantém um total corrente
version: 1
---

**Um leitor de stream é um laço sobre shards e iteradores, e o que ele faz com cada registro é a
aplicação.** O app da Quitanda mostra a cada cliente quanto gastou neste mês. Somar os pedidos de um
cliente em toda tela é uma query que cresce com o histórico; manter um número por cliente, mexido por
toda mudança num pedido, é um `get-item` só. É o stream que mantém esse número honesto: toda mudança num
pedido, feita por qualquer programa, chega até ele.

Os totais moram numa tabela própria, para que escrevê-los não acrescente registros ao stream que está
sendo lido:

```sh
aws dynamodb create-table --table-name quitanda-totals \
  --attribute-definitions AttributeName=pk,AttributeType=S \
  --key-schema AttributeName=pk,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

**O programa lê todo shard desde o registro mais antigo e, para cada mudança num pedido, soma a diferença
ao total daquele cliente.** Salve-o como `~/aws/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Keep a running total per customer from the stream of the table `quitanda`.\n\n    python3 totals.py           # apply each change once, however often it is read\n    python3 totals.py --naive   # apply whatever arrives, as a careless consumer would\n\nReads every shard from the oldest record still kept, and writes the totals\ninto the table `quitanda-totals`. Needs the stream view NEW_AND_OLD_IMAGES.\n\"\"\"\nimport sys\n\nimport boto3\nfrom botocore.exceptions import ClientError\n\ndb = boto3.client('dynamodb')\nstreams = boto3.client('dynamodbstreams')\nTOTALS = 'quitanda-totals'\nnaive = '--naive' in sys.argv\n\n\n", "note": "O manual. Um leitor de stream que mantém um número por cliente, o total dos pedidos dele, numa tabela própria."}, {"code": "def change(record):\n    keys = record['dynamodb']['Keys']\n    sk = keys['sk']['S']\n    if not sk.startswith('ORDER#') or '#LINE#' in sk:\n        return None\n    def total(image):\n        return int(record['dynamodb'].get(image, {}).get('total_cents', {}).get('N', 0))\n    return keys['pk']['S'], total('NewImage') - total('OldImage')\n\n\n", "note": "**Um registro é uma mudança num item.** Só pedidos mexem num total, então perfis e linhas são pulados pela chave de ordenação. Um `INSERT` só tem imagem nova, um `REMOVE` só antiga, um `MODIFY` as duas, então em todo caso a mudança é o total novo menos o antigo, com uma imagem ausente contando como zero."}, {"code": "def apply(customer, cents, event_id):\n    add = {'Update': {'TableName': TOTALS, 'Key': {'pk': {'S': customer}},\n                      'UpdateExpression': 'ADD total_cents :c',\n                      'ExpressionAttributeValues': {':c': {'N': str(cents)}}}}\n    seen = {'Put': {'TableName': TOTALS, 'Item': {'pk': {'S': 'EVENT#' + event_id}},\n                    'ConditionExpression': 'attribute_not_exists(pk)'}}\n    try:\n        db.transact_write_items(TransactItems=[add] if naive else [seen, add])\n        return True\n    except ClientError as e:\n        if e.response['Error']['Code'] == 'TransactionCanceledException':\n            return False\n        raise\n\n\n", "note": "**A mudança é somada numa transação junto com um marcador do `eventID` do registro**, escrito só se ainda não existir marcador para ele. Um registro já aplicado cancela a própria transação, e o total fica como estava. `--naive` manda só a soma, que é o que um consumidor sem o marcador faz."}, {"code": "arn = db.describe_table(TableName='quitanda')['Table']['LatestStreamArn']\nshards = streams.describe_stream(StreamArn=arn)['StreamDescription']['Shards']\napplied = skipped = 0\nfor shard in shards:\n    iterator = streams.get_shard_iterator(StreamArn=arn, ShardId=shard['ShardId'],\n                                          ShardIteratorType='TRIM_HORIZON')['ShardIterator']\n    while iterator:\n        batch = streams.get_records(ShardIterator=iterator)\n        if not batch['Records']:\n            break\n        for record in batch['Records']:\n            found = change(record)\n            if found and apply(*found, record['eventID']):\n                applied += 1\n            elif found:\n                skipped += 1\n        iterator = batch.get('NextShardIterator')\n\n", "note": "**Todo shard, a partir de `TRIM_HORIZON`**, o registro mais antigo que o stream ainda guarda. Cada `get_records` devolve um lote e o iterador do próximo. Este leitor para no primeiro lote vazio, o que é certo para um programa rodado à mão depois que as escritas terminaram e errado para um shard aberto na AWS, onde um lote vazio só quer dizer nada de novo ainda; um leitor de longa duração continua consultando."}, {"code": "print(f'{len(shards)} shard(s): {applied} changes applied, {skipped} already applied')\nfor item in db.scan(TableName=TOTALS)['Items']:\n    if item['pk']['S'].startswith('CUSTOMER#'):\n        print(f\"  {item['pk']['S']:<16}{int(item['total_cents']['N']) / 100:>10.2f}\")\n", "note": "O que ele fez, e os totais como estão agora, em reais."}]}
```

```
ana@laptop:~/aws$ python3 totals.py
1 shard(s): 11 changes applied, 0 already applied
  CUSTOMER#c-17       275.69
  CUSTOMER#c-18        72.27
  CUSTOMER#c-19       321.59
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#"}}' --query "sum(Items[?!contains(sk.S, '#LINE#')].to_number(total_cents.N))"
27569
```

**Onze mudanças aplicadas, e c-17 está em 275,69 reais.** Nove foram os pedidos que a carga inseriu, uma
o `MODIFY` que aumentou o pedido de 12 de outubro e uma o `REMOVE` do pedido de 3 de outubro; os
vinte e cinco perfis e linhas do stream foram pulados pelas chaves. A query abaixo dos totais pergunta à
própria tabela, somando os pedidos de c-17 com um `sum` do JMESPath na linha de comando, e responde 27569
centavos: o mesmo número por outro caminho. Um total corrente que nunca foi comparado com os dados que
resume é um número que ninguém garante, e na AWS a comparação é o teste que acha um consumidor que perdeu
um registro.

**O moto listou os totais em ordem de chave** porque o scan dele é um dicionário; na AWS as três linhas
poderiam voltar em qualquer ordem.
