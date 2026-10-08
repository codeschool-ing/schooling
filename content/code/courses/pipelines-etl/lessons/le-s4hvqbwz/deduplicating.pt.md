---
title: Tirar duplicatas: uma linha por coisa que aconteceu
version: 1
---

A lição 3 contou os eventos entregues duas vezes no arquivo de um dia. Ao longo da semana, a camada
crua guarda cada entrega, e a tabela de staging guarda uma linha por evento:

```
-- One row per event, however many times the collector delivered it, dated by
-- when it happened rather than by the file it landed in.
DROP TABLE IF EXISTS staging.events CASCADE;
CREATE TABLE staging.events AS
SELECT event_id, occurred_at, event_date, session, type, book_id
  FROM (SELECT doc->>'event_id'                     AS event_id,
               (doc->>'occurred_at')::timestamptz   AS occurred_at,
               ((doc->>'occurred_at')::timestamptz
                  AT TIME ZONE 'America/Sao_Paulo')::date AS event_date,
               doc->>'session'                      AS session,
               doc->>'type'                         AS type,
               (doc->>'book_id')::integer           AS book_id,
               row_number() OVER (PARTITION BY doc->>'event_id' ORDER BY file) AS copy
          FROM raw.events) AS delivered
 WHERE copy = 1;
```

A consulta de dentro numera as cópias de cada `event_id` com `row_number()`, ordenadas pelo arquivo
em que vieram, e a de fora guarda a cópia número um. Ela também calcula a data a partir do
`occurred_at`, o momento em que o evento aconteceu — o *horário do evento* da lição 3 — e não do
arquivo em que ele caiu.

```
ana@vm:~/etl$ psql -q -d wh -f sql/staging/events.sql
psql:sql/staging/events.sql:3: NOTICE:  table "events" does not exist, skipping
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.events) AS delivered, (SELECT count(*) FROM staging.events) AS events"
 delivered | events 
-----------+--------
     18308 |  18230
(1 row)
```

**Setenta e oito entregas eram segundas cópias.** Uma contagem de visualizações direto da
`raw.events` teria dado 78 a mais, e o erro teria crescido a cada dia em que o pipeline rodasse.

## O que faz duas linhas serem a mesma

Tirar duplicatas exige uma definição de *a mesma*, e essa definição é a parte difícil:

- um identificador que o produtor deu — o `event_id` aqui. O melhor caso: duas linhas com o
  mesmo id são o mesmo evento por definição;
- todas as colunas iguais — `SELECT DISTINCT`. Perigoso: dois clientes que de fato compraram o
  mesmo livro no mesmo segundo viram um só;
- uma chave de negócio — o mesmo ISBN, da mesma editora, no mesmo `updated_at`. Funciona quando
  não há id, e precisa de alguém que conheça o negócio para dizer quais colunas formam a chave.

**Qual cópia guardar** é a segunda decisão. Para eventos as cópias são idênticas, então o primeiro
arquivo serve tanto quanto qualquer outro. Para duas versões de uma linha que diferem — o pedido
estornado da lição 4 — a regra é "a mais nova", e o `ORDER BY` dentro do `row_number()` é onde essa
regra é escrita.
