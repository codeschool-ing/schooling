---
title: Expectativas: o que costuma acontecer
version: 1
---

Alguns problemas não quebram regra nenhuma. Um dia com um quinto dos seus eventos não tem nulo, nem
duplicata, nem tipo errado; cada linha dele é um evento perfeitamente bom. O que está errado é
**quantas** há, e o único jeito de ver isso é comparar com o que costuma acontecer. Isso é uma
**expectativa**: não uma regra que os dados devem obedecer, mas uma faixa em que se espera que eles
caiam, em que cair fora merece o olhar de uma pessoa.

A Ana acrescenta os eventos do site ao projeto dbt — uma fonte, e um modelo de staging que é o
`staging/events.sql` da lição 6 com `source` dentro — e uma expectativa sobre o volume diário deles:

```
version: 2

sources:
  - name: raw                   # what load_raw.py copies in: dbt reads it, never writes it
    schema: raw
    tables:
      - name: orders
      - name: order_lines
      - name: books
      - name: events
```

```
-- One row per website event, however many times the collector delivered it,
-- dated by when it happened in São Paulo.
select event_id, occurred_at, event_date, session, type, book_id
  from (select doc->>'event_id'                   as event_id,
               (doc->>'occurred_at')::timestamptz as occurred_at,
               ((doc->>'occurred_at')::timestamptz
                  at time zone 'America/Sao_Paulo')::date as event_date,
               doc->>'session'                    as session,
               doc->>'type'                       as type,
               (doc->>'book_id')::integer         as book_id,
               row_number() over (partition by doc->>'event_id' order by file) as copy
          from {{ source('raw', 'events') }}) as delivered
 where copy = 1
```

```
-- An expectation, not a rule: each day of March has between half and twice the
-- events of the seven days before it, on average. A day outside that range is
-- not impossible, but it is worth a person's look before anything is built on it.
with daily as (
    select event_date, count(*) as events
      from {{ ref('stg_events') }}
     group by 1
), compared as (
    select event_date, events,
           avg(events) over (order by event_date rows between 7 preceding and 1 preceding)
             as usual
      from daily
)
select event_date, events, round(usual) as usual
  from compared
 where event_date >= date '2026-03-01'
   and (events < usual / 2 or events > usual * 2)
```

Cada dia é comparado com a média dos sete anteriores, e qualquer dia abaixo da metade ou acima do
dobro é devolvido. No mês até aqui, nenhum é:

```
ana@vm:~/etl/shop$ dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:03:50  1 of 2 OK created sql view model dbt_staging.stg_events ........................ [CREATE VIEW in 0.13s]
07:03:50  2 of 2 PASS event_volume_is_plausible .......................................... [PASS in 0.18s]
07:03:50  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

Então um incidente, encenado e declarado: o coletor entrega só a primeira parte do arquivo do dia 20,
quatrocentas linhas onde um dia tem duas mil e quinhentas, e para. Nada dá erro. O arquivo é JSON
válido, cada evento nele é real, e a carga e a view dão certo:

```
ana@vm:~/etl$ wc -l landing/events/2026-03-19.jsonl landing/events/2026-03-20.jsonl
  2589 landing/events/2026-03-19.jsonl
   400 landing/events/2026-03-20.jsonl
  2989 total
ana@vm:~/etl$ python load_raw.py >/dev/null
ana@vm:~/etl/shop$ dbt build -s stg_events+ 2>&1 | grep -E " OK | PASS | FAIL |Done"
07:03:54  1 of 2 OK created sql view model dbt_staging.stg_events ........................ [CREATE VIEW in 0.10s]
07:03:54  2 of 2 FAIL 1 event_volume_is_plausible ........................................ [FAIL 1 in 0.16s]
07:03:54  Done. PASS=1 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
ana@vm:~/etl$ psql -d wh -f shop/target/compiled/shop/tests/event_volume_is_plausible.sql
 event_date | events | usual 
------------+--------+-------
 2026-03-20 |    399 |  2476
(1 row)

done
```

**A expectativa pegou o que nada mais conseguia**: 399 eventos no dia 20 onde uns 2.476 é o normal.
Rodar o teste compilado no `psql` mostra o dia e os dois números, que é o que a Ana manda para quem
cuida do coletor. Sem ela, o dia 20 teria entrado em todo relatório como o dia mais calmo do mês no
site.

Expectativas pedem um cuidado que regras não pedem. Dias de verdade variam — um feriado, uma
promoção, uma newsletter — e uma expectativa justa o bastante para pegar todo incidente também vai
disparar com notícia boa. **De metade ao dobro** é folgado de propósito. Uma falha aqui é uma
pergunta, como a lição 12 disse de toda falha: às vezes a resposta é *era Black Friday*. Bibliotecas
como Great Expectations e Soda existem para escrever muitas conferências como esta com menos SQL;
nenhuma está instalada no laboratório, e a lição não roda nenhuma.
