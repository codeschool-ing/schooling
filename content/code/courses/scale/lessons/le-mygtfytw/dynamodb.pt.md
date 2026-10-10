---
title: DynamoDB, uma chave em duas partes
version: 1
---

O DynamoDB guarda **itens** em **tabelas**. Todo item tem uma **chave primária**, e a chave é o
desenho inteiro: ela decide onde o item mora e é a única coisa pela qual uma leitura rápida pode
perguntar. Uma chave tem uma ou duas partes:

- a **chave de partição**, que passa por um hash para escolher a partição que guarda o item, como no
  sharding da aula 2;
- uma **chave de ordenação** opcional, que mantém ordenados os itens de uma mesma chave de partição,
  como a chave de agrupamento do Cassandra na aula 4.

O padrão de acesso da bilheteria aqui é "os ingressos de um comprador", e "os ingressos de um
comprador para um show". Então a chave de partição é o comprador, e a chave de ordenação é o
ingresso, escrito como `show-1#seat-42`: o show primeiro, para que os ingressos de um comprador para
um show fiquem lado a lado na ordem. **Juntar dois valores numa chave de ordenação, na ordem em que a
consulta estreita, é o movimento mais comum do desenho no DynamoDB.**

## Rodando

O DynamoDB Local é um contêiner. O cliente dele é a linha de comando da AWS, que também roda num
contêiner, então um alias do shell poupa digitá-lo toda vez. O alias roda o `aws dynamodb` dentro da
imagem `amazon/aws-cli`, na rede do DynamoDB Local, com o diretório atual montado para que ele leia
arquivos de lá, e com credenciais que o DynamoDB Local aceita e ignora:

```sh
alias ddb='docker run --rm --network container:dynamo -v "$PWD":/aws -w /aws -e AWS_ACCESS_KEY_ID=local -e AWS_SECRET_ACCESS_KEY=local -e AWS_DEFAULT_REGION=sa-east-1 amazon/aws-cli:2.31.0 dynamodb --endpoint-url http://localhost:8000'
```

Um alias dura enquanto o terminal estiver aberto; digite-o de novo num novo. Os ingressos a carregar,
no formato de pedido que o `batch-write-item` do DynamoDB espera, em YAML para poder levar um
comentário:

```yaml
# tickets.yaml
RequestItems:
  tickets:
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-1#seat-42"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-1#seat-43"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: ana}, ticket: {S: "show-7#seat-3"}, cents: {N: "9000"}}
    - PutRequest:
        Item: {buyer: {S: bia}, ticket: {S: "show-1#seat-44"}, cents: {N: "18000"}}
    - PutRequest:
        Item: {buyer: {S: caio}, ticket: {S: "show-7#seat-4"}, cents: {N: "9000"}}
```

Cada atributo leva o seu tipo: `S` para texto, `N` para número, que o DynamoDB transmite como texto
para que nenhuma precisão se perca no caminho. Agora o servidor, a tabela e os itens:

```
ana@lab:~/tickets$ docker run -d --name dynamo amazon/dynamodb-local:3.3.0
843f57821680feb59b0bd8fdb773edee88c17a1cced7180e177b23f1cea25a26
ana@lab:~/tickets$ ddb create-table --table-name tickets --attribute-definitions AttributeName=buyer,AttributeType=S AttributeName=ticket,AttributeType=S --key-schema AttributeName=buyer,KeyType=HASH AttributeName=ticket,KeyType=RANGE --billing-mode PAY_PER_REQUEST --query TableDescription.TableStatus --output text
ACTIVE
ana@lab:~/tickets$ ddb batch-write-item --cli-input-yaml file://tickets.yaml
{
    "UnprocessedItems": {}
}
```

O `create-table` nomeia os dois atributos da chave, que são os únicos que uma tabela declara; todo
o resto de um item é livre. `PAY_PER_REQUEST` é o modo de cobrança em que o serviço de verdade cobra
por leitura e escrita em vez de capacidade reservada, a que a seção 06 volta. `ACTIVE` quer dizer
que a tabela está pronta, e `UnprocessedItems` vazio quer dizer que todo item foi gravado.

## A pergunta para a qual ele foi feito

Os ingressos de um comprador para o show 1:

```
ana@lab:~/tickets$ ddb query --table-name tickets --key-condition-expression 'buyer = :b AND begins_with(ticket, :s)' --expression-attribute-values '{":b": {"S": "ana"}, ":s": {"S": "show-1#"}}' --return-consumed-capacity TOTAL
{
    "Items": [
        {
            "ticket": {
                "S": "show-1#seat-42"
            },
            "cents": {
                "N": "18000"
            },
            "buyer": {
                "S": "ana"
            }
        },
        {
            "ticket": {
                "S": "show-1#seat-43"
            },
            "cents": {
                "N": "18000"
            },
            "buyer": {
                "S": "ana"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": {
        "TableName": "tickets",
        "CapacityUnits": 0.5
    }
}
```

Uma **consulta** (*query*) nomeia um valor de chave de partição, `buyer = ana`, e pode estreitar a
chave de ordenação, aqui `begins_with(ticket, "show-1#")`. Voltaram dois ingressos, lidos em ordem de
uma partição. `ScannedCount` é quantos itens o DynamoDB leu, e `Count` quantos devolveu: dois e dois,
**nada desperdiçado**. `ConsumedCapacity` é quanto o pedido custou, nas unidades que o serviço cobra.
