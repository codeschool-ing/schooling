---
title: Um esquema que diz o que o código confere
version: 1
---

A regra da aula 4 era que um esquema deve levar o que o código confere, para o modelo saber da regra antes de quebrá-la. O `OrderId` põe a regra no tipo: `Annotated[str, Field(pattern=..., description=...)]`. O SDK o transforma em JSON Schema:

```
ana@lab:~/agents$ python try_server.py schema 2> server.log
get_order
  input:  {"order_id": {"description": "M- and four digits, such as M-1043", "pattern": "^M-[0-9]{4}$", "title": "Order Id", "type": "string"}}
  output: ["delivered_on", "id", "lines", "placed_on", "refunded", "status", "total", "tracking"]
  hints:  {'read_only_hint': True}
search_help
  input:  {"query": {"title": "Query", "type": "string"}}
  output: ["result"]
  hints:  {'read_only_hint': True}
```

O esquema de entrada do `get_order` agora leva o padrão `^M-[0-9]{4}$` e a descrição *"M- and four digits, such as M-1043"*, o que o `shop_mcp.py` da aula 11 não tinha. Um hospedeiro passa os dois ao modelo, então o modelo vê o formato antes da primeira chamada. E o servidor confere: a mesma anotação que gerou o esquema é contra o que o SDK valida os argumentos, então o esquema e a verificação não se separam. A terceira chamada da próxima seção mostra a verificação funcionando.

A linha de **dicas** mostra `readOnlyHint` nas duas ferramentas. Uma dica é o servidor descrevendo a si mesmo, e a especificação é explícita: um cliente não deve confiar em dicas de um servidor em que não confia; um hospedeiro pode usá-las para decidir que chamadas precisam de uma pessoa, como a aula 7 de `ai-dev` fez, mas a decisão continua sendo do hospedeiro.

O esquema de saída do `search_help` é uma propriedade só, `result`. Uma função que devolve uma lista não pode ser um objeto JSON no nível de cima, então o SDK a embrulha, como o ADK fez na aula 10. Um cliente que lê o `structuredContent` acha a lista sob `result`.
