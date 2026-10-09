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
