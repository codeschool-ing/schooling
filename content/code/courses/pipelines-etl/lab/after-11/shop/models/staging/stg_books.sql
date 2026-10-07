-- One row per book.
select book_id, isbn, title, category, publisher, list_price_cents
  from {{ source('raw', 'books') }}
