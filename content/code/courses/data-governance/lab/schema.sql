-- The database of Farmácia Ipê as the lab builds it, before any lesson has
-- touched it: three schemas, the tables the website and the shops write, and
-- not one grant. Every privilege in the course is added by a lesson.
--
-- Run as the superuser, in the database `ipe`. lab.sh loads the CSV files
-- generate.py wrote straight after.

CREATE ROLE ipe_owner NOLOGIN;
COMMENT ON ROLE ipe_owner IS 'owns every table; nobody logs in as it';

CREATE SCHEMA sales   AUTHORIZATION ipe_owner;
CREATE SCHEMA health  AUTHORIZATION ipe_owner;
CREATE SCHEMA support AUTHORIZATION ipe_owner;

-- A fresh database lets every role create objects in `public` before
-- PostgreSQL 15, and the habit outlived the default. Nothing here uses it.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

SET ROLE ipe_owner;

CREATE TABLE sales.customers (
  customer_id      integer PRIMARY KEY,
  full_name        text        NOT NULL,
  email            text        NOT NULL,
  cpf              text        NOT NULL,
  birth_date       date        NOT NULL,
  sex              char(1)     NOT NULL CHECK (sex IN ('F', 'M')),
  cep              text        NOT NULL,
  city             text        NOT NULL,
  state            char(2)     NOT NULL,
  created_at       timestamptz NOT NULL,
  marketing_opt_in boolean     NOT NULL,
  consent_at       timestamptz
);

CREATE TABLE sales.products (
  product_id         integer PRIMARY KEY,
  name               text    NOT NULL,
  category           text    NOT NULL,
  needs_prescription boolean NOT NULL,
  controlled         boolean NOT NULL,
  price_cents        integer NOT NULL CHECK (price_cents > 0)
);

CREATE TABLE sales.orders (
  order_id    integer PRIMARY KEY,
  customer_id integer REFERENCES sales.customers,
  ordered_at  timestamptz NOT NULL,
  status      text        NOT NULL,
  total_cents integer     NOT NULL
);
CREATE INDEX ON sales.orders (customer_id);
CREATE INDEX ON sales.orders (ordered_at);

CREATE TABLE sales.order_items (
  order_id         integer REFERENCES sales.orders,
  line_no          smallint,
  product_id       integer NOT NULL REFERENCES sales.products,
  quantity         integer NOT NULL CHECK (quantity > 0),
  unit_price_cents integer NOT NULL,
  PRIMARY KEY (order_id, line_no)
);

CREATE TABLE sales.payments (
  order_id     integer PRIMARY KEY REFERENCES sales.orders,
  method       text    NOT NULL CHECK (method IN ('card', 'pix', 'boleto')),
  card_token   text,
  card_last4   char(4),
  amount_cents integer NOT NULL
);

CREATE TABLE health.prescriptions (
  prescription_id integer PRIMARY KEY,
  customer_id     integer NOT NULL REFERENCES sales.customers,
  order_id        integer NOT NULL REFERENCES sales.orders,
  product_id      integer NOT NULL REFERENCES sales.products,
  prescriber      text    NOT NULL,
  issued_on       date    NOT NULL,
  scan_path       text    NOT NULL
);
CREATE INDEX ON health.prescriptions (customer_id);

CREATE TABLE support.tickets (
  ticket_id   integer PRIMARY KEY,
  customer_id integer NOT NULL REFERENCES sales.customers,
  opened_at   timestamptz NOT NULL,
  status      text        NOT NULL,
  body        text        NOT NULL
);
CREATE INDEX ON support.tickets (customer_id);

RESET ROLE;
