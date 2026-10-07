-- The landing schema: every file exactly as it arrived, every column text.
--
-- Nothing is typed, trimmed or converted here. A column declared `date` would
-- refuse `14/03/2025` or, worse, read it the way the server's DateStyle says;
-- a column declared `numeric` would refuse `R$ 94,50` and stop the load. The
-- cleaning is the course, and it starts from what the systems really sent.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

CREATE TABLE raw.customers (
  customer_id text, name text, email text, cep text, city text, state text,
  signed_up text, birth_year text, signup_channel text, marketing_opt_in text);

CREATE TABLE raw.orders (
  order_id text, customer_id text, channel text, ordered_at text, fulfilment text,
  total text, discount text, delivery_fee text, payment text, status text,
  courier text, delivery_minutes text);

CREATE TABLE raw.order_items (
  order_id text, line_no text, product_code text, quantity text, unit text,
  unit_price text);

CREATE TABLE raw.products (
  product_code text, name text, category text, unit text, price text);

CREATE TABLE raw.store_sales (
  venda text, loja text, data text, hora text, cliente text, total text,
  pagamento text, itens text);

CREATE TABLE raw.survey (
  order_id text, sent_on text, answered_on text, nps text);

CREATE TABLE raw.invoices (
  invoice text, supplier text, issued text, currency text, amount text,
  weight text, weight_unit text);

CREATE TABLE raw.fx_rates_2025 (month text, usd_brl text, eur_brl text);

CREATE TABLE raw.targets_2025 (
  loja text, "jan/25" text, "fev/25" text, "mar/25" text, "abr/25" text,
  "mai/25" text, "jun/25" text, "jul/25" text, "ago/25" text, "set/25" text,
  "out/25" text, "nov/25" text, "dez/25" text, "Total" text);

\copy raw.customers FROM 'raw/customers.csv' WITH (FORMAT csv, HEADER true)
\copy raw.orders FROM 'raw/orders.csv' WITH (FORMAT csv, HEADER true)
\copy raw.order_items FROM 'raw/order_items.csv' WITH (FORMAT csv, HEADER true)
\copy raw.products FROM 'raw/products.csv' WITH (FORMAT csv, HEADER true)
\copy raw.store_sales FROM 'raw/store_sales.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'LATIN1')
\copy raw.survey FROM 'raw/survey.csv' WITH (FORMAT csv, HEADER true)
\copy raw.invoices FROM 'raw/invoices.csv' WITH (FORMAT csv, HEADER true)
\copy raw.fx_rates_2025 FROM 'raw/fx_rates_2025.csv' WITH (FORMAT csv, HEADER true)
\copy raw.targets_2025 FROM 'raw/targets_2025.csv' WITH (FORMAT csv, HEADER true)
