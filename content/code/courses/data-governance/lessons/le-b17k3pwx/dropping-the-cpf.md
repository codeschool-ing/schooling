---
title: Dropping the CPF
version: 1
---

Every use of the CPF in clear now has a replacement. Support reads it by decrypting `cpf_ct`
through OpenBao; anybody finds a customer by it through `cpf_hmac`; analysts never had it. So the
column can go. The first attempt:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "ALTER TABLE sales.customers DROP COLUMN cpf"
SET
ERROR:  cannot drop column cpf of table sales.customers because other objects depend on it
DETAIL:  view sales.customer_profile depends on column cpf of table sales.customers
view support.customer_card depends on column cpf of table sales.customers
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

Two views depend on it. `customer_card` is expected — it shows the masked CPF. `customer_profile`
is the analysts' view from lesson 2, and it never showed a CPF at all: it depends on the column
because its inner query says `c.*`, and **`*` in a view's definition is a dependency on every
column, including the ones you mean to remove.** The fix is to name the columns the view uses:

```sql
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
```

```
ana@lab:~/gov$ psql -f drop-cpf.sql
SET
CREATE VIEW
DROP VIEW
ALTER TABLE
CREATE VIEW
GRANT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "\d sales.customers"
SET
                           Table "sales.customers"
      Column      |           Type           | Collation | Nullable | Default 
------------------+--------------------------+-----------+----------+---------
 customer_id      | integer                  |           | not null | 
 full_name        | text                     |           | not null | 
 email            | text                     |           | not null | 
 birth_date       | date                     |           | not null | 
 sex              | character(1)             |           | not null | 
 cep              | text                     |           | not null | 
 city             | text                     |           | not null | 
 state            | character(2)             |           | not null | 
 created_at       | timestamp with time zone |           | not null | 
 marketing_opt_in | boolean                  |           | not null | 
 consent_at       | timestamp with time zone |           |          | 
 cpf_ct           | text                     |           |          | 
 cpf_hmac         | text                     |           |          | 
Indexes:
    "customers_pkey" PRIMARY KEY, btree (customer_id)
    "customers_cpf_hmac_idx" btree (cpf_hmac)
Check constraints:
    "customers_sex_check" CHECK (sex = ANY (ARRAY['F'::bpchar, 'M'::bpchar]))
Referenced by:
    TABLE "sales.orders" CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
    TABLE "health.prescriptions" CONSTRAINT "prescriptions_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
    TABLE "support.tickets" CONSTRAINT "tickets_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id)
Policies:
    POLICY "agent_sees_own_states" FOR SELECT
      TO support_agent
      USING ((state IN ( SELECT r.state
   FROM support.agent_regions r
  WHERE (r.agent = CURRENT_USER))))
    POLICY "analysts_see_all" FOR SELECT
      TO analyst,pipeline
      USING (true)
```

`sales.customers` no longer has a column called `cpf`. A dump, a replica, a careless `SELECT *`, the
server's log and lesson 3's `grep` on the data file can find no CPF in clear anywhere in the table.
The support card shows the HMAC and the ciphertext, which mean nothing to a person and are exactly
what the support application needs.

## Finding Paula, again

Support's OpenBao policy grows by one path — computing the index — and the support application does
what it would do when a customer reads out their number:

```hcl
# Support decrypts a CPF to read it to the customer, and computes the
# index of a CPF the customer reads out, to find them.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
path "transit/hmac/ipe-cpf-index" {
  capabilities = ["update"]
}
```

```
ana@lab:~/gov$ bao policy write support support-hmac.hcl
Success! Uploaded policy: support
ana@lab:~/gov$ bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token
26 support.token
ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64) > wanted.hmac
ana@lab:~/gov$ psql service=carla -c "SELECT customer_id, full_name, email, city FROM support.customer_card WHERE cpf_hmac = '$(cat wanted.hmac)'"
 customer_id |       full_name        |      email       |   city    
-------------+------------------------+------------------+-----------
           1 | Paula Cavalcanti Silva | p***@example.com | São Paulo
(1 row)
```

The application computed the HMAC of the CPF the customer said, with a token allowed only to decrypt
CPFs and to compute that index, and Carla's view found Paula by it. If Carla needed to read the CPF
back to her, the same token would decrypt `cpf_ct`.

**What the database holds about a CPF now is two strings it cannot turn into a CPF.** The capability
to do so lives in OpenBao, behind policies, in an audit log. That is the strongest position this
course reaches for a single value — and it cost one encrypted column, one indexed column, two
policies and a view, which is why it is kept for the values that deserve it.
