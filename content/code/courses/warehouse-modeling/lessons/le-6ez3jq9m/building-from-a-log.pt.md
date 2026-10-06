---
title: Construindo o tipo 2 a partir de um registro de mudanças
version: 1
---

A `dim_customer` do warehouse foi construída de uma vez, a partir da tabela atual de clientes e do
registro de toda mudança da rede. Essa é a melhor fonte que o tipo 2 pode ter, porque o registro diz
exatamente quando cada mudança aconteceu:

```sql
-- Slowly changing, type 2 on tier, city and state: a new row every time one
-- of them changed, each row valid from the change until the next one.
-- The name is type 1: every version carries the name as it is spelled now.
CREATE TABLE dim_customer AS
WITH tracked AS (
    SELECT * FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state')
),
-- what each tracked field held when the customer joined: the old value of its
-- first change, or the current value if it never changed
first_values AS (
    SELECT c.customer_id, c.created_at AS valid_from,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'tier' ORDER BY changed_at LIMIT 1), c.tier)  AS tier,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'city' ORDER BY changed_at LIMIT 1), c.city)  AS city,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'state' ORDER BY changed_at LIMIT 1), c.state) AS state
    FROM staging.customers c
),
-- one event per moment something tracked changed
moments AS (
    SELECT customer_id, changed_at AS valid_from,
           max(new_value) FILTER (WHERE field = 'tier')  AS tier,
           max(new_value) FILTER (WHERE field = 'city')  AS city,
           max(new_value) FILTER (WHERE field = 'state') AS state
    FROM tracked GROUP BY customer_id, changed_at
),
timeline AS (
    SELECT * FROM first_values
    UNION ALL
    SELECT * FROM moments
),
-- carry each field forward until the moment that changes it
versions AS (
    SELECT customer_id, valid_from,
           last_value(tier IGNORE NULLS)  OVER w AS tier,
           last_value(city IGNORE NULLS)  OVER w AS city,
           last_value(state IGNORE NULLS) OVER w AS state,
           lead(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_from
    FROM timeline
    WINDOW w AS (PARTITION BY customer_id ORDER BY valid_from
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT row_number() OVER (ORDER BY v.customer_id, v.valid_from) AS customer_key,
       v.customer_id,
       c.name,
       v.tier,
       v.city,
       v.state,
       v.valid_from,
       coalesce(v.next_from, TIMESTAMPTZ '9999-12-31 00:00:00-03') AS valid_to,
       v.next_from IS NULL                                     AS is_current
FROM versions v JOIN staging.customers c USING (customer_id)
UNION ALL
SELECT 0, NULL, 'Walk-in, not identified', 'none', 'Unknown', '--',
       TIMESTAMPTZ '1970-01-01 00:00:00-03', TIMESTAMPTZ '9999-12-31 00:00:00-03', true
ORDER BY customer_key;
```

Leia em quatro passos:

1. **`first_values`**: o que cada campo acompanhado tinha quando o cliente entrou. É o valor antigo da
   primeira mudança do campo, ou, se ele nunca mudou, o valor que tem hoje.
2. **`moments`**: uma linha por momento em que algo acompanhado mudou, com o valor novo de cada campo
   que mudou ali e nada nos outros. Uma mudança de endereço troca a cidade e o estado no mesmo instante,
   então é um momento, não dois.
3. **`versions`**: as duas listas juntas, em ordem de tempo, com cada campo vazio preenchido carregando
   o último valor conhecido (`last_value(... IGNORE NULLS)`), e o fim de cada versão tirado do começo da
   próxima (`lead`).
4. **O `SELECT` final**: uma chave substituta para cada versão, o nome como é escrito hoje (tipo 1), e o
   membro desconhecido como chave 0.

Duas decisões nele merecem um segundo olhar:

- **Só nível, cidade e estado criam uma versão nova.** O e-mail nem está no warehouse: nenhum relatório
  agrupa por ele, e um endereço é dado pessoal sem uso analítico, assunto a que a lição 12 volta. O nome
  é tipo 1.
- **A última versão termina em 31 de dezembro de 9999**, e não num valor vazio. Uma consulta que pergunta
  "que versão valia no instante *t*" pode então usar sempre `t >= valid_from AND t < valid_to`, sem caso
  especial para a linha atual.

Reconstruir a partir do registro inteiro serve para 40.000 clientes e dois anos. Um warehouse com
milhões de clientes, carregado toda noite, não reconstrói; aplica as mudanças de um dia de cada vez ao
que já tem. A próxima seção faz isso.
