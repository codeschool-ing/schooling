#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 5 leave
# (`lab.sh state 5`). The CPF check in section 12 reads the CSV file lab.sh
# generated, /var/lib/ipe-data/customers.csv, because the database no longer
# holds a CPF in clear after lesson 5.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, 4 cores, TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 5 >/dev/null 2>&1 </dev/null

put inferred.sql <<'EOF'
-- What a pharmacy's order lines say about the people who placed them.
SET ROLE ipe_owner;
SELECT p.category,
       count(DISTINCT o.customer_id) AS customers
FROM sales.order_items i
JOIN sales.orders o   USING (order_id)
JOIN sales.products p USING (product_id)
WHERE p.category IN ('psychiatric', 'diabetes', 'contraceptive',
                     'diagnostic', 'cardiovascular', 'thyroid')
GROUP BY p.category ORDER BY customers DESC;
EOF
code inferred-sql inferred.sql
block inferred
on 'psql -f inferred.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT name, category FROM sales.products WHERE category = '"'"'diagnostic'"'"'"'

put minors.sql <<'EOF'
-- Customers under eighteen on the lab's today, by age.
SET ROLE ipe_owner;
SELECT extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age,
       count(*) AS customers,
       count(*) FILTER (WHERE marketing_opt_in) AS accepted_marketing
FROM sales.customers
WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
GROUP BY 1 ORDER BY 1;
EOF
code minors-sql minors.sql
block minors
on 'psql -f minors.sql'

put inventory.sql <<'EOF'
-- The first draft of an inventory: every column that exists, per table.
SET ROLE ipe_owner;
SELECT table_schema || '.' || table_name AS table, count(*) AS columns
FROM information_schema.columns
WHERE table_schema IN ('sales', 'health', 'support')
  AND table_name IN (SELECT table_name FROM information_schema.tables
                     WHERE table_type = 'BASE TABLE')
GROUP BY 1 ORDER BY 1;
EOF
code inventory-sql inventory.sql
block inventory
on 'psql -f inventory.sql'

put classes.sql <<'EOF'
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
EOF
code classes-sql classes.sql
put unclassified.sql <<'EOF'
-- Every column of a table in Ipê's schemas that nobody has classified.
-- Run in CI, an answer that is not empty fails the build.
SET ROLE ipe_owner;
SELECT c.table_schema, c.table_name, c.column_name
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN gov.column_class k
  ON k.table_schema = c.table_schema AND k.table_name = c.table_name
 AND k.column_name = c.column_name
WHERE c.table_schema IN ('sales', 'health', 'support')
  AND t.table_type = 'BASE TABLE'
  AND k.class IS NULL
ORDER BY 1, 2, 3;
EOF
code unclassified-sql unclassified.sql
block classes
on 'sudo -u postgres psql -c "CREATE SCHEMA gov AUTHORIZATION ipe_owner"'
on 'psql -f classes.sql'
on 'psql -f unclassified.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT class, count(*) FROM gov.column_class GROUP BY class ORDER BY 2 DESC"'

block new-column
on 'psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.orders ADD COLUMN coupon_code text"'
on 'psql -f unclassified.sql'
on "psql -c \"SET ROLE ipe_owner\" -c \"INSERT INTO gov.column_class VALUES ('sales','orders','coupon_code','personal','a code may be issued to one person')\""
on 'psql -q -At -f unclassified.sql | wc -l'

put tickets.sql <<'EOF'
-- What customers typed into the support form, counted by what it contains.
SET ROLE ipe_owner;
SELECT count(*) AS tickets,
       count(*) FILTER (WHERE body ~ '\d{3}\.\d{3}\.\d{3}-\d{2}') AS with_a_cpf,
       count(*) FILTER (WHERE body ~ '[[:alnum:]._]+@[[:alnum:].]+') AS with_an_email,
       count(*) FILTER (WHERE body ~* 'sertraline|insulin|clonazepam') AS naming_a_medicine
FROM support.tickets;
EOF
code tickets-sql tickets.sql
block tickets
on 'psql -f tickets.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT ticket_id, body FROM support.tickets WHERE body ~* '"'"'sertraline'"'"' ORDER BY ticket_id LIMIT 2"'

put redact.sql <<'EOF'
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
EOF
code redact-sql redact.sql
block redact
on 'psql -f redact.sql'
on 'psql service=bruno -c "SELECT ticket_id, body FROM support.tickets_redacted WHERE position('"'"'['"'"' IN body) > 0 ORDER BY ticket_id LIMIT 4"'

put cpf_check.py <<'EOF'
"""How many CPFs in the file pass their own check digits."""
import csv, sys

def digit_ok(cpf, n):
    """Is the n-th digit (9 or 10, from zero) the check digit it should be?"""
    d = [int(c) for c in cpf if c.isdigit()]
    s = sum(v * w for v, w in zip(d[:n], range(n + 1, 1, -1)))
    return (s * 10 % 11) % 10 == d[n]

rows = list(csv.DictReader(open(sys.argv[1])))
first = sum(digit_ok(r["cpf"], 9) for r in rows)
both = sum(digit_ok(r["cpf"], 9) and digit_ok(r["cpf"], 10) for r in rows)
print(len(rows), "CPFs:", first, "pass the first check digit,", both, "pass both")
EOF
code cpf-check-py cpf_check.py
block cpf-check
on 'python3 cpf_check.py /var/lib/ipe-data/customers.csv'
