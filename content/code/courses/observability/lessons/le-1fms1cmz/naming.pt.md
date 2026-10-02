---
title: O nome de um span é uma categoria, não um registro
version: 1
---

O span da vitrine se chama `POST /checkout`, não `POST /checkout for kettle`. Parece um detalhe, e é
o erro de instrumentação mais comum que existe. O `names.py` faz cinquenta spans para cinquenta
pedidos, uma vez dando a cada um o id do pedido no nome e outra com o modelo da rota no nome e o id
num atributo:

```python
    if style == "bad":
        name = f"GET /orders/{order_id}"
        attributes = {}
    else:
        name = "GET /orders/{id}"
        attributes = {"shop.order_id": order_id}
    with tracer.start_as_current_span(name, attributes=attributes):
        pass
```

O Jaeger mantém uma lista das **operações** de cada serviço, os nomes de span distintos que ele já
viu, e a oferece como a primeira coisa pela qual filtrar:

```
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq '.operations | length'
50
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-bad' | jq -r '.operations[:3][].name'
GET /orders/1011
GET /orders/1047
GET /orders/1026
ana@obs:~/shop$ curl -s 'localhost:16686/api/v3/operations?service=names-good' | jq -r '.operations[].name'
GET /orders/{id}
```

**Cinquenta operações contra uma**, para as mesmas cinquenta requisições. A lista do primeiro
serviço cresce um item a cada pedido que a loja receber. Os três primeiros são `1011`, `1047` e
`1026`, numa ordem que ninguém escolheu. Um filtro por operação virou uma busca por um pedido. Uma
latência agregada por operação são cinquenta médias de uma requisição cada. Backends que calculam
métricas a partir de spans, o que a aula 12 faz com o Collector, criam uma série por operação. O
nome virou o label que estoura a fatura na aula 6.

A regra decorre daquilo para que um nome serve: **o nome de um span diz que tipo de trabalho é
este**, e os atributos dizem qual instância dele. `GET /orders/{id}` com `shop.order_id = 1011`
mantém os dois: a operação é uma linha em toda lista, e o pedido 1011 continua a uma busca de
distância. As convenções semânticas escrevem isso para HTTP, onde o nome é o método e o modelo da
rota. Fazem o mesmo para bancos de dados, onde é a operação e a tabela, nunca a consulta inteira com seus
valores.
