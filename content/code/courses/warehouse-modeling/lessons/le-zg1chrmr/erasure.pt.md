---
title: Apagando uma pessoa e mantendo as vendas
version: 1
---

O artigo 18 da LGPD lista os direitos que uma pessoa tem sobre seus dados, entre eles **anonimização e eliminação**. O
artigo 16 lista o que a empresa pode guardar mesmo assim, como o que uma obrigação legal ou regulatória exige. Para uma
loja, isso significa uma tensão conhecida: a venda aconteceu, os registros fiscais dela precisam ser guardados, e o
cliente ainda pode pedir para ser esquecido.

A classificação diz onde a pessoa está. O cliente 19 tem três versões na `dim_customer`, e seis linhas de vendas:

```
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT customer_key, customer_id, name, tier, city, state, valid_from FROM dim_customer WHERE customer_id = 19"
┌──────────────┬─────────────┬──────────────────┬─────────┬──────────────┬─────────┬──────────────────────────┐
│ customer_key │ customer_id │       name       │  tier   │     city     │  state  │        valid_from        │
│    int64     │    int64    │     varchar      │ varchar │   varchar    │ varchar │ timestamp with time zone │
├──────────────┼─────────────┼──────────────────┼─────────┼──────────────┼─────────┼──────────────────────────┤
│           27 │          19 │ Gabriela Barbosa │ reader  │ Porto Alegre │ RS      │ 2021-06-18 16:45:20-03   │
│           28 │          19 │ Gabriela Barbosa │ regular │ Porto Alegre │ RS      │ 2022-04-04 18:48:13-03   │
│           29 │          19 │ Gabriela Barbosa │ patron  │ Porto Alegre │ RS      │ 2023-04-21 11:15:26-03   │
└──────────────┴─────────────┴──────────────────┴─────────┴──────────────┴─────────┴──────────────────────────┘
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT count(*) AS lines, sum(net_cents) AS net_cents FROM fact_sales WHERE customer_key IN (SELECT customer_key FROM dim_customer WHERE customer_id = 19)"
┌───────┬───────────┐
│ lines │ net_cents │
│ int64 │  int128   │
├───────┼───────────┤
│     6 │     73630 │
└───────┴───────────┘
```

```sql
-- Customer 19 asked to be erased. Every version loses what identifies the
-- person; the keys stay, so the sales still add up and point at nobody.
UPDATE dim_customer
SET customer_id = NULL, name = 'Erased on request', tier = 'erased',
    city = 'Erased', state = '--'
WHERE customer_id = 19;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < erase.sql
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT customer_key, customer_id, name, tier, city, state, valid_from FROM dim_customer WHERE customer_key IN (SELECT DISTINCT customer_key FROM dim_customer WHERE name = 'Erased on request')"
┌──────────────┬─────────────┬───────────────────┬─────────┬─────────┬─────────┬──────────────────────────┐
│ customer_key │ customer_id │       name        │  tier   │  city   │  state  │        valid_from        │
│    int64     │    int64    │      varchar      │ varchar │ varchar │ varchar │ timestamp with time zone │
├──────────────┼─────────────┼───────────────────┼─────────┼─────────┼─────────┼──────────────────────────┤
│           27 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2021-06-18 16:45:20-03   │
│           28 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2022-04-04 18:48:13-03   │
│           29 │        NULL │ Erased on request │ erased  │ Erased  │ --      │ 2023-04-21 11:15:26-03   │
└──────────────┴─────────────┴───────────────────┴─────────┴─────────┴─────────┴──────────────────────────┘
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT sum(net_cents) AS net_cents FROM fact_sales"
┌────────────┐
│ net_cents  │
│   int128   │
├────────────┤
│ 9574389852 │
└────────────┘
```

O update sobrescreve as colunas pessoais de todas as versões e deixa as chaves em paz. **As tabelas fato não foram
tocadas**: as seis linhas ainda apontam para as chaves 27, 28 e 29, então todo total do warehouse continua o que era,
9.574.389.852 centavos, e as linhas agora pertencem a um cliente que ninguém consegue nomear. O que dava significado ao
identificador foi apagado; o identificador fica.

Três coisas que isso não faz, e cada uma importa:

- **Não mexe nas cópias.** Os arquivos de extração, o esquema de staging, os arquivos Delta do lake e suas versões
  antigas, os backups: cada um ainda guarda a pessoa até ser reconstruído, passar por um vacuum ou expirar. A lição 10
  encontrou isso como o motivo de o histórico de uma tabela Delta ser um passivo além de um recurso. A classificação
  precisa cobri-los também.
- **Mantém as datas das versões.** `valid_from` ainda registra três momentos em que o nível desse cliente mudou. Se três
  carimbos de tempo conseguem levar de volta a uma pessoa é exatamente a pergunta que o artigo 12 faz sobre dados
  anonimizados, se a anonimização pode ser revertida com esforços razoáveis, e isso é um julgamento para quem responde
  pelos dados, não para um script.
- **Não impede a próxima carga.** A menos que o sistema de origem também tenha apagado o cliente, a carga de amanhã o
  traz de volta. A eliminação precisa começar na origem, ou ficar registrada em algum lugar que a carga leia.
