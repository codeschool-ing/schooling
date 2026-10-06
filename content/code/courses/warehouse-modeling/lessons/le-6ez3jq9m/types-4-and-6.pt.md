---
title: Tipos 4 e 6, as combinações
version: 1
---

A numeração vai além do 3, e dois dos tipos seguintes valem a pena porque resolvem problemas que o
tipo 2 deixa.

## Tipo 6: o valor atual em toda versão

A seção 06 precisou de uma junção a mais para agrupar as vendas pelo nível que os clientes têm *hoje*.
O tipo 6 guarda essa resposta: toda versão de um cliente carrega o seu próprio valor **e** o valor atual
do cliente, numa segunda coluna. O nome é a aritmética dos três que ele combina, 1 + 2 + 3: linhas tipo
2, com uma coluna tipo 1 do valor atual, que também é a ideia do tipo 3 de guardar dois valores lado a
lado.

```sql
-- Type 6: type 2 rows, each also carrying the customer's current tier.
CREATE TABLE dim_customer_t6 AS
SELECT d.*, now.tier AS current_tier
FROM dim_customer d
LEFT JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current;

SELECT d.tier AS tier_at_sale, d.current_tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer_t6 d USING (customer_key)
JOIN dim_date dt       USING (date_key)
WHERE dt.year = 2025 AND d.tier = 'reader'
GROUP BY ALL ORDER BY revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type6.sql
┌──────────────┬──────────────┬─────────────┐
│ tier_at_sale │ current_tier │ revenue_brl │
│   varchar    │   varchar    │   double    │
├──────────────┼──────────────┼─────────────┤
│ reader       │ reader       │ 34440811.35 │
│ reader       │ regular      │  1208862.02 │
│ reader       │ patron       │    39969.64 │
└──────────────┴──────────────┴─────────────┘
```

Uma consulta agora responde às duas perguntas de uma vez. Dos R$ 35,7 milhões comprados por readers em
2025, R$ 34,4 milhões vieram de quem ainda é reader, R$ 1,2 milhão de quem desde então virou regular, e
R$ 39.969,64 de quem depois chegou a patron. **Essa última linha é o programa funcionando**, e nenhuma
das duas tabelas da seção 06 conseguia mostrá-la.

O custo é a carga: quando o nível de um cliente muda, o `current_tier` de **todas** as versões
anteriores precisa ser atualizado também, o que é uma sobrescrita tipo 1 sobre o histórico inteiro dele.

## Tipo 4: uma minidimensão para o que muda rápido

O tipo 2 cresce uma linha por mudança. Para um atributo que muda com frequência numa dimensão grande,
como um score de crédito atualizado todo mês para milhões de clientes, são linhas demais. O tipo 4 leva
os atributos que mudam rápido para uma tabela pequena própria, uma **minidimensão**, com uma linha por
combinação de valores que ocorre (faixas, e não números exatos), e põe uma segunda chave na tabela fato
apontando para ela. A dimensão de clientes continua lenta; a chave da minidimensão em cada linha fato
registra como eram os atributos rápidos naquele momento.

É a dimensão junk da lição 3 de novo, usada por outro motivo. A rede não precisa de uma: seus níveis
mudam alguns milhares de vezes em dois anos, e o tipo 2 absorve isso sem esforço.
