---
title: Metadados, guardados ao lado do dado
version: 1
---

**Metadado é dado sobre dado**: o que uma coluna significa, de que tipo ela é, quem é o dono, quão
sensível é, de onde veio. Todo time guarda isso em algum lugar; a pergunta é se guarda onde continua
verdadeiro. Uma página de wiki descrevendo uma tabela está correta no dia em que é escrita e errada na
primeira vez que uma coluna é acrescentada sem ninguém se lembrar da página.

O PostgreSQL já guarda a maior parte. O catálogo conhece toda coluna e o seu tipo. O `COMMENT ON`
deixa uma descrição morar no banco, ao lado da coluna, versionada com as migrações que a mudam. E o
curso acrescentou duas tabelas suas: a classificação da aula 6 e os donos da seção 3.

```sql
-- What a column means, kept beside the column, where every tool can read it.
SET ROLE ipe_owner;
COMMENT ON TABLE sales.orders IS
  'One order placed on the site or in a shop. Owner: head of sales.';
COMMENT ON COLUMN sales.orders.customer_id IS
  'NULL for guest checkouts, which the old site allowed until December 2019.';
COMMENT ON COLUMN sales.orders.ordered_at IS
  'When the customer confirmed the order, in the shop''s time zone.';
COMMENT ON COLUMN sales.orders.total_cents IS
  'Total in centavos, after discounts, before delivery. Equals the payment.';
```

```sql
-- A data dictionary, generated: the catalogue, the classification, the owner
-- and the comment, for one table.
SELECT a.attname                              AS "column",
       format_type(a.atttypid, a.atttypmod)   AS type,
       cc.class,
       o.owner,
       col_description(a.attrelid, a.attnum)  AS meaning
FROM pg_attribute a
JOIN pg_class c      ON c.oid = a.attrelid
JOIN pg_namespace n  ON n.oid = c.relnamespace
LEFT JOIN gov.column_class cc
       ON (cc.table_schema, cc.table_name, cc.column_name) = (n.nspname, c.relname, a.attname)
LEFT JOIN gov.table_owners o
       ON (o.table_schema, o.table_name) = (n.nspname, c.relname)
WHERE n.nspname = 'sales' AND c.relname = 'orders' AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;
```

```
ana@lab:~/gov$ psql -f describe.sql
SET
COMMENT
COMMENT
COMMENT
COMMENT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f dictionary.sql
SET
   column    |           type           |  class   |     owner     |                                  meaning                                  
-------------+--------------------------+----------+---------------+---------------------------------------------------------------------------
 order_id    | integer                  | personal | head of sales | 
 customer_id | integer                  | personal | head of sales | NULL for guest checkouts, which the old site allowed until December 2019.
 ordered_at  | timestamp with time zone | personal | head of sales | When the customer confirmed the order, in the shop's time zone.
 status      | text                     | personal | head of sales | 
 total_cents | integer                  | personal | head of sales | Total in centavos, after discounts, before delivery. Equals the payment.
 coupon_code | text                     | personal | head of sales | 
(6 rows)
```

Essa saída **é** o dicionário de dados de `sales.orders`, gerado em vez de escrito: o tipo vem do
catálogo, a classe da aula 6, o dono da seção 3, o significado do comentário. O comentário em
`customer_id` registra a decisão sobre as compras sem cadastro, então a próxima analista que contar
nulos acha a explicação no mesmo lugar que a coluna.

Três colunas ainda não têm significado — `order_id`, `status`, `coupon_code`. Isso está visível, e é
o ponto: um dicionário gerado do banco mostra as próprias lacunas, enquanto um escrito à mão
simplesmente as deixa de fora.

## Três tipos, e onde cada um mora

- o metadado **técnico** — tipos, chaves, índices — já está no catálogo, e está sempre certo;
- o metadado **de negócio** — significado, dono, classificação — vai em comentários e em tabelas de
  governança, mudado na mesma migração que aquilo que ele descreve;
- o metadado **operacional** — quando foi carregado, quantas linhas, se as regras de qualidade
  passaram — é escrito pelos próprios jobs, como o `gov.quality_runs`.

Produtos de catálogo de dados — DataHub, OpenMetadata, Collibra e outros — leem os três de muitos
bancos e acrescentam busca e uma tela. Vale tê-los em escala. O que eles mostram é tão bom quanto o que
os bancos guardam, e é por isso que o hábito vem primeiro e o produto depois.
