---
title: Dizer exatamente o que é verdade
version: 1
---

Duas correções. A regra do cliente vale só para o site, o que o `where` de um teste expressa: o dbt
embrulha o modelo num filtro antes de conferi-lo. A regra de unicidade é sobre um par de colunas, e
o `column_name` pode ser uma expressão, então o par vira um valor só a conferir:

```
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        data_tests: [unique, not_null]
      - name: customer_id
        data_tests:
          - not_null:
              config:
                where: "shop_id = 7"            # the website: a till may sell to nobody
      - name: status
        data_tests:
          - accepted_values:
              arguments:
                values: [completed, cancelled, refunded]
  - name: stg_order_lines
    data_tests:
      - unique:                                 # the grain is the order AND the line
          arguments:
            column_name: "order_id || '-' || line_no"
    columns:
      - name: order_id
        data_tests:
          - relationships:
              arguments:
                to: ref('stg_orders')
                field: order_id
```

Desta vez a Ana roda `dbt build`, que é o assunto da próxima seção:

```
ana@vm:~/etl/shop$ dbt build 2>&1 | grep -E "PASS|FAIL|WARN|SKIP|ERROR|Done"
08:48:55  5 of 11 FAIL 7 not_null_stg_orders_customer_id ................................. [FAIL 7 in 0.10s]
08:48:55  4 of 11 PASS accepted_values_stg_orders_status__completed__cancelled__refunded . [PASS in 0.11s]
08:48:55  7 of 11 PASS relationships_stg_order_lines_order_id__order_id__ref_stg_orders_ . [PASS in 0.10s]
08:48:55  6 of 11 PASS not_null_stg_orders_order_id ...................................... [PASS in 0.10s]
08:48:55  9 of 11 PASS unique_stg_orders_order_id ........................................ [PASS in 0.04s]
08:48:55  8 of 11 PASS unique_stg_order_lines_order_id_line_no ........................... [PASS in 0.08s]
08:48:55  11 of 11 SKIP relation dbt_marts.fact_sales due to ephemeral model status 'skipped'  [ERROR SKIP]
08:48:55  10 of 11 SKIP relation dbt_marts.daily_sales due to ephemeral model status 'skipped'  [ERROR SKIP]
08:48:56  [ERROR]: in test not_null_stg_orders_customer_id (models/staging/schema.yml)
08:48:56  Done. PASS=8 WARN=0 ERROR=1 SKIP=2 NO-OP=0 REUSED=0 TOTAL=11
```

O `unique_stg_order_lines_order_id_line_no` passa: o grão se sustenta. O teste do cliente continua
falhando, mas agora com **7** linhas em vez de 5.809, e sete é um número que uma pessoa consegue ler:

```
ana@vm:~/etl$ psql -d wh -c "SELECT order_id, ordered_at, updated_at FROM raw.orders WHERE shop_id = 7 AND customer_id IS NULL ORDER BY 1"
 order_id |       ordered_at       |       updated_at       
----------+------------------------+------------------------
   101204 | 2026-01-05 08:47:56-03 | 2026-02-13 10:18:52-03
   103233 | 2026-01-12 08:04:31-03 | 2026-02-16 15:13:36-03
   104638 | 2026-01-17 08:00:04-03 | 2026-02-20 12:18:12-03
   104990 | 2026-01-18 07:17:34-03 | 2026-02-15 15:15:17-03
   108207 | 2026-01-29 17:10:05-03 | 2026-02-13 10:18:52-03
   108348 | 2026-01-30 07:38:44-03 | 2026-02-20 12:18:12-03
   111384 | 2026-02-09 17:22:36-03 | 2026-02-16 15:13:36-03
(7 rows)
```

Sete pedidos do site cujo cliente foi tirado semanas depois da venda — o `updated_at` é o dia em que
isso aconteceu. São os clientes que pediram para ser esquecidos: o apagamento da loja mantém o pedido,
porque a venda aconteceu e a contabilidade precisa dela, e tira quem a fez. O `dim_customer` da lição
7 apaga as linhas deles pelo mesmo motivo.

Então a regra estreitada ainda não é bem a verdade, e as exceções que sobraram também não são
defeito: elas são **conhecidas, explicadas e legais**. Fazer o teste passar acrescentando-as ao
`where` esconderia o próximo pedido que perdesse o cliente por um motivo que ninguém pretendeu. A
próxima seção dá à Ana a outra ferramenta: um teste que pode falhar em voz alta sem parar nada.
