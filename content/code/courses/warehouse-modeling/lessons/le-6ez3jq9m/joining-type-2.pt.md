---
title: Fazendo uma pergunta a uma dimensão tipo 2
version: 1
---

Com o tipo 2, um fato pode ser descrito **como era** ou **como é agora**, e as duas são perguntas
diferentes. Receita de 2025 por nível de fidelidade, dos dois jeitos:

```sql
-- Revenue of 2025 by loyalty tier: the tier the customer had when they
-- bought, against the tier they have now.
SELECT d.tier AS tier_at_sale, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d USING (customer_key)
JOIN dim_date dt    USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;

SELECT now.tier AS tier_today, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d   USING (customer_key)
JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current
JOIN dim_date dt      USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < by-tier.sql
┌──────────────┬─────────────┐
│ tier_at_sale │ revenue_brl │
│   varchar    │   double    │
├──────────────┼─────────────┤
│ reader       │ 35689643.01 │
│ regular      │  3720786.22 │
│ patron       │   897527.15 │
└──────────────┴─────────────┘
┌────────────┬─────────────┐
│ tier_today │ revenue_brl │
│  varchar   │   double    │
├────────────┼─────────────┤
│ reader     │ 34440811.35 │
│ regular    │  4657279.06 │
│ patron     │  1209865.97 │
└────────────┴─────────────┘
```

O primeiro resultado agrupa cada venda pela versão para a qual ela aponta: o nível que o cliente
**tinha quando comprou**. O segundo vai dessa versão à versão atual do cliente e agrupa pelo nível que
ele **tem hoje**.

**Os readers compraram R$ 35.689.643,01 em 2025, como readers. Os clientes que são readers hoje
compraram R$ 34.440.811,35.** A diferença, R$ 1.248.831,66, é o que foi comprado como reader por pessoas
que subiram de nível depois. Os dois números estão certos:

- **Nível na época** responde "quanto compra o nível mais baixo do programa?" — o que o gerente precisa
  saber antes de mudar o que se oferece aos readers.
- **Nível hoje** responde "quanto gastaram este ano os nossos patrons atuais?" — o que o gerente precisa
  saber antes de decidir a quem mandar um convite.

Um relatório que não diz qual dos dois mostra vai ser lido como o outro por alguém.

A primeira consulta é a junção comum de estrela: a tabela fato já carrega a chave da versão certa,
porque a carga a procurou quando a venda chegou (`20_fact_sales.sql` liga por
`o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to`). **A viagem no tempo é feita uma vez, na
carga**, e toda consulta depois disso ganha "como era" de graça. "Como é agora" custa mais uma junção por
`customer_id` e `is_current`, e a seção 10 mostra um jeito de guardar isso também.
