---
title: Índices secundários locais
version: 1
---

**Um índice secundário local mantém a chave de partição da tabela e ordena a mesma coleção de itens por
outro atributo.** Onde um índice global reorganiza a tabela inteira, um local é uma segunda ordem para
cada coleção: os itens de c-17, ordenados por `total_cents` em vez de por `sk`. "Os maiores pedidos de um
cliente" vira então uma query no índice, lida de trás para frente.

**Ele só pode ser criado junto com a tabela.** O `update-table` não tem parâmetro para isso, nem na AWS
nem na linha de comando, então um índice local que não estava no primeiro projeto é uma tabela nova e uma
recarga. Aqui isso é barato, então a tabela é apagada e feita de novo com um:

```sh
aws dynamodb delete-table --table-name quitanda > /dev/null
aws dynamodb create-table --table-name quitanda \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
                          AttributeName=total_cents,AttributeType=N \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --local-secondary-indexes '[{"IndexName": "by-total",
      "KeySchema": [{"AttributeName": "pk", "KeyType": "HASH"},
                    {"AttributeName": "total_cents", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "ALL"}}]' \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

Na AWS, `delete-table` apaga todo item e os dois índices, e nada pergunta duas vezes. Esse é o preço de um
índice que faltou no primeiro projeto, e o motivo de a lição 9 escrever os padrões primeiro.

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --no-scan-index-forward --query 'Items[].[total_cents.N,sk.S]' --output text
23490	ORDER#2026-10-05#o-10002
5760	ORDER#2026-10-03#o-10001
2489	ORDER#2026-10-12#o-10003
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}}' --no-scan-index-forward --limit 1 --consistent-read --query 'Items[0].[order_id.S,total_cents.N]' --output text
o-10002	23490
```

**Os três pedidos de c-17, do maior para o menor, e o perfil e as linhas não estão lá**, porque não têm
`total_cents`: um índice local é esparso do mesmo jeito que um global. A segunda query pediu
`--consistent-read` e conseguiu. Essa é a única coisa que só um índice local oferece, porque ele mora na
mesma partição que os itens que ordena e é escrito na mesma operação. Ele também divide a capacidade da
tabela em vez de ter a sua, e uma query nele pode pedir atributos que não foram projetados, que o DynamoDB
então busca na tabela pelo custo de mais uma leitura.

## O limite que vem com ele

**Uma tabela com índice local limita cada coleção de itens a 10 GB.** Os itens de uma chave de partição,
mais as cópias deles em todo índice local, não podem passar disso, e uma escrita que passaria falha com
`ItemCollectionSizeLimitExceededException`. Os pedidos de um cliente não vão chegar a 10 GB; uma coleção
com chave em algo que cresce para sempre, as leituras de um aparelho ou os eventos de uma loja, pode
chegar. O moto não impõe esse limite, e isso não foi rodado aqui.

**Então um índice local é a exceção, escolhida por um motivo.** Consistência forte numa ordem alternativa
é esse motivo. No resto, um índice global faz o mesmo trabalho para a mesma coleção, com a chave de
partição da tabela como a sua, sem limite de tamanho, com capacidade própria e podendo ser criado no dia
em que a pergunta chega. A AWS permite até cinco índices locais por tabela e, por padrão, vinte globais.
