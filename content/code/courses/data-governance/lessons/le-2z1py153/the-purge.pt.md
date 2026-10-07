---
title: O expurgo
version: 1
---

O expurgo transforma o cronograma em eliminações. O da Ipê é uma função que lê só `gov.retention` e
`gov.legal_holds`, então mudar um prazo ou acrescentar um bloqueio nunca significa editá-la:

```sql
-- The purge: what gov.retention says has expired goes, except what a legal
-- hold keeps. Before orders go, what they say about sales is kept as monthly
-- totals that name nobody. Every run is logged.
SET ROLE ipe_owner;
CREATE TABLE gov.sales_monthly (
  month       date    NOT NULL,
  category    text    NOT NULL,
  orders      integer NOT NULL,
  units       integer NOT NULL,
  revenue_cts bigint  NOT NULL,
  PRIMARY KEY (month, category)
);
CREATE TABLE gov.purge_log (
  run_on  date        NOT NULL,
  rel     text        NOT NULL,
  deleted bigint      NOT NULL,
  PRIMARY KEY (run_on, rel)
);
INSERT INTO gov.column_class
SELECT 'gov', t, c, 'none', w
FROM (VALUES ('sales_monthly','month','totals that name nobody'),
             ('sales_monthly','category','totals that name nobody'),
             ('sales_monthly','orders','totals that name nobody'),
             ('sales_monthly','units','totals that name nobody'),
             ('sales_monthly','revenue_cts','totals that name nobody'),
             ('purge_log','run_on','a count of rows, not people'),
             ('purge_log','rel','a count of rows, not people'),
             ('purge_log','deleted','a count of rows, not people')) AS v(t, c, w);

CREATE FUNCTION gov.purge(today date) RETURNS TABLE (rel text, deleted bigint)
LANGUAGE plpgsql AS $$
DECLARE
  held    integer[] := ARRAY(SELECT customer_id FROM gov.legal_holds
                             WHERE released_on IS NULL);
  expired integer[];
  n       bigint;
BEGIN
  expired := ARRAY(
    SELECT o.order_id FROM sales.orders o
    WHERE date_trunc('year', o.ordered_at) + interval '1 year'
          + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= today
      AND (o.customer_id IS NULL OR o.customer_id <> ALL (held)));

  -- What the business still needs from them, anonymised (LGPD art. 16, IV).
  INSERT INTO gov.sales_monthly
  SELECT date_trunc('month', o.ordered_at)::date, p.category, count(DISTINCT o.order_id),
         sum(i.quantity), sum(i.quantity * i.unit_price_cents)
  FROM sales.orders o
  JOIN sales.order_items i USING (order_id)
  JOIN sales.products p USING (product_id)
  WHERE o.order_id = ANY (expired)
  GROUP BY 1, 2
  ON CONFLICT (month, category) DO UPDATE
    SET orders = gov.sales_monthly.orders + EXCLUDED.orders,
        units = gov.sales_monthly.units + EXCLUDED.units,
        revenue_cts = gov.sales_monthly.revenue_cts + EXCLUDED.revenue_cts;

  DELETE FROM health.prescriptions r
  WHERE (r.issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
         <= today OR r.order_id = ANY (expired))
    AND r.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'health.prescriptions'; deleted := n; RETURN NEXT;

  DELETE FROM support.tickets t
  WHERE t.status = 'closed'
    AND t.opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets') <= today
    AND t.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'support.tickets'; deleted := n; RETURN NEXT;

  DELETE FROM sales.order_items WHERE order_id = ANY (expired);
  DELETE FROM sales.payments    WHERE order_id = ANY (expired);
  DELETE FROM sales.deliveries  WHERE order_id = ANY (expired);
  DELETE FROM sales.returns     WHERE order_id = ANY (expired);
  DELETE FROM sales.orders      WHERE order_id = ANY (expired);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'sales.orders'; deleted := n; RETURN NEXT;
END $$;
```

A ordem do trabalho dentro dela importa:

1. **achar o que expirou**, pulando o que um bloqueio cobre — pedidos sem cadastro de 2019 não têm
   cliente e, portanto, nenhum bloqueio, e é por isso que `customer_id IS NULL` é testado à parte;
2. **guardar o que o negócio ainda precisa, anonimizado**: totais mensais por categoria de produto,
   escritos antes de qualquer pedido sair (seção 6);
3. **apagar primeiro os dependentes** — receitas, depois os itens, o pagamento, a entrega e a devolução
   do pedido — e os pedidos por último, para nenhuma chave estrangeira ficar apontando para o nada.

Uma versão anterior usava tabelas temporárias, e o laboratório a recusou: a aula 1 tirou de todo mundo
o privilégio `TEMPORARY`, e a função roda como `ipe_owner`. Arrays guardados em variáveis fazem o mesmo
trabalho sem o privilégio.

## Rodando

```sql
-- One run, logged.
SET ROLE ipe_owner;
INSERT INTO gov.purge_log
SELECT DATE '2026-07-01', rel, deleted FROM gov.purge(DATE '2026-07-01')
RETURNING rel, deleted;
```

```
ana@lab:~/gov$ psql -f hold.sql
SET
CREATE TABLE
INSERT 0 4
INSERT 0 1
ana@lab:~/gov$ psql -f purge.sql
SET
CREATE TABLE
CREATE TABLE
INSERT 0 8
CREATE FUNCTION
ana@lab:~/gov$ psql -f run-purge.sql
SET
         rel          | deleted 
----------------------+---------
 health.prescriptions |    9826
 support.tickets      |     366
 sales.orders         |     950
(3 rows)

INSERT 0 3
ana@lab:~/gov$ psql -f overdue.sql
SET
        table         | past_retention 
----------------------+----------------
 sales.orders         |             13
 health.prescriptions |             21
 support.tickets      |              1
(3 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders_kept_by_the_hold FROM sales.orders WHERE customer_id = 4407 AND ordered_at < DATE '2021-01-01'" -c "SELECT * FROM gov.sales_monthly WHERE month = DATE '2020-03-01' ORDER BY category"
SET
 orders_kept_by_the_hold 
-------------------------
                      13
(1 row)
```

**9.826 receitas, 366 chamados e 950 pedidos** apagados, e as contagens escritas em `gov.purge_log`.
A consulta de vencidos, rodada de novo, ainda acha 13, 21 e 1: são o pedido, as receitas e o chamado
do cliente 4407, mantidos pelo bloqueio, e a consulta seguinte confirma que os 13 pedidos continuam lá.
A consulta de vencidos não sabe dos bloqueios; o expurgo sabe. Essa diferença é a certa — a primeira
é um relatório do que o cronograma diz, o segundo é o que pode acontecer.

## Rodando todo dia

Um expurgo que alguém se lembra de rodar uma vez por ano é um expurgo atrasado um ano na maior parte
do tempo. A função é escrita para **rodar num agendamento**, como um job noturno com a data passada
como parâmetro. Ela também é **segura de rodar duas vezes**: na mesma data não sobra nada a achar,
então uma segunda execução não apaga nada e não acrescenta nada aos totais, por construção. A chave
do log vai um passo além e recusa uma segunda entrada para a mesma data, então um job repetido por
engano falha de forma visível em vez de escrever uma segunda linha. O log então mostra, toda noite,
quanto o cronograma removeu; uma noite com zero linhas está bem, e um mês de noites sem log nenhum é
o alarme.