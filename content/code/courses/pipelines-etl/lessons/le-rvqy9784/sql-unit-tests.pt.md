---
title: Um teste de unidade para um modelo SQL
version: 1
---

Um modelo dbt também é código, e as regras dele podem ser testadas do mesmo jeito: algumas linhas de
entrada inventadas, e a saída que elas devem dar. O dbt chama isso de **teste de unidade** (*unit
test*), e o escreve em YAML ao lado do modelo. A Ana testa as duas regras do `stg_orders` que mais
importam e que mais fácil se erra: o dia a que um pedido pertence, e o que conta como venda.

```
version: 2

unit_tests:
  - name: order_date_is_the_day_in_sao_paulo
    description: >
      Late on a São Paulo evening is already tomorrow in UTC; the order belongs to
      the shop's day. And only a completed order is a sale.
    model: stg_orders
    given:
      - input: source('raw', 'orders')
        rows:
          - {order_id: 1, shop_id: 1, ordered_at: "2026-03-02 23:30:00-03", status: completed}
          - {order_id: 2, shop_id: 1, ordered_at: "2026-03-03 00:10:00-03", status: completed}
          - {order_id: 3, shop_id: 7, ordered_at: "2026-03-02 12:00:00-03", status: refunded}
    expect:
      rows:
        - {order_id: 1, order_date: 2026-03-02, is_sale: true}
        - {order_id: 2, order_date: 2026-03-03, is_sale: true}
        - {order_id: 3, order_date: 2026-03-02, is_sale: false}
```

O `given` troca a entrada do modelo — aqui a fonte `raw.orders` — por três linhas; colunas não
listadas ficam nulas. O `expect` lista as linhas que o modelo deve devolver, só nas colunas nomeadas.
As três linhas são escolhidas pelas regras: onze e meia da noite em São Paulo, que já é o dia 3 em UTC
e precisa continuar sendo o 2; meia-noite e dez, que é o 3; e um pedido reembolsado, que não é venda.

```
ana@vm:~/etl/shop$ dbt test -s test_type:unit 2>&1 | grep -E "PASS|FAIL|Done"
07:30:29  1 of 1 PASS stg_orders::order_date_is_the_day_in_sao_paulo ..................... [PASS in 0.18s]
07:30:29  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1
```

O dbt monta o SQL do modelo contra essas linhas sem tocar as tabelas de verdade, e compara. Passa, o
que diz que a regra da lição 6 continua valendo. Vale conferir porque a regra é frágil: `ordered_at::date`
em vez de `(ordered_at at time zone 'America/Sao_Paulo')::date` parece quase igual, e só dá o dia
certo enquanto o fuso da conexão por acaso for o de São Paulo; num servidor ou num cliente em UTC, põe
toda venda do fim da noite no dia seguinte. Um teste de unidade é
como um revisor descobre isso sem ler cada caractere.

Testes de unidade rodam com `dbt test`, mas não são testes de dados: não precisam de dados no
warehouse, e pertencem às conferências rodadas antes de uma mudança entrar, e não ao build noturno — a
lição 18 os põe lá.
