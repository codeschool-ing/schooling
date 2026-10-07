#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 4 leave
# (`lab.sh state 4`): OpenBao initialised and unsealed, Ana logged in with the
# root token, ipe-cpf at version 2 and every CPF in sales.customers.cpf_ct.
#
# Every HMAC and token in the output is made by this run's keys and differs
# from run to run; the counts do not.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 4 >/dev/null 2>&1 </dev/null

put mask.sql <<'EOF'
-- How support sees a customer: enough to recognise them, not enough to
-- copy their documents.
SET ROLE ipe_owner;
CREATE FUNCTION support.mask_cpf(cpf text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN '***.' || substr(cpf, 5, 7) || '-**';
CREATE FUNCTION support.mask_email(email text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN left(email, 1) || '***@' || split_part(email, '@', 2);

CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name,
       support.mask_cpf(cpf)     AS cpf,
       support.mask_email(email) AS email,
       city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);

GRANT SELECT ON support.customer_card TO support_agent;
REVOKE SELECT ON sales.customers FROM support_agent;
EOF
code mask-sql mask.sql
block mask
on 'psql -f mask.sql'
on 'psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"'
on 'psql -c "SET ROLE ipe_owner" -c "GRANT EXECUTE ON FUNCTION support.mask_cpf(text), support.mask_email(text) TO support_agent"'
on 'psql service=carla -c "SELECT * FROM support.customer_card ORDER BY customer_id LIMIT 3"'
on 'psql service=carla -c "SELECT count(*) FROM support.customer_card"'
on 'psql service=carla -c "SELECT cpf FROM sales.customers LIMIT 1"'

put dev.sql <<'EOF'
-- A copy of the customers for the developers' database: the same shape and
-- the same distributions, and nobody in it.
SET ROLE ipe_owner;
COPY (
  SELECT customer_id,
         'Customer ' || customer_id                     AS full_name,
         'customer' || customer_id || '@example.com'    AS email,
         make_date(extract(year FROM birth_date)::int, 1, 1) AS birth_date,
         sex, left(cep, 2) || '000-000'                  AS cep,
         city, state, created_at, marketing_opt_in
  FROM sales.customers ORDER BY customer_id
) TO STDOUT WITH (FORMAT csv, HEADER true);
EOF
code dev-sql dev.sql
block dev
on 'psql -X -q -f dev.sql > dev_customers.csv && head -n 3 dev_customers.csv && wc -l dev_customers.csv'

block card-tokens
on 'psql -c "SET ROLE ipe_owner" -c "SELECT method, card_token, card_last4, amount_cents FROM sales.payments WHERE method = '"'"'card'"'"' ORDER BY order_id LIMIT 3"'

block hmac
on 'bao write -f transit/keys/ipe-cpf-index'
on "bao write -field=hmac transit/hmac/ipe-cpf-index input=\$(printf '372.874.168-09' | base64); echo"
on "bao write -field=hmac transit/hmac/ipe-cpf-index input=\$(printf '372.874.168-09' | base64); echo"

put index_cpf.py <<'EOF'
"""Give every customer a searchable stand-in for the CPF: an HMAC made by
OpenBao with a key nobody can read. Equal CPFs give equal HMACs, so the
database can find a customer by CPF without holding one."""
import base64, csv, io, json, os, ssl, subprocess, urllib.request

TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])
TOKEN = open(os.path.expanduser("~/.vault-token")).read().strip()

def psql(sql):
    return subprocess.run(["psql", "-X", "-q", "-f", "-"], input=sql,
                          capture_output=True, text=True, check=True).stdout

def hmac(values):
    body = json.dumps({"batch_input": [
        {"input": base64.b64encode(v.encode()).decode()} for v in values]})
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/hmac/ipe-cpf-index",
                                 data=body.encode(), method="POST",
                                 headers={"X-Vault-Token": TOKEN})
    with urllib.request.urlopen(req, context=TLS) as r:
        return [b["hmac"] for b in json.load(r)["data"]["batch_results"]]

rows = list(csv.reader(io.StringIO(psql(
    "SET ROLE ipe_owner;\n"
    "COPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);"))))
pairs = []
for i in range(0, len(rows), 250):
    chunk = rows[i:i + 250]
    pairs += zip([c for c, _ in chunk], hmac([cpf for _, cpf in chunk]))
values = ",\n".join(f"({c}, '{h}')" for c, h in pairs)
psql("SET ROLE ipe_owner;\n"
     "UPDATE sales.customers c SET cpf_hmac = v.h\n"
     f"FROM (VALUES {values}) AS v(id, h) WHERE c.customer_id = v.id;")
print(len(pairs), "CPFs indexed")
EOF
code index-py index_cpf.py

put index.sql <<'EOF'
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD COLUMN cpf_hmac text;
EOF
code index-sql index.sql
block index
on 'psql -f index.sql'
on 'python3 index_cpf.py'
on 'psql -c "SET ROLE ipe_owner" -c "CREATE UNIQUE INDEX ON sales.customers (cpf_hmac)"'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS cpfs_twice FROM (SELECT cpf_hmac FROM sales.customers GROUP BY cpf_hmac HAVING count(*) > 1) d"'
on 'psql -c "SET ROLE ipe_owner" -c "CREATE INDEX ON sales.customers (cpf_hmac)"'

block drop-fails
on 'psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers DROP COLUMN cpf"'

put drop-cpf.sql <<'EOF'
-- The CPF in clear has a replacement for each of its uses: cpf_ct to read
-- it (support, through OpenBao) and cpf_hmac to find it. So it goes.
SET ROLE ipe_owner;
CREATE OR REPLACE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT customer_id, state, created_at,
             extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers) c;
DROP VIEW support.customer_card;
ALTER TABLE sales.customers DROP COLUMN cpf;
CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name, cpf_hmac, cpf_ct,
       support.mask_email(email) AS email, city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);
GRANT SELECT ON support.customer_card TO support_agent;
EOF
code drop-cpf-sql drop-cpf.sql
block drop-cpf
on 'psql -f drop-cpf.sql'
on 'psql -c "SET ROLE ipe_owner" -c "\d sales.customers"'

put support-hmac.hcl <<'EOF'
# Support decrypts a CPF to read it to the customer, and computes the
# index of a CPF the customer reads out, to find them.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
path "transit/hmac/ipe-cpf-index" {
  capabilities = ["update"]
}
EOF
code support-hmac-hcl support-hmac.hcl
block find
on 'bao policy write support support-hmac.hcl'
on 'bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token'
on "BAO_TOKEN=\$(cat support.token) bao write -field=hmac transit/hmac/ipe-cpf-index input=\$(printf '372.874.168-09' | base64) > wanted.hmac"
on 'psql service=carla -c "SELECT customer_id, full_name, email, city FROM support.customer_card WHERE cpf_hmac = '"'"'$(cat wanted.hmac)'"'"'"'

put naive.sql <<'EOF'
-- A FIRST DRAFT of the analysts' export: the customer replaced by an md5.
SET ROLE ipe_owner;
COPY (
  SELECT md5(o.customer_id::text) AS customer_ref,
         date_trunc('month', o.ordered_at)::date AS month,
         o.total_cents
  FROM sales.orders o WHERE o.customer_id IS NOT NULL
  ORDER BY o.order_id LIMIT 3
) TO STDOUT WITH (FORMAT csv, HEADER true);
EOF
code naive-sql naive.sql
block naive
on 'psql -X -q -f naive.sql'
on 'psql -X -q -Atc "SELECT customer_id FROM generate_series(1, 6012) AS customer_id WHERE md5(customer_id::text) = '"'"'$(psql -X -q -At -f naive.sql | sed -n 2p | cut -d, -f1)'"'"'"'

block keyed
on 'bao write -f transit/keys/ipe-analytics-ref'
on "bao write -field=hmac transit/hmac/ipe-analytics-ref input=\$(printf '2' | base64); echo"

put quasi.sql <<'EOF'
-- How many customers are alone in their group, for three choices of what
-- an export carries about them. The rest of the columns are not the point.
SET ROLE ipe_owner;
WITH c AS (SELECT * FROM sales.customers)
SELECT 'birth date, sex, CEP' AS released,
       count(*) FILTER (WHERE n = 1) AS alone, count(*) AS customers
FROM (SELECT count(*) OVER (PARTITION BY birth_date, sex, cep) AS n FROM c) g
UNION ALL
SELECT 'birth year, sex, city',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(year FROM birth_date), sex, city) AS n FROM c) g
UNION ALL
SELECT 'decade of birth, sex, state',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(decade FROM birth_date), sex, state) AS n FROM c) g;
EOF
code quasi-sql quasi.sql
block quasi
on 'psql -f quasi.sql'

put kanon.sql <<'EOF'
-- The smallest group, and how many groups are smaller than k = 5, for the
-- generalised release: decade of birth, sex and state.
SET ROLE ipe_owner;
SELECT min(n) AS smallest_group,
       count(*) FILTER (WHERE n < 5) AS groups_under_5,
       sum(n) FILTER (WHERE n < 5) AS customers_in_them,
       count(*) AS groups
FROM (SELECT count(*) AS n FROM sales.customers
      GROUP BY extract(decade FROM birth_date), sex, state) g;
EOF
code kanon-sql kanon.sql
block kanon
on 'psql -f kanon.sql'

put report.sql <<'EOF'
-- Customers with a psychiatric prescription issued in June 2026, by city.
-- A count below 10 is published as "<10", never as the number.
SET ROLE ipe_owner;
SELECT c.city,
       CASE WHEN count(DISTINCT p.customer_id) < 10 THEN '<10'
            ELSE count(DISTINCT p.customer_id)::text END AS customers
FROM health.prescriptions p
JOIN sales.products pr USING (product_id)
JOIN sales.customers c USING (customer_id)
WHERE pr.category = 'psychiatric' AND p.issued_on >= DATE '2026-06-01'
GROUP BY c.city ORDER BY c.city;
EOF
code report-sql report.sql
block report
on 'psql -f report.sql'
