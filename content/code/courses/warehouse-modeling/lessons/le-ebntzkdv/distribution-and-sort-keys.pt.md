---
title: Chaves de distribuição e de ordenação
version: 1
---

Uma tabela do Redshift declara como as suas linhas se espalham entre as fatias, com `DISTSTYLE`:

| estilo | o que acontece | serve para |
|---|---|---|
| `KEY` | as linhas vão para onde manda o hash da coluna `DISTKEY` | tabelas grandes ligadas por essa coluna |
| `ALL` | uma cópia inteira da tabela em cada nó | dimensões pequenas |
| `EVEN` | as linhas são distribuídas em rodízio | tabelas sem boa chave e sem junções |
| `AUTO` | o Redshift escolhe, e pode mudar de ideia conforme a tabela cresce | o padrão |

e em que ordem as linhas ficam guardadas em cada fatia, com uma `SORTKEY`, que faz os zone maps da lição 8
pularem blocos em filtros por essas colunas.

A estrela da Ana no dialeto do Redshift (**não executado**):

```sql
CREATE TABLE dim_book (
  book_key    BIGINT,
  isbn        VARCHAR(13),
  title       VARCHAR(200),
  department  VARCHAR(50)
  -- and the other columns of dim_book
)
DISTSTYLE ALL;

CREATE TABLE fact_sales (
  date_key       INTEGER,
  shop_key       BIGINT,
  book_key       BIGINT,
  customer_key   BIGINT,
  promotion_key  BIGINT,
  order_id       BIGINT,
  line_no        BIGINT,
  quantity       BIGINT,
  gross_cents    BIGINT,
  discount_cents BIGINT,
  net_cents      BIGINT
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (date_key);
```

Cada escolha nele é uma que a lição 7 ou 8 mediu no laboratório:

- **`DISTKEY (order_id)`**: 572.439 valores distintos que espalharam quatro nós com meio por cento de
  diferença entre eles, e a chave que a `fact_payments` compartilharia, deixando essa junção co-localizada.
- **Não `shop_key`**: sete valores puseram 72% das linhas num nó.
- **`DISTSTYLE ALL` nas dimensões**: copiar 3.000 livros para cada nó moveu 9.000 linhas; reespalhar as
  vendas por livro teria movido 666.023.
- **`SORTKEY (date_key)`**: as consultas filtram primeiro por data, e os dados chegam em ordem de data, então
  os blocos de um mês ficam juntos e o resto é pulado: dois grupos de linhas de oito, na lição 8.

As configurações `AUTO` do Redshift muitas vezes chegam a escolhas parecidas sozinhas. Saber quais são, e por
quê, é o que deixa alguém ver quando o `AUTO` escolheu mal, o que o número de desequilíbrio da lição 7 mostra.
