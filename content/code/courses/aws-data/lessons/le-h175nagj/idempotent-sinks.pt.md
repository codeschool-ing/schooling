---
title: Destinos que não ligam para quantas vezes são escritos
version: 1
---

**A tabela de deduplicação da seção anterior é uma resposta; um destino idempotente por natureza é a
mais barata.** Uma tabela de deduplicação lembra cada evento para que uma escrita possa ser recusada.
Um destino idempotente não precisa de memória, porque escrever a mesma coisa duas vezes já cai no
mesmo lugar com o mesmo resultado. O teste de um destino é uma pergunta só: se esta escrita se
repetir, o resultado muda? `ADD` num total responde que sim. Outros dois respondem que não, e são os
dois que este curso mais usa.

## Uma chave que nomeia o conteúdo, não o momento

Um consumidor que escreve lotes no S3 precisa de uma chave para cada objeto. A chave tentadora é a
hora da escrita; a idempotente é um nome derivado do que o lote contém, como o shard e o primeiro e o
último número de sequência dele. Um lote pequeno, escrito duas vezes sob cada tipo de chave:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ printf '%s\n' '{"order_id": "o-301", "cents": 4590}' '{"order_id": "o-302", "cents": 12800}' > batch.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-time/1792168816735151990.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-time/1792168817394032117.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/ --recursive
2026-10-16 13:40:19         75 raw/payments-by-seq/shardId-000000000000/1-2.json
2026-10-16 13:40:17         75 raw/payments-by-time/1792168816735151990.json
2026-10-16 13:40:18         75 raw/payments-by-time/1792168817394032117.json
```

**O lote nomeado pela hora agora está no lago duas vezes; o nomeado pela sequência está lá uma.** O
segundo `cp` em `1-2.json` sobrescreveu um objeto idêntico com bytes idênticos, o que não muda nada,
então um consumidor que caiu depois de escrever o objeto e antes do checkpoint pode escrevê-lo de novo
no reprocessamento sem dano. Com as chaves pela hora, o mesmo reprocessamento deixa dois objetos com os
mesmos dois pagamentos, e toda consulta ao lago conta os dois. O aviso da lição 1 de que sobrescrever é
silencioso e definitivo é, aqui, exatamente a propriedade desejada.

Isso funciona porque um reprocessamento lê os **mesmos** registros nos mesmos lotes. Um consumidor
cujos limites de lote podem mudar entre execuções, porque junta por tempo e não por posição, perde
isso, e volta a precisar de um passo de deduplicação; juntar por número de sequência o mantém. E o
Firehose, que nomeia os objetos pela hora e por um sufixo aleatório, não pode ficar idempotente desse jeito. Um duplicado que ele escreve fica no lago até um job posterior removê-lo, e é por isso que
tabelas do lago construídas a partir de entregas do Firehose são deduplicadas pela chave de
idempotência quando são compactadas na camada curada.

## Um upsert, não um incremento

A outra forma é uma escrita que define um valor em vez de mudá-lo:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-08"}}' --update-expression 'ADD cents :c' --expression-attribute-values '{":c": {"N": "500"}}' --return-values UPDATED_NEW --query Attributes.cents.N --output text
500
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-08"}}' --update-expression 'ADD cents :c' --expression-attribute-values '{":c": {"N": "500"}}' --return-values UPDATED_NEW --query Attributes.cents.N --output text
1000
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda-totals --item '{"customer_id": {"S": "c-09"}, "cents": {"N": "500"}}'
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda-totals --item '{"customer_id": {"S": "c-09"}, "cents": {"N": "500"}}'
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-09"}}' --query Item.cents.N --output text
500
```

**`ADD` duas vezes fez 1.000 a partir de 500; `put-item` duas vezes deixou 500.** Um `put-item` troca o
item inteiro pelo dado, então repeti-lo é inofensivo, e o mesmo vale para o
`INSERT ... ON CONFLICT DO UPDATE` do SQL e para o `MERGE`, que `sql-databases` cobre. O porém é que
um upsert precisa levar o **estado inteiro**, o próprio total e não o valor a somar a ele, e o
consumidor precisa conhecer esse estado. Isso serve a um stream de fotografias, como "o saldo do
cliente `c-09` agora é 500", e não serve a um stream de mudanças, como "some 500", que é o que
pagamentos são. Um stream de mudanças num destino não idempotente é o caso que precisa da
deduplicação da seção anterior.

**Desenhe os eventos para facilitar o destino.** Se um produtor pode mandar o estado novo em vez da
diferença, todo consumidor depois dele pode fazer upsert e esquecer os duplicados. Quando o evento
precisa ser uma diferença, ele leva um id, e o destino ou registra o id junto com o efeito, como o
`totals.py` faz, ou é reconstruído mais tarde a partir do histórico deduplicado.
