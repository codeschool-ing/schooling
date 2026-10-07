-- The operational database of Ponto Final, the source every pipeline in the
-- course reads. The tills and the website write it; nothing in this course
-- does, except lab.sh playing back a day of trade.
CREATE TABLE shops (
  shop_id   integer PRIMARY KEY,
  name      text NOT NULL,
  city      text,
  state     text,
  channel   text NOT NULL CHECK (channel IN ('store', 'online'))
);
CREATE TABLE books (
  book_id          integer PRIMARY KEY,
  isbn             text NOT NULL UNIQUE,
  title            text NOT NULL,
  category         text NOT NULL,
  publisher        text NOT NULL,
  list_price_cents integer NOT NULL CHECK (list_price_cents > 0),
  updated_at       timestamptz NOT NULL
);
CREATE TABLE customers (
  customer_id integer PRIMARY KEY,
  name        text NOT NULL,
  email       text NOT NULL UNIQUE,
  city        text NOT NULL,
  state       text NOT NULL,
  created_at  timestamptz NOT NULL,
  updated_at  timestamptz NOT NULL
);
CREATE TABLE orders (
  order_id    integer PRIMARY KEY,
  shop_id     integer NOT NULL REFERENCES shops,
  customer_id integer REFERENCES customers,
  ordered_at  timestamptz NOT NULL,
  status      text NOT NULL CHECK (status IN ('completed', 'cancelled', 'refunded')),
  updated_at  timestamptz NOT NULL
);
CREATE INDEX orders_updated_at ON orders (updated_at);
CREATE TABLE order_lines (
  order_id         integer NOT NULL REFERENCES orders,
  line_no          integer NOT NULL,
  book_id          integer NOT NULL REFERENCES books,
  quantity         integer NOT NULL CHECK (quantity > 0),
  unit_price_cents integer NOT NULL CHECK (unit_price_cents > 0),
  PRIMARY KEY (order_id, line_no)
);
CREATE TABLE payments (
  payment_id   integer PRIMARY KEY,
  order_id     integer NOT NULL REFERENCES orders,
  method       text NOT NULL,
  amount_cents integer NOT NULL,
  paid_at      timestamptz NOT NULL
);
