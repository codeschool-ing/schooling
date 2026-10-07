---
title: Regras que rodam sozinhas
version: 1
---

Uma consulta rodada uma vez é uma investigação. Para virar governança, as mesmas perguntas têm de ser
feitas **todo dia, por uma máquina, com as respostas guardadas**. As regras vão para uma tabela, e cada
execução delas vai para outra, em que só se insere:

```sql
-- The questions, kept: each rule is a query returning how many rows break it,
-- and every run is written down and never edited.
SET ROLE ipe_owner;
CREATE TABLE gov.quality_rules (
  rule      text PRIMARY KEY,
  dimension text NOT NULL CHECK (dimension IN
              ('validity', 'uniqueness', 'completeness', 'consistency', 'timeliness')),
  check_sql text NOT NULL,              -- returns one number: the rows breaking it
  tolerance integer NOT NULL DEFAULT 0, -- how many may break it and still pass
  why       text NOT NULL
);
CREATE TABLE gov.quality_runs (
  run_at  timestamptz NOT NULL,
  rule    text        NOT NULL REFERENCES gov.quality_rules,
  failing bigint      NOT NULL,
  passed  boolean     NOT NULL,
  PRIMARY KEY (run_at, rule)
);
INSERT INTO gov.column_class
SELECT 'gov', t, c, 'none', 'about rules, not people'
FROM (VALUES ('quality_rules', 'rule'), ('quality_rules', 'dimension'),
             ('quality_rules', 'check_sql'), ('quality_rules', 'tolerance'),
             ('quality_rules', 'why'), ('quality_runs', 'run_at'),
             ('quality_runs', 'rule'), ('quality_runs', 'failing'),
             ('quality_runs', 'passed')) AS v(t, c);

INSERT INTO gov.quality_rules VALUES
 ('customers.email-shape', 'validity',
  $q$SELECT count(*) FROM sales.customers WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$'
     AND email NOT LIKE 'erased-%@invalid'$q$, 0,
  'an address that cannot receive mail is a customer we cannot reach'),
 ('customers.email-unique', 'uniqueness',
  $q$SELECT count(*) FROM (SELECT lower(email) FROM sales.customers
     GROUP BY 1 HAVING count(*) > 1) d$q$, 0,
  'one person, one customer: an export or an erasure must find all of them'),
 ('orders.not-in-future', 'validity',
  $q$SELECT count(*) FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01'$q$, 0,
  'an order cannot have happened after today'),
 ('orders.customer-after-2020', 'completeness',
  $q$SELECT count(*) FROM sales.orders WHERE customer_id IS NULL
     AND ordered_at >= timestamptz '2020-01-01'$q$, 0,
  'guest checkout ended with the old site in 2019; a null since then is a defect'),
 ('customers.consent-after-signup', 'consistency',
  $q$SELECT count(*) FROM sales.customers WHERE consent_at < created_at$q$, 0,
  'a consent before the account existed cannot be proven'),
 ('payments.match-order', 'consistency',
  $q$SELECT count(*) FROM sales.orders o JOIN sales.payments p USING (order_id)
     WHERE p.amount_cents <> o.total_cents$q$, 0,
  'what was paid is what was ordered');

CREATE FUNCTION gov.run_quality(at timestamptz)
RETURNS TABLE (rule text, dimension text, failing bigint, passed boolean)
LANGUAGE plpgsql AS $$
DECLARE r gov.quality_rules;
BEGIN
  FOR r IN SELECT * FROM gov.quality_rules q ORDER BY q.rule LOOP
    EXECUTE r.check_sql INTO failing;
    rule := r.rule; dimension := r.dimension; passed := failing <= r.tolerance;
    INSERT INTO gov.quality_runs VALUES (at, rule, failing, passed);
    RETURN NEXT;
  END LOOP;
END $$;
```

```
ana@lab:~/gov$ psql -f rules.sql
SET
CREATE TABLE
CREATE TABLE
INSERT 0 9
INSERT 0 6
CREATE FUNCTION
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT * FROM gov.run_quality('2026-07-01 06:00-03')"
SET
              rule              |  dimension   | failing | passed 
--------------------------------+--------------+---------+--------
 customers.consent-after-signup | consistency  |    1324 | f
 customers.email-shape          | validity     |      23 | f
 customers.email-unique         | uniqueness   |      12 | f
 orders.customer-after-2020     | completeness |       0 | t
 orders.not-in-future           | validity     |       3 | f
 payments.match-order           | consistency  |       0 | t
(6 rows)
```

Cada regra carrega quatro coisas que vale copiar:

- **a consulta** que conta as linhas que a quebram, então a regra é exatamente tão precisa quanto SQL;
- **uma tolerância**, zero aqui, porque uma regra que tolera "algumas" vai tolerar mais algumas;
- **a dimensão**, para um relatório poder dizer "a validade está piorando" sem ninguém ler SQL;
- **o motivo**, em palavras, porque daqui a dois anos alguém vai querer apagar uma regra que falha, e
  o motivo é o que diz se pode.

A regra dos pedidos sem cadastro merece leitura atenta. Ela não pergunta "o `customer_id` é nulo
alguma vez?" — isso falharia para sempre em catorze linhas corretas, e uma regra que sempre falha é
uma regra que todo mundo aprende a ignorar. Ela pergunta "é nulo **desde 2020**?", o que codifica o
que o dono decidiu na seção anterior, e passa. **Uma regra deve falhar só no que alguém precisa
resolver.**

## O histórico é o ponto

O `gov.quality_runs` guarda cada resultado. A primeira execução diz 23 e-mails malformados. Se a de
1º de agosto disser 25, o site ainda está deixando entrar; se disser 20, o aviso no próximo pedido
está funcionando. Um relatório de qualidade que mostra só os números de hoje não distingue as duas
coisas. E quando um auditor pergunta se a Ipê monitora a qualidade dos seus dados — o princípio da
responsabilização da LGPD, de novo —, a resposta é uma tabela com uma linha por regra por dia.

É assim que a plataforma em que você estuda trata o próprio conteúdo: todo curso passa por um conjunto
de verificações antes de ser publicado, as mesmas verificações a cada mudança, e uma falha o barra. As
regras aqui são a mesma ideia, aplicada a linhas.
