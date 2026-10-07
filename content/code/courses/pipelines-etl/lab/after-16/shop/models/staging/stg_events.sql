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
