-- One row per order line, with what the line was worth.
select order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents as line_cents
  from {{ source('raw', 'order_lines') }}
