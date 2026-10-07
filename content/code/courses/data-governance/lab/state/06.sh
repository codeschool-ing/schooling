# Where lesson 6 leaves the database: the schema gov with gov.column_class
# classifying every column of Ipê's tables (and sales.orders.coupon_code,
# added and classified in the lesson), and support.tickets_redacted, the
# view analysts read tickets through.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg -c "CREATE SCHEMA gov AUTHORIZATION ipe_owner"
pg <<'SQL'
-- Every column of Ipê's tables, and what it holds. Four classes, no more:
--   none         nothing about a person
--   personal     about a person, identifies them only with other data
--   identifying  picks a person out on its own
--   sensitive    article 5, II of the LGPD, or reveals it
SET ROLE ipe_owner;
CREATE TABLE gov.column_class (
  table_schema name NOT NULL,
  table_name   name NOT NULL,
  column_name  name NOT NULL,
  class        text NOT NULL
               CHECK (class IN ('none', 'personal', 'identifying', 'sensitive')),
  why          text NOT NULL,
  PRIMARY KEY (table_schema, table_name, column_name)
);
INSERT INTO gov.column_class VALUES
 ('sales','customers','customer_id','personal','internal number; joins to everything about them'),
 ('sales','customers','full_name','identifying','a name'),
 ('sales','customers','email','identifying','an address that reaches one person'),
 ('sales','customers','birth_date','personal','quasi-identifier (lesson 5)'),
 ('sales','customers','sex','personal','quasi-identifier'),
 ('sales','customers','cep','personal','quasi-identifier; often one street'),
 ('sales','customers','city','personal','quasi-identifier'),
 ('sales','customers','state','personal','quasi-identifier'),
 ('sales','customers','created_at','personal','when this person signed up'),
 ('sales','customers','marketing_opt_in','personal','a choice this person made'),
 ('sales','customers','consent_at','personal','when they made it'),
 ('sales','customers','cpf_ct','identifying','the CPF, encrypted (lesson 4)'),
 ('sales','customers','cpf_hmac','identifying','a stand-in that finds one CPF (lesson 5)'),
 ('sales','orders','order_id','personal','an order is somebody''s'),
 ('sales','orders','customer_id','personal','who placed it'),
 ('sales','orders','ordered_at','personal','when they bought'),
 ('sales','orders','status','personal','what happened to their order'),
 ('sales','orders','total_cents','personal','what they spent'),
 ('sales','order_items','order_id','personal','joins to the customer'),
 ('sales','order_items','line_no','none','a position in the order'),
 ('sales','order_items','product_id','sensitive','which medicine somebody bought reveals health'),
 ('sales','order_items','quantity','personal','how much of it'),
 ('sales','order_items','unit_price_cents','none','the price on the day'),
 ('sales','products','product_id','none','the catalogue'),
 ('sales','products','name','none','the catalogue'),
 ('sales','products','category','none','the catalogue'),
 ('sales','products','needs_prescription','none','the catalogue'),
 ('sales','products','controlled','none','the catalogue'),
 ('sales','products','price_cents','none','the catalogue'),
 ('sales','payments','order_id','personal','joins to the customer'),
 ('sales','payments','method','personal','how they paid'),
 ('sales','payments','card_token','personal','a reference the provider maps to a card'),
 ('sales','payments','card_last4','personal','recognisable to the cardholder'),
 ('sales','payments','amount_cents','personal','what they paid'),
 ('sales','returns','order_id','personal','joins to the customer'),
 ('sales','returns','returned_on','personal','when they returned it'),
 ('sales','returns','reason','personal','free text a customer may have dictated'),
 ('sales','deliveries','order_id','personal','joins to the customer'),
 ('sales','deliveries','delivered_at','personal','when they were at home'),
 ('health','prescriptions','prescription_id','sensitive','a prescription is health data'),
 ('health','prescriptions','customer_id','sensitive','whose prescription'),
 ('health','prescriptions','order_id','sensitive','joins health to a purchase'),
 ('health','prescriptions','product_id','sensitive','what was prescribed'),
 ('health','prescriptions','prescriber','sensitive','which doctor; a speciality says a diagnosis'),
 ('health','prescriptions','issued_on','sensitive','when'),
 ('health','prescriptions','scan_path','sensitive','where the image of the prescription is'),
 ('support','tickets','ticket_id','personal','a ticket is somebody''s'),
 ('support','tickets','customer_id','personal','whose'),
 ('support','tickets','opened_at','personal','when they wrote'),
 ('support','tickets','status','personal','what happened to it'),
 ('support','tickets','body','sensitive','free text: section 9 found CPFs, addresses and medicines in it'),
 ('support','agent_regions','agent','personal','an employee'),
 ('support','agent_regions','state','none','a state');
ALTER TABLE sales.orders ADD COLUMN coupon_code text;
INSERT INTO gov.column_class VALUES ('sales','orders','coupon_code','personal','a code may be issued to one person');
-- What analysts may read of a ticket: the text with the patterns that
-- identify somebody, or reveal their health, replaced.
SET ROLE ipe_owner;
CREATE VIEW support.tickets_redacted AS
SELECT ticket_id, opened_at, status,
       regexp_replace(
         regexp_replace(
           regexp_replace(body, '\d{3}\.\d{3}\.\d{3}-\d{2}', '[CPF]', 'g'),
           '[[:alnum:]._]+@[[:alnum:].]+', '[EMAIL]', 'g'),
         'I take [a-z]+', 'I take [MEDICINE]', 'gi') AS body
FROM support.tickets;
GRANT USAGE ON SCHEMA support TO analyst;
GRANT SELECT ON support.tickets_redacted TO analyst;
SQL
