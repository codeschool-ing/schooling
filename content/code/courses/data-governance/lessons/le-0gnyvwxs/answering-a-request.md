---
title: Answering a request, end to end
version: 1
---

**Article 19** sets the deadlines for confirmation and access. The answer may be given in a
**simplified form, immediately**; or as a **clear and complete declaration** — with the origin of the
data, the criteria used and the purpose, protecting trade secrets — **within 15 days** of the
request. When the processing rests on consent or a contract, the person may also ask for a complete
electronic copy in a format that allows it to be used elsewhere (§3), which is the bridge to
portability.

For the other rights, the law fixes no number of days: article 18, §4 asks for action, or an
explanation of why there is none, and the ANPD may regulate the rest. Ipê does what most controllers
do and answers **every** kind of request within the same 15 days, because one deadline is a deadline
people remember.

## Who answers

The requests reach the DPO, and in the lab the DPO is Davi. He needs to read everything about one
customer and change nothing, which lesson 2's job roles do not give anybody:

```sql
-- The DPO answers data subjects' requests: he may read what is about a
-- customer, and change nothing.
CREATE ROLE privacy_officer NOLOGIN;
GRANT privacy_officer TO davi;
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales, health, support, gov TO privacy_officer;
GRANT SELECT ON ALL TABLES IN SCHEMA sales, health, support, gov TO privacy_officer;
CREATE POLICY privacy_officer_reads_all ON sales.customers
  FOR SELECT TO privacy_officer USING (true);
CREATE POLICY privacy_officer_reads_all ON support.tickets
  FOR SELECT TO privacy_officer USING (true);
```

```
ana@lab:~/gov$ psql -f privacy-role.sql
CREATE ROLE
GRANT ROLE
SET
GRANT
GRANT
CREATE POLICY
CREATE POLICY
```

The two policies matter. `sales.customers` and `support.tickets` have row-level security since
lesson 2, and a role with `SELECT` and no policy reads **zero rows** without an error — the export
below would have come back with an empty customer and nobody would have noticed.

The CPF is encrypted (lessons 4 and 5). An access request is one of the few reasons to decrypt it,
so the DPO gets a policy in OpenBao that allows exactly that and a token that lasts one hour:

```hcl
# The DPO decrypts a CPF to include it in a data subject's export.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

```
ana@lab:~/gov$ bao policy write dpo dpo.hcl
Success! Uploaded policy: dpo
ana@lab:~/gov$ bao token create -policy=dpo -ttl=1h -field=token > dpo.token && wc -c dpo.token
26 dpo.token
```

## The export

```python
"""Everything Ipê holds about one customer, as JSON, for a data subject's
request under article 18 of the LGPD. Which tables to read comes from
gov.column_class: a table with a customer_id is about somebody directly, and
a table with an order_id and no customer_id is about them through an order."""
import base64, json, os, ssl, subprocess, sys, urllib.request

ID = int(sys.argv[1])
TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])

def psql(sql):
    out = subprocess.run(["psql", "service=davi", "-X", "-q", "-At", "-c", sql],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out) if out.strip() else None

def decrypt(ct):
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/decrypt/ipe-cpf",
                                 data=json.dumps({"ciphertext": ct}).encode(), method="POST",
                                 headers={"X-Vault-Token": open("dpo.token").read().strip()})
    with urllib.request.urlopen(req, context=TLS) as r:
        return base64.b64decode(json.load(r)["data"]["plaintext"]).decode()

def tables_with(column, without=None):
    no = (f"AND NOT EXISTS (SELECT 1 FROM gov.column_class d WHERE d.table_schema = c.table_schema "
          f"AND d.table_name = c.table_name AND d.column_name = '{without}')") if without else ""
    return psql("SELECT json_agg(DISTINCT c.table_schema || '.' || c.table_name) "
                f"FROM gov.column_class c WHERE c.column_name = '{column}' {no}") or []

where = {t: f"customer_id = {ID}" for t in tables_with("customer_id")}
for t in tables_with("order_id", without="customer_id"):
    where[t] = f"order_id IN (SELECT order_id FROM sales.orders WHERE customer_id = {ID})"

export = {"customer_id": ID, "generated_for": "LGPD art. 18, II", "tables": {}}
for t in sorted(where):
    rows = psql(f"SELECT json_agg(t) FROM {t} t WHERE {where[t]}") or []
    for r in rows:
        r.pop("cpf_hmac", None)
        if r.get("cpf_ct"):
            r["cpf"] = decrypt(r.pop("cpf_ct"))
    export["tables"][t] = rows
json.dump(export, sys.stdout, ensure_ascii=False, indent=1)
print()
```

The script does not list tables. It asks `gov.column_class` which tables have a `customer_id`, and
which have an `order_id` and no `customer_id` — order items and payments are about a customer
through an order, and an export that looked only for `customer_id` missed them on its first run. A
table added next year and classified as lesson 6 requires is in the export without anybody editing
this file. The keyed hash is removed, since it means nothing to the person, and the CPF is
decrypted.

```
ana@lab:~/gov$ python3 export_subject.py 112 > subject-112.json && wc -c subject-112.json
3226 subject-112.json
ana@lab:~/gov$ python3 -c "import json; d = json.load(open('subject-112.json')); print({t: len(r) for t, r in d['tables'].items()})"
{'health.prescriptions': 3, 'sales.consent_events': 1, 'sales.customers': 1, 'sales.deliveries': 0, 'sales.order_items': 4, 'sales.orders': 3, 'sales.payments': 3, 'sales.returns': 0, 'support.tickets': 1}
ana@lab:~/gov$ python3 -c "import json; d = json.load(open('subject-112.json')); print(json.dumps(d['tables']['sales.customers'][0], ensure_ascii=False, indent=1))"
{
 "customer_id": 112,
 "full_name": "Sérgio Moura Fernandes",
 "email": "sergio.moura@example.net",
 "birth_date": "1982-07-16",
 "sex": "M",
 "cep": "30193-173",
 "city": "Belo Horizonte",
 "state": "MG",
 "created_at": "2020-01-02T10:44:08-03:00",
 "marketing_opt_in": true,
 "consent_at": "2020-01-02T07:23:03-03:00",
 "cpf": "610.041.257-87"
}
```

Nine tables, 3,226 bytes, for customer 112: his three orders and their four items, three payments,
three prescriptions, one support ticket, one consent event, and the customer row with his CPF in
clear. Two tables came back empty and are in the file anyway — "you have no returns" is part of a
complete answer.

## Keeping the clock

```sql
-- Every request a data subject makes, with the date the answer is due.
SET ROLE ipe_owner;
CREATE TABLE gov.subject_requests (
  request_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id integer     NOT NULL,
  kind        text        NOT NULL
              CHECK (kind IN ('confirm', 'access', 'correct', 'delete', 'port',
                              'revoke-consent', 'sharing-info')),
  received_on date        NOT NULL,
  due_on      date        GENERATED ALWAYS AS (received_on + 15) STORED,
  answered_on date,
  answer      text
);
INSERT INTO gov.column_class VALUES
 ('gov','subject_requests','request_id','personal','one person''s request'),
 ('gov','subject_requests','customer_id','personal','whose'),
 ('gov','subject_requests','kind','personal','what they asked for'),
 ('gov','subject_requests','received_on','personal','when'),
 ('gov','subject_requests','due_on','none','arithmetic on the date'),
 ('gov','subject_requests','answered_on','personal','when we answered'),
 ('gov','subject_requests','answer','personal','what we did');
GRANT SELECT, INSERT, UPDATE (answered_on, answer) ON gov.subject_requests TO privacy_officer;
INSERT INTO gov.subject_requests (customer_id, kind, received_on, answered_on, answer) VALUES
  (112, 'access', '2026-06-02', '2026-06-09', 'export sent, subject-112.json'),
  (3,  'delete',  '2026-06-20', NULL, NULL),
  (47, 'access',  '2026-06-10', NULL, NULL),
  (88, 'correct', '2026-06-25', NULL, NULL);
```

```sql
-- On the lab's today, 1 July 2026: what is open, and what is late.
SELECT request_id, customer_id, kind, received_on, due_on,
       CASE WHEN due_on < DATE '2026-07-01' THEN 'LATE' ELSE 'open' END AS state
FROM gov.subject_requests
WHERE answered_on IS NULL
ORDER BY due_on;
```

```
ana@lab:~/gov$ psql -f requests.sql
SET
CREATE TABLE
INSERT 0 7
GRANT
INSERT 0 4
ana@lab:~/gov$ psql service=davi -f due.sql
 request_id | customer_id |  kind   | received_on |   due_on   | state 
------------+-------------+---------+-------------+------------+-------
          3 |          47 | access  | 2026-06-10  | 2026-06-25 | LATE
          2 |           3 | delete  | 2026-06-20  | 2026-07-05 | open
          4 |          88 | correct | 2026-06-25  | 2026-07-10 | open
(3 rows)
```

The due date is a **generated column**, so it cannot disagree with the date the request arrived.
Request 1 was answered in seven days. Request 3 was received on 10 June and nobody has answered it;
on 1 July it is six days late. **A deadline that lives in somebody's calendar is missed the week
they are on holiday**; one that lives in a table can be checked by a query every morning, and that
query is how this one was found.
