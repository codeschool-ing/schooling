---
title: Um índice esparso
version: 1
---

**Um índice guarda só os itens que têm a chave dele, e isso é um recurso, não uma falha.** Um índice
relacional tem uma entrada para cada linha, NULLs inclusive. Um índice secundário global num atributo que
a maioria dos itens não tem é pequeno, barato, e responde "quais itens estão neste estado" sem ler os que
não estão. Os pedidos de 14 de outubro na tabela da Quitanda têm `pending_since` até serem entregues, e
nada mais tem. Então um índice com chave nele guarda os pedidos abertos e mais nada:

```sh
aws dynamodb update-table --table-name quitanda \
  --attribute-definitions AttributeName=pending_since,AttributeType=S AttributeName=order_id,AttributeType=S \
  --global-secondary-index-updates '[{"Create": {"IndexName": "pending",
      "KeySchema": [{"AttributeName": "pending_since", "KeyType": "HASH"},
                    {"AttributeName": "order_id", "KeyType": "RANGE"}],
      "Projection": {"ProjectionType": "KEYS_ONLY"}}}]' > /dev/null
```

Um índice é criado num `update-table` próprio, um por chamada, regra da AWS e do moto. `KEYS_ONLY`
porque a tela de expedição precisa das chaves para buscar um pedido e de mais nada.

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query '[Count,ScannedCount]' --output text
722	722
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'attribute_exists(pending_since)' --select COUNT --query '[Count,ScannedCount]' --output text
255	11439
241	11445
226	11216
```

**Um scan do índice leu 722 itens e achou 722**: todo item nele é um pedido aberto, então não há nada a
filtrar. A mesma pergunta feita à tabela, um scan com `attribute_exists(pending_since)`, achou os mesmos
722 em três páginas e leu os 34.100 itens para isso. Fazer scan de um índice esparso é um dos poucos
scans que são trabalho honesto.

**E um pedido sai do índice sozinho quando é entregue.** Remover o atributo é a entrega da última seção
da lição 9; o DynamoDB remove a entrada do índice na mesma escrita:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-19"}, "sk": {"S": "ORDER#2026-10-14#o-10009"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{":t": {"S": "2026-10-14T19:05"}}'
{
    "ConsumedCapacity": {
        "TableName": "quitanda",
        "CapacityUnits": 0.5
    }
}
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query Count
721
```

**721.** Nada apagou nada do índice; o item deixou de se qualificar. A técnica é toda essa: um atributo
que só existe enquanto um item está num estado, e um índice nele. O custo acompanha o estado e não a
tabela: um pedido paga escritas no índice duas vezes, uma quando fica pendente e outra quando deixa de
ficar, e o índice guarda só o que está aberto agora.

**O moto também respondeu ao update com um `ConsumedCapacity` que ninguém pediu.** A AWS só devolve esse
bloco quando a requisição pede com `--return-consumed-capacity`, e a lição 11 mostra que o número nele,
aqui 0,5 para uma escrita, não é o que a AWS cobraria.
