---
title: Tipo 1, sobrescrever
version: 1
---

**O tipo 1 sobrescreve o valor antigo com o novo.** A dimensão tem uma linha por cliente, a linha diz
o que a origem diz hoje, e nada registra o que dizia antes. É o que o banco operacional faz, e o que um
warehouse faz por padrão se ninguém decidir outra coisa.

Construa uma dimensão de clientes tipo 1 a partir de uma extração, e pergunte quanto a rede vendeu em
2024 a clientes de Minas Gerais e do Paraná:

```sql
-- Type 1: one row per customer, overwritten with whatever the extract says.
CREATE OR REPLACE TABLE dim_customer_t1 AS
SELECT customer_id, name, tier, city, state
FROM read_csv('extracts/customers_' || getvariable('extract_date') || '.csv');

SELECT c.state, round(sum(f.net_cents) / 100, 2) AS sold_in_2024_brl
FROM fact_sales f
JOIN dim_customer d     ON d.customer_key = f.customer_key
JOIN dim_customer_t1 c  ON c.customer_id = d.customer_id
JOIN dim_date dt        ON dt.date_key = f.date_key
WHERE dt.year = 2024 AND c.state IN ('MG', 'PR')
GROUP BY ALL ORDER BY c.state;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE extract_date = DATE '2025-10-01'" < type1.sql
┌─────────┬──────────────────┐
│  state  │ sold_in_2024_brl │
│ varchar │      double      │
├─────────┼──────────────────┤
│ MG      │       4688508.55 │
│ PR      │       3575257.82 │
└─────────┴──────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE extract_date = DATE '2025-12-01'" < type1.sql
┌─────────┬──────────────────┐
│  state  │ sold_in_2024_brl │
│ varchar │      double      │
├─────────┼──────────────────┤
│ MG      │       4679116.31 │
│ PR      │       3573642.13 │
└─────────┴──────────────────┘
```

**A mesma pergunta sobre 2024, feita em outubro de 2025 e de novo em dezembro de 2025, dá duas
respostas diferentes.** Minas Gerais perdeu R$ 9.392,24 de vendas de 2024 entre as duas cargas. Nada
sobre 2024 mudou nesses dois meses. Saíram de Minas Gerais mais clientes do que entraram em outubro e
novembro, a sobrescrita levou o histórico inteiro deles junto, e um relatório impresso em outubro não
bate mais com o warehouse.

Essa é a propriedade que define o tipo 1: **o passado é reescrito para parecer o presente.** É errado
para tudo o que as pessoas analisam ao longo do tempo, e exatamente certo para um tipo de mudança:

- **Correções.** Um nome digitado errado no caixa, uma cidade escrita de dois jeitos, uma data de
  nascimento com dia e mês trocados. O valor antigo nunca foi verdade, então não há histórico que valha
  guardar, e toda venda passada deve mostrar o valor corrigido.
- **Atributos que ninguém analisa.** O idioma preferido de um cliente para e-mails, a imagem de capa de
  um livro. Se nenhum relatório agrupa por ele ao longo do tempo, guardar o histórico custa espaço e não
  compra nada.

Os nomes dos clientes da rede são tipo 1 pelo primeiro motivo: o registro de mudanças tem 508 mudanças
de nome, e cada uma é a correção de como o nome foi digitado no caixa.
