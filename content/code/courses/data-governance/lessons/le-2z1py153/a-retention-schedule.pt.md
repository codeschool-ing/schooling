---
title: Um cronograma de retenção, como tabela
version: 1
---

Um cronograma de retenção diz, para cada tipo de registro: **por quanto tempo**, **contado a partir de
quando**, **por quê**, e **quem decidiu**. As três primeiras regras da Ipê:

```sql
-- How long each kind of record is kept, from when, and why. One row per
-- rule; the purge reads nothing else.
SET ROLE ipe_owner;
CREATE TABLE gov.retention (
  table_schema name     NOT NULL,
  table_name   name     NOT NULL,
  keep_for     interval NOT NULL,
  counted_from text     NOT NULL,
  basis        text     NOT NULL,
  decided_by   text     NOT NULL,
  PRIMARY KEY (table_schema, table_name)
);
INSERT INTO gov.column_class
SELECT 'gov', 'retention', c, 'none', 'a rule about tables, not people'
FROM unnest(ARRAY['table_schema','table_name','keep_for','counted_from','basis','decided_by']) c;
INSERT INTO gov.retention VALUES
 ('sales',  'orders',        '5 years', 'the first day of the year after the order',
  'tax records: five years from the start of the following year', 'finance manager'),
 ('health', 'prescriptions', '2 years', 'the day the prescription was issued',
  'the chief pharmacist''s rule, after the health rules for controlled medicines',
  'chief pharmacist'),
 ('support','tickets',       '2 years', 'the day the ticket was opened, once closed',
  'no law asks for more; long enough to see a complaint come back', 'head of support');
```

Cada coluna merece o seu lugar:

- **`keep_for`** é um `interval`, para o expurgo poder fazer contas com ele, e para ele não conseguir
  dizer "um tempo".
- **`counted_from`** é onde os cronogramas de retenção mais erram. A lei tributária brasileira conta os
  seus cinco anos a partir do **primeiro dia do ano seguinte** àquele a que o registro pertence, e não
  da data do pedido; um pedido de março de 2020 é guardado até o fim de 2025, e não até março de 2025.
  Um cronograma que conta do dia errado apaga cedo demais, e isso é violação de outra lei.
- **`basis`** diz o porquê em palavras. A regra dos chamados diz com todas as letras que nenhuma lei
  pede dois anos — é uma decisão de negócio, e dizer isso é o que deixa alguém mudá-la depois sem medo
  de uma lei que não acha.
- **`decided_by`** nomeia o papel dono da decisão, como na aula 9.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-timeline\" aria-label=\"A linha do tempo de retenção de um pedido feito em março de 2020. A regra tributária conta cinco anos a partir do primeiro dia do ano seguinte, 1º de janeiro de 2021, então o pedido pode ser expurgado a partir de 1º de janeiro de 2026. Contar da data do pedido o teria apagado em março de 2025, nove meses cedo demais. Um bloqueio judicial para o relógio enquanto durar.\"><path d=\"M40.0 110.0 L680.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M40.0 104.0 L40.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"40.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2020</text><path d=\"M131.4 104.0 L131.4 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"131.4\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2021</text><path d=\"M222.9 104.0 L222.9 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"222.9\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2022</text><path d=\"M314.3 104.0 L314.3 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"314.3\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2023</text><path d=\"M405.7 104.0 L405.7 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2024</text><path d=\"M497.1 104.0 L497.1 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.1\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025</text><path d=\"M588.6 104.0 L588.6 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"588.6\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026</text><path d=\"M680.0 104.0 L680.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2027</text><rect x=\"131.4\" y=\"84.0\" width=\"457.1\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cinco anos, a partir de 1º de janeiro de 2021</text><circle cx=\"58.3\" cy=\"110.0\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"58.3\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido</text><text x=\"58.3\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">março de 2020</text><circle cx=\"588.6\" cy=\"110.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"588.6\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pode ser expurgado</text><text x=\"588.6\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1º de janeiro de 2026</text><circle cx=\"515.4\" cy=\"160.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M515.4 116.0 L515.4 154.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"515.4\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">contado do pedido: março de 2025, cedo demais</text><text x=\"360.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um bloqueio judicial para o relógio até ser liberado</text></svg>", "caption": "Contada a partir do dia errado, uma regra de retenção viola outra lei."}
```

## O que está vencido hoje

```sql
-- On the lab's today, how many rows are past what gov.retention allows.
SET ROLE ipe_owner;
SELECT 'sales.orders' AS "table", count(*) AS past_retention
  FROM sales.orders
  WHERE date_trunc('year', ordered_at) + interval '1 year'
        + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= DATE '2026-07-01'
UNION ALL
SELECT 'health.prescriptions', count(*)
  FROM health.prescriptions
  WHERE issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
        <= DATE '2026-07-01'
UNION ALL
SELECT 'support.tickets', count(*)
  FROM support.tickets
  WHERE status = 'closed'
    AND opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets')
        <= DATE '2026-07-01';
```

```
ana@lab:~/gov$ psql -f retention.sql
SET
CREATE TABLE
INSERT 0 6
INSERT 0 3
ana@lab:~/gov$ psql -f overdue.sql
SET
        table         | past_retention 
----------------------+----------------
 sales.orders         |            963
 health.prescriptions |           9847
 support.tickets      |            367
(3 rows)
```

No hoje do laboratório, 1º de julho de 2026: **963 pedidos** de 2020 para trás, **9.847 receitas**
emitidas há dois anos ou mais, e **367 chamados fechados** com mais de dois anos. Nenhum deles tem mais
motivo para existir, pelas próprias regras da Ipê. Todos são dado pessoal, nove em cada dez dado de
saúde, e todos estariam no próximo vazamento.

A consulta só conta. Decidir apagar é um passo separado, e a próxima seção é o motivo de ele não poder
ser um `DELETE` simples.
