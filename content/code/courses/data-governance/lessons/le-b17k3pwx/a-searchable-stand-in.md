---
title: A stand-in the database can search
version: 1
---

To find a customer by CPF, the database needs a column where the same CPF always gives the same
value — so it can be indexed and compared — and from which nobody can work back to the CPF. An
encryption with a random nonce fails the first test; a plain hash fails the second, because a CPF
has only eleven digits and every one of them can be hashed in an afternoon.

**A keyed hash — an HMAC — passes both**, provided the key is somewhere nobody can read it. OpenBao's
transit engine computes HMACs with a key that never leaves it:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf-index
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791344084]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-cpf-index
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64); echo
vault:v1:l1jDUSj8dorJ9bd8Knbe/1D+8q/tjs/3hyLEVtJ/qBg=
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-cpf-index input=$(printf '372.874.168-09' | base64); echo
vault:v1:l1jDUSj8dorJ9bd8Knbe/1D+8q/tjs/3hyLEVtJ/qBg=
```

The same CPF, twice, the same HMAC. Without `ipe-cpf-index` — which is not exportable — nobody can
compute it, so the column can sit in the database, in backups and in exports without being a
dictionary of CPFs. The `v1` is the key version, as in lesson 4.

The column is filled the same way lesson 4 encrypted the CPFs, by a script calling OpenBao in
batches:

```python
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
```

```
ana@lab:~/gov$ psql -f index.sql
SET
ALTER TABLE
ana@lab:~/gov$ python3 index_cpf.py
6012 CPFs indexed
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "CREATE UNIQUE INDEX ON sales.customers (cpf_hmac)"
SET
ERROR:  could not create unique index "customers_cpf_hmac_idx"
DETAIL:  Key (cpf_hmac)=(vault:v1:Eii5YuOYAXbl+hlcEt0CdNwT9j9dVb47y8q6vKayXRY=) is duplicated.
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS cpfs_twice FROM (SELECT cpf_hmac FROM sales.customers GROUP BY cpf_hmac HAVING count(*) > 1) d"
SET
 cpfs_twice 
------------
         12
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "CREATE INDEX ON sales.customers (cpf_hmac)"
SET
CREATE INDEX
```

**The unique index was refused**, and that is a finding, not a bug in the script. Twelve HMACs
appear twice, which means twelve CPFs appear twice: the same person registered as two customers.
Lesson 9 measures data quality and finds those twelve from another side; here they arrived because
an index asked the question nobody had asked before. The index is created without `UNIQUE`, and
the duplicates go on lesson 9's list.

## Why an HMAC and not a token from a vault

Both would let the database find a customer. The difference is in what has to be called and when:

| | random token and vault | keyed hash (HMAC) |
|---|---|---|
| same input, same output | only by looking it up in the vault | yes, by computing it |
| who holds the mapping | the vault, a table that must be protected | nobody: there is no mapping, only a key |
| finding a customer by a CPF read out on the phone | ask the vault for the CPF's token, then search | compute the HMAC, then search |
| getting the CPF back | detokenise | not possible from the HMAC — decrypt `cpf_ct` instead |

The HMAC is a **one-way stand-in**: perfect for searching and joining, useless for reading. That is
why the CPF ends up with two columns, each with one job, and why the next section can drop the
third.
