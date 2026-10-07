---
title: Donos e curadores
version: 1
---

Três papéis aparecem em quase todo programa de governança, com nomes diferentes:

| papel | responde por | na Ipê |
|---|---|---|
| **dono** (*owner*) | para que o dado serve, quem pode usá-lo, por quanto tempo é guardado | um papel do negócio: chefe de vendas, farmacêutico responsável |
| **curador** (*steward*) | se ele está correto, completo e documentado, no dia a dia | uma pessoa que trabalha com ele: Bruno, Carla, Davi |
| **custodiante** (*custodian*) | onde ele é guardado, copiado e protegido | a plataforma: Ana, e o banco |

O dono é um **papel, e não uma pessoa**: pessoas mudam de emprego, e uma tabela que pertence à
"Marta" não pertence a ninguém na semana seguinte à saída dela. O curador é uma pessoa, porque alguém
precisa ser perguntado quando um número parece errado. E o custodiante, de propósito, não é o dono: a
pessoa que consegue rodar `DROP TABLE` não é a que decide se a tabela deve existir.

## Escrevendo isso

```sql
-- Who answers for each table: the owner decides what it is for and who may
-- read it; the steward looks after its quality day to day.
SET ROLE ipe_owner;
CREATE TABLE gov.table_owners (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  owner        text NOT NULL,
  steward      text NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class VALUES
 ('gov','table_owners','table_schema','none','a schema'),
 ('gov','table_owners','table_name','none','a table'),
 ('gov','table_owners','owner','personal','an employee''s name'),
 ('gov','table_owners','steward','personal','an employee''s name');
INSERT INTO gov.table_owners VALUES
 ('sales',  'customers',      'head of sales',      'bruno'),
 ('sales',  'orders',         'head of sales',      'bruno'),
 ('sales',  'order_items',    'head of sales',      'bruno'),
 ('sales',  'payments',       'finance manager',    'bruno'),
 ('sales',  'products',       'head of purchasing', 'bruno'),
 ('sales',  'consent_events', 'DPO',                'davi'),
 ('health', 'prescriptions',  'chief pharmacist',   'davi'),
 ('support','tickets',        'head of support',    'carla'),
 ('gov',    'column_class',   'DPO',                'davi'),
 ('gov',    'subject_requests','DPO',               'davi');
```

```sql
-- Every table nobody has said they answer for.
SELECT t.table_schema, t.table_name
FROM information_schema.tables t
LEFT JOIN gov.table_owners o USING (table_schema, table_name)
WHERE t.table_schema IN ('sales', 'health', 'support', 'gov')
  AND t.table_type = 'BASE TABLE'
  AND o.owner IS NULL
ORDER BY 1, 2;
```

```
ana@lab:~/gov$ psql -f owners.sql
SET
CREATE TABLE
INSERT 0 4
INSERT 0 10
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f unowned.sql
SET
 table_schema |  table_name   
--------------+---------------
 gov          | ai_systems
 gov          | holidays
 gov          | table_owners
 sales        | deliveries
 sales        | returns
 support      | agent_regions
(6 rows)
```

Dez tabelas têm dono e curador. Seis não têm, e cada uma diz alguma coisa:

- **`sales.deliveries`, `sales.returns`, `support.agent_regions`** vieram da aula 2, criadas para
  mostrar um privilégio, e ninguém foi perguntado sobre elas desde então. Numa empresa de verdade,
  essas são as tabelas cuja finalidade ninguém sabe explicar três anos depois.
- **`gov.ai_systems` e `gov.holidays`** vieram da aula 8. Tabelas de governança também precisam de
  dono — alguém tem de acrescentar os feriados do ano que vem.
- **O próprio `gov.table_owners`.** A tabela que registra posse não tem dono. É o achado mais comum de
  qualquer primeiro inventário, e se corrige do mesmo jeito que os outros: uma linha.

## Tornando impossível esquecer

O mesmo movimento da aula 6: a consulta acima, rodando com as migrações, falha quando devolve uma
linha. Uma tabela nova então não chega à produção sem alguém dizer quem responde por ela — e o momento
em que essa pergunta é feita é o momento em que quem está criando a tabela ainda sabe a resposta.
