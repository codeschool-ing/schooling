---
title: Escritas condicionais, e a sobrescrita que ninguém viu
version: 1
---

**Um `put-item` substitui qualquer item que já tinha a mesma chave, por inteiro e sem dizer nada.** Não
existe um "insert" que falha quando a linha existe, como no SQL com chave primária. A primeira seção
desta lição escreveu à mão o perfil de c-17, com o nome Ana e o bairro Lapa; depois o `seed.py` escreveu
a mesma chave:

```
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}}' --query 'Item.[name.S,district.S,customer_id.S]' --output text
Gabi	Lapa	c-17
```

**A Ana sumiu, e nada avisou.** O `batch_writer` da carga mandou um put para `CUSTOMER#c-17`/`PROFILE`,
e o put substituiu o item inteiro. O nome é Gabi, o bairro é Lapa só porque o gerador o sorteou também,
e `customer_id` é um atributo que o item escrito à mão nunca teve. Se o item antigo tivesse um atributo
que o novo não mencionasse, ele teria sumido também. Numa aplicação é a clássica atualização perdida:
duas telas abertas no mesmo perfil, as duas salvam, e a segunda ganha em silêncio.

## attribute_not_exists, o insert que recusa

**Uma expressão de condição é verificada contra o item que tem a mesma chave, e a escrita só acontece se
ela for verdadeira.** `attribute_not_exists(pk)` só é verdadeira quando não existe item nenhum com
aquela chave, já que todo item que existe tem `pk`. Isso transforma um put num insert que se recusa a
sobrescrever:

```
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item file://profile.json --condition-expression 'attribute_not_exists(pk)' --return-values-on-condition-check-failure ALL_OLD

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the PutItem operation: The conditional request failed

Additional error details:
Item: <complex value>
Use "--cli-error-format json" or another error format to see the full details.
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-99"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}}' --condition-expression 'attribute_not_exists(pk)'
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-99"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}}' --condition-expression 'attribute_not_exists(pk)'

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the PutItem operation: The conditional request failed
```

**O primeiro put foi recusado, o segundo criou c-99 e o terceiro foi recusado de novo.**
`ConditionalCheckFailedException` é a resposta a uma condição falsa, e o item fica exatamente como
estava. A opção `--return-values-on-condition-check-failure ALL_OLD` pede que o item que barrou a
escrita volte junto com o erro, para que um programa mostre o que já está lá em vez de perguntar de novo. A linha de comando o imprime como `<complex value>`, a menos que se peça para formatar os erros
como JSON. **Uma escrita condicional que falhou ainda é uma escrita na conta**: a AWS cobra as unidades
de escrita da tentativa, com a condição verdadeira ou não.

**O `BatchWriteItem` não aceita condições**, e é por isso que não dava para mandar a carga deixar a Ana
em paz. Um lote é até 25 puts e deletes simples. Onde alguns deles não podem sobrescrever, eles vão um a
um, ou numa transação, `TransactWriteItems`, que aplica até cem escritas com condições, todas ou
nenhuma, e cujo preço a lição 11 calcula.

## Uma condição sobre o estado, não só sobre a existência

O mesmo mecanismo protege uma mudança de estado. O pedido `o-10009` foi feito em 14 de outubro e leva
`pending_since`; entregá-lo remove esse atributo e registra quando. Duas vezes:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T18:20"}}' --return-values ALL_NEW --query 'Attributes.[order_id.S,pending_since.S,delivered_at.S]' --output text
o-10009	None	2026-10-14T18:20
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T18:45"}}' --return-values ALL_NEW

aws: [ERROR]: An error occurred (ConditionalCheckFailedException) when calling the UpdateItem operation: The conditional request failed
```

**O primeiro update entregou o pedido, e o segundo foi recusado, porque ele já estava entregue.** O app
de um entregador que manda o mesmo "entregue" duas vezes, depois de uma nova tentativa numa conexão
ruim, não muda nada na segunda, e a hora da entrega é a primeira. A mesma forma com um número é o bloqueio otimista:
`version = :seen` na condição e `version = version + 1` no update. Uma escrita então só dá certo se
ninguém mudou o item desde que ele foi lido, e é esse o conserto para as duas telas lá de cima.
