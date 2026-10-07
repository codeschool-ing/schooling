---
title: Classificando cada coluna
version: 1
---

Um inventário em que as pessoas confiam é um que não consegue ficar desatualizado sem alguém
perceber. O jeito de chegar lá é guardar a classificação **no banco, ao lado das colunas que ela
descreve**, e fazer uma consulta que liste tudo o que ficou de fora.

A Ipê usa quatro classes. Menos juntaria coisas tratadas de jeitos diferentes; mais transformaria
toda coluna nova numa discussão:

| classe | quer dizer | exemplo |
|---|---|---|
| `none` | nada sobre uma pessoa | o preço de um produto |
| `personal` | sobre uma pessoa; a identifica só com outros dados | a cidade de um cliente |
| `identifying` | destaca uma pessoa sozinha | um endereço de e-mail |
| `sensitive` | artigo 5º, II, ou o revela | uma receita; a linha de pedido de uma farmácia |

O schema `gov` é criado pelo superusuário para o dono — `ipe_owner` não tem direito de criar schemas
no banco, como a aula 1 arranjou — e a classificação vai numa tabela ali. O começo do arquivo, com
toda coluna de `sales.customers`:

```sql
-- Every column of Ipê's tables, and what it holds. Four classes, no more:
--   none         nothing about a person
--   personal     about a person, identifies them only with other data
--   identifying  picks a person out on its own
--   sensitive    article 5, II of the LGPD, or reveals it
SET ROLE ipe_owner;
CREATE TABLE gov.column_class (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  column_name  name NOT NULL,
  class        text NOT NULL
               CHECK (class IN ('none', 'personal', 'identifying', 'sensitive')),
  why          text NOT NULL,
  PRIMARY KEY (table_schema, table_name, column_name)
);
INSERT INTO gov.column_class VALUES
 ('sales','customers','customer_id','personal','internal number; joins to everything about them'),
 ('sales','customers','full_name','identifying','a name'),
 ('sales','customers','email','identifying','an address that reaches one person'),
 ('sales','customers','birth_date','personal','quasi-identifier (lesson 5)'),
 ('sales','customers','sex','personal','quasi-identifier'),
 ('sales','customers','cep','personal','quasi-identifier; often one street'),
 ('sales','customers','city','personal','quasi-identifier'),
 ('sales','customers','state','personal','quasi-identifier'),
 ('sales','customers','created_at','personal','when this person signed up'),
 ('sales','customers','marketing_opt_in','personal','a choice this person made'),
 ('sales','customers','consent_at','personal','when they made it'),
 ('sales','customers','cpf_ct','identifying','the CPF, encrypted (lesson 4)'),
 ('sales','customers','cpf_hmac','identifying','a stand-in that finds one CPF (lesson 5)'),
```

O arquivo segue do mesmo jeito para toda coluna de toda tabela, 53 linhas ao todo, cada uma com um
**`why`** que diz o que a coluna revela — uma classificação sem motivo é um rótulo que alguém vai
mudar sem saber o que está desfazendo. E uma consulta lista o que ninguém classificou:

```sql
-- Every column of a table in Ipê's schemas that nobody has classified.
-- Run in CI, an answer that is not empty fails the build.
SET ROLE ipe_owner;
SELECT c.table_schema, c.table_name, c.column_name
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN gov.column_class k
  ON k.table_schema = c.table_schema AND k.table_name = c.table_name
 AND k.column_name = c.column_name
WHERE c.table_schema IN ('sales', 'health', 'support')
  AND t.table_type = 'BASE TABLE'
  AND k.class IS NULL
ORDER BY 1, 2, 3;
```

```
ana@lab:~/gov$ sudo -u postgres psql -c "CREATE SCHEMA gov AUTHORIZATION ipe_owner"
CREATE SCHEMA
ana@lab:~/gov$ psql -f classes.sql
SET
CREATE TABLE
INSERT 0 53
ana@lab:~/gov$ psql -f unclassified.sql
SET
 table_schema | table_name | column_name 
--------------+------------+-------------
(0 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT class, count(*) FROM gov.column_class GROUP BY class ORDER BY 2 DESC"
SET
    class    | count 
-------------+-------
 personal    |    31
 none        |     9
 sensitive   |     9
 identifying |     4
(4 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l6-classes\" aria-label=\"As 53 colunas das tabelas da Ipê por classe: 31 pessoais, 9 sensíveis, 9 sem nada sobre uma pessoa, 4 identificadoras. As sensíveis estão em health.prescriptions, em sales.order_items.product_id e em support.tickets.body.\"><text x=\"138.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">personal</text><rect x=\"150.0\" y=\"26.0\" width=\"434.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"594.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">31</text><text x=\"138.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sensitive</text><rect x=\"150.0\" y=\"72.0\" width=\"126.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"286.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"316.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">health.prescriptions (7), order_items.product_id, tickets.body</text><text x=\"138.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">none</text><rect x=\"150.0\" y=\"118.0\" width=\"126.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"286.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"138.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">identifying</text><rect x=\"150.0\" y=\"164.0\" width=\"56.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"216.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"246.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nome, e-mail, cpf_ct, cpf_hmac</text></svg>", "caption": "A maioria das colunas é dado pessoal, e as sensíveis não estão todas no schema chamado health.", "same": ["health.prescriptions (7), order_items.product_id, tickets.body"]}
```

Nada sem classe; 31 colunas pessoais, 9 sensíveis, 4 identificadoras e 9 sem nada sobre uma pessoa.
**A maior parte das colunas da Ipê é dado pessoal**, como a seção 2 previu, e as sensíveis não estão
só em `health`: `order_items.product_id` e o texto livre dos chamados de suporte também estão lá,
pelos motivos que as seções 4 e 9 dão.

## A verificação que a mantém verdadeira

Uma classificação escrita uma vez vale por uma semana. A consulta é o que a faz durar, porque pode
rodar onde as mudanças de schema rodam — no pipeline que aplica migrações — e falhar quando acha
alguma coisa:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.orders ADD COLUMN coupon_code text"
SET
ALTER TABLE
ana@lab:~/gov$ psql -f unclassified.sql
SET
 table_schema | table_name | column_name 
--------------+------------+-------------
 sales        | orders     | coupon_code
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "INSERT INTO gov.column_class VALUES ('sales','orders','coupon_code','personal','a code may be issued to one person')"
SET
INSERT 0 1
ana@lab:~/gov$ psql -q -At -f unclassified.sql | wc -l
0
```

Um desenvolvedor acrescentou `coupon_code` aos pedidos; a verificação a achou no dia em que
apareceu; uma linha a classifica e a verificação volta a ficar quieta. **Acrescentar uma coluna sem
decidir o que ela guarda passa a ser impossível, e não só desaconselhado.** A próxima seção mostra
a mesma ideia na plataforma em que este curso está rodando.
