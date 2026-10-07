---
title: Um consentimento que se prova
version: 1
---

O consentimento é definido no **artigo 5º, XII** como a manifestação *livre, informada e inequívoca*
pela qual a pessoa concorda com o tratamento para uma *finalidade determinada*. O **artigo 8º**
acrescenta quatro regras que um modelo de dados precisa conseguir cumprir:

- **deve ser dado por escrito ou por outro meio que demonstre a vontade da pessoa** — uma caixa
  marcada com o texto dela, e não uma caixa que veio marcada;
- **cabe ao controlador o ônus da prova de que foi obtido conforme a lei** (§2º) — quando, como, para
  quê;
- **autorizações genéricas são nulas** (§4º) — "você concorda com tudo" é consentimento para nada;
- **pode ser revogado a qualquer momento, de graça, por procedimento facilitado** (§5º).

## O que a Ipê tinha

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, marketing_opt_in, consent_at FROM sales.customers WHERE customer_id IN (1, 2, 3) ORDER BY 1"
SET
 customer_id | marketing_opt_in |       consent_at       
-------------+------------------+------------------------
           1 | t                | 2025-01-07 20:54:32-03
           2 | f                | 
           3 | t                | 2022-04-10 11:06:37-03
(3 rows)
```

Um booleano e uma data. Diz que a cliente 1 consentiu em 7 de janeiro de 2025, e nada mais: nem com
que texto, nem por qual formulário, nem para qual finalidade — "marketing" cobre igualmente e-mail,
SMS e ofertas de parceiros. Quando a cliente 1 revoga, a implementação óbvia põe o booleano em
`false`, e então **a prova de que ela consentiu um dia, e a data em que revogou, somem as duas**. O
artigo 8º, §2º põe o ônus da prova na Ipê; esta coluna torna a prova impossível.

## O consentimento como eventos

```sql
-- Every consent and every withdrawal, as events that are never edited.
-- The current state is computed from them; nothing overwrites a choice.
SET ROLE ipe_owner;
CREATE TABLE sales.consent_events (
  event_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  integer     NOT NULL REFERENCES sales.customers,
  purpose      text        NOT NULL,   -- what the consent is for
  given        boolean     NOT NULL,   -- true: given, false: withdrawn
  text_version text        NOT NULL,   -- the wording the person saw
  channel      text        NOT NULL,   -- where it happened
  at           timestamptz NOT NULL
);
-- What the old boolean knew, carried over as the first event of each
-- customer who opted in. The wording of 2019 to 2026 is version 1.
INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at)
SELECT customer_id, 'marketing-email', true, 'mkt-v1', 'sign-up form', consent_at
FROM sales.customers WHERE marketing_opt_in;

-- Lesson 6's rule: a new table is classified in the same change.
INSERT INTO gov.column_class VALUES
 ('sales','consent_events','event_id','personal','one choice somebody made'),
 ('sales','consent_events','customer_id','personal','whose choice'),
 ('sales','consent_events','purpose','personal','what they agreed to or refused'),
 ('sales','consent_events','given','personal','the choice'),
 ('sales','consent_events','text_version','none','which wording; the wording is not about anybody'),
 ('sales','consent_events','channel','personal','where they made it'),
 ('sales','consent_events','at','personal','when');

CREATE VIEW sales.consent_now AS
SELECT DISTINCT ON (customer_id, purpose)
       customer_id, purpose, given, text_version, at
FROM sales.consent_events
ORDER BY customer_id, purpose, at DESC, event_id DESC;
```

```
ana@lab:~/gov$ psql -f consents.sql
SET
CREATE TABLE
INSERT 0 2536
INSERT 0 7
CREATE VIEW
```

Cada consentimento e cada revogação é uma linha que nunca é editada: quem, para qual finalidade, dado
ou revogado, **com que texto** (`text_version`), por qual canal e quando. Os 2.536 clientes que
tinham marcado a opção viram 2.536 primeiros eventos, com a versão honesta do texto para os anos em
que o formulário antigo foi usado. A tabela nova é classificada no mesmo arquivo, porque senão a
verificação da aula 6 falharia. O estado atual é uma view, calculada a partir dos eventos.

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at) VALUES (1, 'marketing-email', false, 'mkt-v1', 'unsubscribe link', '2026-06-20 09:12:00-03')"
SET
INSERT 0 1
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT * FROM sales.consent_now WHERE customer_id = 1"
SET
 customer_id |     purpose     | given | text_version |           at           
-------------+-----------------+-------+--------------+------------------------
           1 | marketing-email | f     | mkt-v1       | 2026-06-20 09:12:00-03
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT given, channel, at FROM sales.consent_events WHERE customer_id = 1 ORDER BY at"
SET
 given |     channel      |           at           
-------+------------------+------------------------
 t     | sign-up form     | 2025-01-07 20:54:32-03
 f     | unsubscribe link | 2026-06-20 09:12:00-03
(2 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT given, count(*) FROM sales.consent_now WHERE purpose = 'marketing-email' GROUP BY given"
SET
 given | count 
-------+-------
 f     |     1
 t     |  2535
(2 rows)
```

A cliente 1 cancelou a inscrição em 20 de junho. O estado atual dela diz `given = f`; o histórico diz
quando ela consentiu, por qual formulário, e quando e como revogou. Ficam 2.535 consentimentos. Cada
um deles pode ser mostrado a um fiscal com o texto que a pessoa viu — que é o que o artigo 8º pede, e
o que um booleano nunca conseguiria.

**A revogação encerra o tratamento futuro; não desfaz o passado.** Os e-mails enviados antes de 20 de
junho foram enviados licitamente. O que a revogação exige é que o sistema de marketing leia
`consent_now`, e não o booleano antigo, antes da próxima campanha — e um teste que falhe se não ler.
