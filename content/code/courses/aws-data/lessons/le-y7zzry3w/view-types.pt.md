---
title: O que um registro carrega
version: 1
---

**O tipo de visão decide quanto do item cada registro carrega, e é escolhido quando o stream é
ligado.** São quatro:

| tipo de visão | cada registro carrega |
|---|---|
| `KEYS_ONLY` | a chave do item, e mais nada |
| `NEW_IMAGE` | o item como ficou depois da mudança |
| `OLD_IMAGE` | o item como era antes da mudança |
| `NEW_AND_OLD_IMAGES` | os dois |

**Um consumidor que mantém um total corrente precisa dos dois.** Um `MODIFY` que levou um pedido de
24,89 para 40,79 reais é uma mudança de 15,90, e só a imagem antiga diz quanto era antes. Com
`NEW_IMAGE`, o consumidor teria de lembrar ele mesmo o último total de cada pedido; com `KEYS_ONLY`,
teria de ler o item de volta na tabela, e até lá o item pode ter mudado de novo. Aqui está o `MODIFY` da
seção anterior inteiro:

```
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[31]'
{
    "eventID": "7679416eebb84a44a2743179ed5b4a04",
    "eventName": "MODIFY",
    "eventVersion": "1.0",
    "eventSource": "aws:dynamodb",
    "awsRegion": "us-east-1",
    "dynamodb": {
        "ApproximateCreationDateTime": "2026-10-16T13:28:15.082000-03:00",
        "Keys": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            }
        },
        "NewImage": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            },
            "order_id": {
                "S": "o-10003"
            },
            "order_day": {
                "S": "2026-10-12"
            },
            "total_cents": {
                "N": "4079"
            },
            "line_count": {
                "N": "3"
            }
        },
        "OldImage": {
            "pk": {
                "S": "CUSTOMER#c-17"
            },
            "sk": {
                "S": "ORDER#2026-10-12#o-10003"
            },
            "order_id": {
                "S": "o-10003"
            },
            "order_day": {
                "S": "2026-10-12"
            },
            "total_cents": {
                "N": "2489"
            },
            "line_count": {
                "N": "2"
            }
        },
        "SequenceNumber": "1100000000017454423040",
        "SizeBytes": 641,
        "StreamViewType": "NEW_AND_OLD_IMAGES"
    }
}
```

**Tudo de que o consumidor da próxima seção precisa está nele**: o nome do evento, o id dele, a chave e
as duas imagens, com `total_cents` 2489 antes e 4079 depois. `SizeBytes` é o tamanho do registro, e
`ApproximateCreationDateTime` é mais ou menos quando a mudança foi feita. Um campo está errado de um
jeito que vale notar: `awsRegion` diz `us-east-1` para uma tabela em São Paulo, o que é do moto, não da
AWS. Um programa que encaminhasse registros por esse campo funcionaria contra só um dos dois.

**O tipo de visão não pode ser trocado num stream ligado.** O moto recusa com as palavras dele:

```
ana@laptop:~/aws$ aws dynamodb update-table --table-name quitanda --stream-specification StreamEnabled=true,StreamViewType=KEYS_ONLY

aws: [ERROR]: An error occurred (ResourceInUseException) when calling the UpdateTable operation: Cannot enable stream
```

A AWS recusa também. O caminho para outro tipo de visão é desligar o stream e ligar um novo, que ganha um
rótulo novo e um ARN novo e começa vazio, enquanto o antigo continua legível pelas últimas 24 horas dele.
Essa sequência não foi rodada aqui. Um consumidor tem de ser levado para o stream novo de propósito, e as
mudanças feitas entre os dois só podem ser achadas no stream que estava ligado na hora.
