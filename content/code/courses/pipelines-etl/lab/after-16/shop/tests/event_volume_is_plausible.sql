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
