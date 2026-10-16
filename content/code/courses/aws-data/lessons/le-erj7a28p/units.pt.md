---
title: Unidades de leitura e unidades de escrita
version: 1
---

**O DynamoDB não cobra por requisição nem por tempo; cobra por unidade, e uma unidade é um tamanho.**
Uma unidade de leitura é uma leitura fortemente consistente de um item de até 4 KB. Uma unidade de
escrita é uma escrita de um item de até 1 KB. Todo o resto é múltiplo dessas duas, e os múltiplos são a
aritmética inteira:

| a operação | o que custa |
|---|---|
| leitura fortemente consistente | 1 unidade por 4 KB do item, arredondado para cima |
| leitura eventualmente consistente, o padrão | metade disso |
| leitura dentro de uma transação | o dobro do preço fortemente consistente |
| escrita, seja put, update ou delete | 1 unidade por 1 KB do item, arredondado para cima |
| escrita dentro de uma transação | o dobro disso |

**O arredondamento é por item num `get-item`, num `put-item` e em cada item de um lote, e por página
numa `query` ou num `scan`.** Numa página os tamanhos de todos os itens lidos são somados primeiro e o
total é arredondado, que é o que o `pages.py` da lição 10 contou. Um update é cobrado pelo maior entre o
item antes e o item depois. Uma escrita que uma condição recusou ainda é cobrada, como disse a lição 9.
E todo índice que guarda o item acrescenta a sua escrita, como disse a lição 10.

## Um item, com preço calculado à mão

O catálogo de produtos da Quitanda guarda uma descrição longa em cada produto. A tabela dele tem chave
no código do produto, e é sob demanda como a da lição 9:

```sh
aws dynamodb create-table --table-name products \
  --attribute-definitions AttributeName=sku,AttributeType=S \
  --key-schema AttributeName=sku,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

**O tamanho de um item é o comprimento do nome de cada atributo mais o valor dele.** Um café com uma
descrição de 9.000 caracteres tem `sku` (3) e `coffee-500g` (11), depois `description` (11) e os 9.000:
**9.025 bytes**. Então, pela tabela acima:

| | unidades |
|---|---|
| escrevê-lo | 9.025 / 1.024 = 8,8, então **9** |
| lê-lo de forma fortemente consistente | 9.025 / 4.096 = 2,2, então **3** |
| lê-lo de forma eventualmente consistente | **1,5** |
| lê-lo numa transação | **6** |
| escrevê-lo numa transação | **18** |

**Uma descrição curta muda todas as linhas.** Com 900 caracteres o mesmo item tem 925 bytes: uma
unidade de escrita e meia de leitura. O tamanho de um item é a primeira decisão sobre o preço dele, e é
por isso que atributos grandes e pouco lidos, uma foto ou um texto longo, costumam morar no S3, com só a
chave deles no item.

## O que o moto diz em vez disso

Peça ao moto as unidades das mesmas operações, com `--return-consumed-capacity TOTAL`, no mesmo item. O
comando que grava o item num arquivo é o da primeira linha:

```
ana@laptop:~/aws$ python3 -c "import json; print(json.dumps({'sku': {'S': 'coffee-500g'}, 'description': {'S': 'x' * 9000}}))" > coffee.json
ana@laptop:~/aws$ wc -c coffee.json
9056 coffee.json
ana@laptop:~/aws$ aws dynamodb put-item --table-name products --item file://coffee.json --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
1.0
ana@laptop:~/aws$ aws dynamodb get-item --table-name products --key '{"sku": {"S": "coffee-500g"}}' --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
0.5
ana@laptop:~/aws$ aws dynamodb get-item --table-name products --key '{"sku": {"S": "coffee-500g"}}' --consistent-read --return-consumed-capacity TOTAL --query ConsumedCapacity.CapacityUnits
0.5
ana@laptop:~/aws$ aws dynamodb transact-get-items --transact-items '[{"Get": {"TableName": "products", "Key": {"sku": {"S": "coffee-500g"}}}}]' --return-consumed-capacity TOTAL --query 'ConsumedCapacity[0].CapacityUnits'
2.0
ana@laptop:~/aws$ aws dynamodb transact-write-items --transact-items '[{"Put": {"TableName": "products", "Item": {"sku": {"S": "tea-250g"}}}}]' --return-consumed-capacity TOTAL --query ConsumedCapacity
[]
```

**1; 0,5; 0,5; 2 e uma lista vazia, onde a AWS diria 9; 1,5; 3; 6 e 18.** O arquivo tem 9.056 bytes de
JSON, o item dentro dele 9.025 pela regra da AWS, e o moto respondeu a escrita dele com o número que dá
a toda escrita. As leituras dele são meia unidade fixa, fortemente consistentes ou não. A leitura
transacional é um dois fixo, e a escrita transacional não informa nada. **O `ConsumedCapacity` do moto é
uma constante por operação, não uma medida**, então neste curso as unidades são sempre contadas à mão ou
por um programa como o `pages.py`, e nunca lidas no moto. Um número com a forma certa e o valor errado é
a coisa mais convincente que o moto produz.
