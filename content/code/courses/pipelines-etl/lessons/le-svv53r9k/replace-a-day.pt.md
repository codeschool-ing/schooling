---
title: Substituir um período inteiro
version: 1
---

Uma tabela fato é carregada um período por vez, e o período é a unidade que ela sabe **substituir**.
A carga de fatos da Ana apaga o dia que vai escrever, depois o insere, dentro de uma transação só:

```
-- marts.fact_sales: one row per order line sold, for one day, replaced whole.
-- Run as: psql -v day=2026-03-07 -f load/fact_sales.sql
CREATE TABLE IF NOT EXISTS marts.fact_sales (
  order_date   date    NOT NULL,
  order_id     integer NOT NULL,
  line_no      integer NOT NULL,
  customer_key bigint  NOT NULL,   -- -1: no customer we can name
  book_id      integer NOT NULL,
  quantity     integer NOT NULL,
  line_cents   bigint  NOT NULL);

BEGIN;
DELETE FROM marts.fact_sales WHERE order_date = :'day';
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
COMMIT;
```

O `:'day'` é uma variável do psql, ajustada na linha de comando com `-v day=2026-03-03`, para que o
mesmo arquivo carregue qualquer dia que receber — o script de batch da lição 1 fez a mesma escolha
pelo mesmo motivo.

Rode a noite de 2 de março uma segunda vez, e a tabela não muda:

```
ana@vm:~/etl$ sh nightly.sh 2026-03-02
2026-03-02: 415 fact rows
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-01 |   272
 2026-03-02 |   415
(2 rows)
```

**415 linhas para 2 de março, como antes.** O delete tirou as linhas da primeira execução e o insert
pôs as mesmas linhas de volta. E como os dois acontecem numa transação, quem lê nunca vê o dia
faltando: até o commit, o PostgreSQL mostra a todos os outros as linhas antigas; depois dele, as
novas.

## O período precisa casar com a fonte da verdade

Substituir um dia funciona porque um dia da loja é uma coisa fechada: tudo o que aconteceu em 2 de
março pode ser lido de novo do `staging`, inteiro. **A regra é que o período que você apaga precisa
ser um período que você consegue reconstruir por completo.** Apague um dia e insira a partir de uma
extração que só tinha as linhas da tarde, e a manhã some.

É isso também que torna fáceis as mudanças tardias. Quando a loja estorna um pedido de 2 de março no
dia 9, nada precisa achar e atualizar a linha fato: rodar de novo a carga de 2 de março refaz o dia a
partir do que a loja diz agora, e o pedido estornado deixa de ser uma venda. A lição 15 transforma
isso num hábito — recarregar os últimos dias toda noite — e a lição 9 deixa um agendador fazer isso.
