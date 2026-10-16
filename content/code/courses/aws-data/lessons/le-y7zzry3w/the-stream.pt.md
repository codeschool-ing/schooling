---
title: Um stream das mudanças da tabela
version: 1
---

**Um stream do DynamoDB são as mudanças da tabela, item a item e na ordem em que aconteceram, guardadas
por 24 horas.** Não é uma cópia da tabela, e não é uma fila que guarda o que ninguém leu. Cada escrita
que muda um item acrescenta um registro: que tipo de mudança foi, a chave do item e, dependendo do tipo
de visão do stream, o item antes e depois. Algo fora da tabela lê esses registros e age sobre eles:
mantém um total, alimenta um índice de busca, manda ao data warehouse das lições 14 a 19 as linhas
novas. Isso é processamento guiado por mudanças, e a tabela não precisa saber quem está ouvindo.

**Um stream é ligado para uma tabela, e começa vazio.** Mudanças feitas antes dele não estão nele. Esta lição reconstrói a tabela da lição 9. Com o moto rodando no terminal dele e as quatro linhas de "O seu
laboratório, em resumo" da lição 1 digitadas neste, rode o primeiro comando de "A chave de partição e a
chave de ordenação" da lição 9. Depois o stream, antes de qualquer item ser escrito:

```sh
aws dynamodb update-table --table-name quitanda \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES > /dev/null
```

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query 'Table.[StreamSpecification,LatestStreamLabel]'
[
    {
        "StreamEnabled": true,
        "StreamViewType": "NEW_AND_OLD_IMAGES"
    },
    "2026-10-16T16:28:10.507132"
]
ana@laptop:~/aws$ aws dynamodbstreams describe-stream --stream-arn "$ARN" --query "StreamDescription.[StreamStatus,StreamViewType,length(Shards),Shards[0].ShardId]"
[
    "ENABLED",
    "NEW_AND_OLD_IMAGES",
    1,
    "shardId-00000001541626099285-f35f62ef"
]
```

**O stream tem um rótulo, a hora em que foi criado, e um shard.** Um shard é um pedaço do stream, lido
por conta própria. Na AWS os shards acompanham as partições da tabela, e o DynamoDB os abre e fecha
sozinho. Quando um shard é fechado, os registros seguintes dos itens dele continuam num shard filho, que
um leitor não deve começar antes de terminar o pai. O moto mantém um shard só para o stream inteiro e
nunca o fecha, e nada disso foi rodado aqui. Duas variáveis deixam os comandos curtos daqui em diante:

```sh
ARN=$(aws dynamodb describe-table --table-name quitanda --query Table.LatestStreamArn --output text)
SHARD=$(aws dynamodbstreams describe-stream --stream-arn "$ARN" \
  --query 'StreamDescription.Shards[0].ShardId' --output text)
```

## Registros, na ordem das escritas

O `seed.py` da lição 9, salvo em `~/aws`, escreve os trinta itens; o stream registra cada um. Um
**iterador de shard** é uma posição num shard, e `TRIM_HORIZON` pede o registro mais antigo ainda
guardado:

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[:4].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text
INSERT	1100000000017454423009	PROFILE
INSERT	1100000000017454423010	ORDER#2026-10-03#o-10001#LINE#1
INSERT	1100000000017454423011	ORDER#2026-10-03#o-10001#LINE#2
INSERT	1100000000017454423012	ORDER#2026-10-03#o-10001#LINE#3
```

**Todo registro é um `INSERT`, com um número de sequência que só cresce.** Eles vêm na ordem em que os
itens foram escritos, que é a ordem da carga: o perfil de c-17 primeiro, depois as três linhas do
primeiro pedido, depois o próprio pedido. Agora três mudanças em c-17: uma terceira linha no pedido de
12 de outubro, com o total aumentado para acompanhar, e o pedido de 3 de outubro apagado com as suas
três linhas.

```sh
aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-17"},
  "sk": {"S": "ORDER#2026-10-12#o-10003#LINE#3"}, "product": {"S": "eggs-12"},
  "qty": {"N": "1"}, "price_cents": {"N": "1590"}}'
aws dynamodb update-item --table-name quitanda \
  --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "ORDER#2026-10-12#o-10003"}}' \
  --update-expression 'SET total_cents = total_cents + :p, line_count = line_count + :one' \
  --expression-attribute-values '{":p": {"N": "1590"}, ":one": {"N": "1"}}' > /dev/null
for sk in ORDER#2026-10-03#o-10001 ORDER#2026-10-03#o-10001#LINE#{1,2,3}; do
  aws dynamodb delete-item --table-name quitanda \
    --key "{\"pk\": {\"S\": \"CUSTOMER#c-17\"}, \"sk\": {\"S\": \"$sk\"}}"
done
```

```
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[30:].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text
INSERT	1100000000017454423039	ORDER#2026-10-12#o-10003#LINE#3
MODIFY	1100000000017454423040	ORDER#2026-10-12#o-10003
REMOVE	1100000000017454423041	ORDER#2026-10-03#o-10001
REMOVE	1100000000017454423042	ORDER#2026-10-03#o-10001#LINE#1
REMOVE	1100000000017454423043	ORDER#2026-10-03#o-10001#LINE#2
REMOVE	1100000000017454423044	ORDER#2026-10-03#o-10001#LINE#3
```

**Seis escritas, seis registros, cada um do tipo certo.** O put de uma linha nova é um `INSERT`, o update
do total do pedido um `MODIFY`, e os quatro deletes quatro `REMOVE`s. **A ordem é garantida para cada
item e não para a tabela**: duas mudanças em `ORDER#2026-10-12#o-10003` sempre chegam a um leitor na
ordem em que foram feitas, porque os registros de um item estão sempre num shard. Registros de dois itens
em dois shards podem ser lidos em qualquer ordem. Um shard só no moto faz tudo parecer ordenado; um
leitor que confia nisso funciona aqui e não na AWS.

**24 horas, e acabou.** A AWS remove um registro um dia depois de escrito, lido ou não, e um leitor que
fica mais de um dia para trás perde mudanças para sempre. O moto guarda todo registro até parar, que é
outro jeito de perder todos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Dois shards ao longo do tempo. O shard 1 guarda INSERT e depois MODIFY do pedido o-10003, e é fechado; o shard filho continua com o REMOVE de o-10003, então os três registros desse item ficam em ordem, o pai antes do filho. O shard 2 guarda INSERT e MODIFY de o-10007 e INSERT de o-10008, intercalados no tempo com o shard 1, sem ordem entre os dois shards. Todo registro fica guardado por 24 horas.\" data-fig=\"l12-shards\"><defs><marker id=\"l12-shards-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shard 1, fechado</text><line x1=\"140\" y1=\"64\" x2=\"700\" y2=\"64\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o filho dele</text><line x1=\"140\" y1=\"124\" x2=\"700\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shard 2</text><line x1=\"140\" y1=\"184\" x2=\"700\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><rect x=\"150\" y=\"50\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"205\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"205\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><rect x=\"330\" y=\"50\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"385\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MODIFY</text><text x=\"385\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><line x1=\"470\" y1=\"44\" x2=\"470\" y2=\"84\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"/><rect x=\"560\" y=\"110\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"615\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">REMOVE</text><text x=\"615\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><rect x=\"240\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"295\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"295\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10007</text><rect x=\"420\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"475\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MODIFY</text><text x=\"475\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10007</text><rect x=\"580\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"635\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"635\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10008</text><path d=\"M260,64 L328,64\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l12-shards-ah)\"/><path d=\"M440,64 C500,64 500,124 558,124\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l12-shards-ah)\"/><text x=\"330\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um item: sempre nesta ordem</text><text x=\"450\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dois shards: qualquer ordem</text><line x1=\"140\" y1=\"225\" x2=\"700\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l12-shards-ah)\"/><text x=\"140\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"700\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardado por 24 horas, depois some</text></svg>", "caption": "Desenhado para ilustrar: o moto mantém um shard só, que nunca fecha. A ordem vale dentro de um item, cujos registros o seguem de um shard pai para o filho; entre shards, não vale.", "same": ["shard 2"]}
```
