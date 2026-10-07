---
title: The CPF, encrypted before it reaches the database
version: 1
---

Lesson 3 ended with a promise: replace the column whose key travelled in the query. The pieces are
in place — a key the database never sees, a website allowed to encrypt and not decrypt, support
allowed to decrypt and not encrypt.

First, the old attempt goes, and a column for ciphertext takes its place:

```sql
-- Lesson 3's first attempt goes, and a column for ciphertext the
-- database receives and cannot read takes its place.
SET ROLE ipe_owner;
ALTER TABLE sales.customers DROP COLUMN cpf_enc;
ALTER TABLE sales.customers ADD COLUMN cpf_ct text;
```

```
ana@lab:~/gov$ psql -f column.sql
SET
ALTER TABLE
ALTER TABLE
```

Then the job the website does for every new customer, done once for all of them. In a real
system this happens in the application code at sign-up; here a script plays the website, with the
website's token:

```schooling-example
{
  "language": "python",
  "file": "encrypt_cpf.py",
  "parts": [
    {
      "code": "\"\"\"Encrypt every customer's CPF with the website's key, in batches, and\nwrite the ciphertexts back. The database never sees the key: it receives\nciphertext, which it stores and cannot read.\"\"\"\nimport base64, csv, io, json, os, ssl, subprocess, urllib.request\n\n",
      "note": "The standard library and nothing else, so the script runs on any machine with Python 3."
    },
    {
      "code": "ADDR = os.environ[\"BAO_ADDR\"]\nTOKEN = open(\"site-app.token\").read().strip()\nTLS = ssl.create_default_context(cafile=os.environ[\"BAO_CACERT\"])\n\n",
      "note": "**The website's token, not Ana's.** It carries the `site-app` policy, so this script can encrypt and could not decrypt a single CPF if it tried. The CA file is the lab's, so the connection to OpenBao is checked like the one to PostgreSQL."
    },
    {
      "code": "def psql(sql):\n    return subprocess.run([\"psql\", \"-X\", \"-q\", \"-f\", \"-\"], input=sql,\n                          capture_output=True, text=True, check=True).stdout\n\n",
      "note": "Every statement goes to psql on standard input, under Ana's own login."
    },
    {
      "code": "def encrypt(values):\n    body = json.dumps({\"batch_input\": [\n        {\"plaintext\": base64.b64encode(v.encode()).decode()} for v in values]})\n    req = urllib.request.Request(f\"{ADDR}/v1/transit/encrypt/ipe-cpf\",\n                                 data=body.encode(), method=\"POST\",\n                                 headers={\"X-Vault-Token\": TOKEN})\n    with urllib.request.urlopen(req, context=TLS) as r:\n        return [b[\"ciphertext\"] for b in json.load(r)[\"data\"][\"batch_results\"]]\n\n",
      "note": "**One request encrypts many values.** `batch_input` takes a list, each plaintext base64-encoded, and the answer keeps the order, so the n-th ciphertext belongs to the n-th CPF. The key never appears: the request names it, `ipe-cpf`, and OpenBao uses it."
    },
    {
      "code": "rows = list(csv.reader(io.StringIO(psql(\n    \"SET ROLE ipe_owner;\\n\"\n    \"COPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);\"))))\n",
      "note": "The CPFs leave the database once, in id order, as CSV."
    },
    {
      "code": "pairs = []\nfor i in range(0, len(rows), 250):\n    chunk = rows[i:i + 250]\n    pairs += zip([c for c, _ in chunk], encrypt([cpf for _, cpf in chunk]))\n",
      "note": "**Batches of 250**, so that no single request is large: 6,012 CPFs take 25 of them."
    },
    {
      "code": "values = \",\\n\".join(f\"({c}, '{ct}')\" for c, ct in pairs)\npsql(\"SET ROLE ipe_owner;\\n\"\n     \"UPDATE sales.customers c SET cpf_ct = v.ct\\n\"\n     f\"FROM (VALUES {values}) AS v(id, ct) WHERE c.customer_id = v.id;\")\nprint(len(pairs), \"CPFs encrypted by\", ADDR)\n",
      "note": "**What goes back is ciphertext.** One `UPDATE` joins the pairs by id; the database stores `vault:v2:…` strings and has nothing that turns them back into CPFs."
    }
  ]
}
```

```
ana@lab:~/gov$ python3 encrypt_cpf.py
6012 CPFs encrypted by https://bao.ipe.example:8200
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, left(cpf_ct, 40) AS cpf_ct FROM sales.customers ORDER BY 1 LIMIT 3"
SET
 customer_id |                  cpf_ct                  
-------------+------------------------------------------
           1 | vault:v2:6imxF0NlF2vTZrptkc/KgEt/Yzg8I2d
           2 | vault:v2:iBJqvllnAsO0445cFowNVOjzf5eT6Eg
           3 | vault:v2:OMTRBdV/vcaK9v/U8B85snk9yKKrLjM
(3 rows)

ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=vault:v2:6imxF0NlF2vTZrptkc/KgEt/Yzg8I2djETTPEwRvNVaJ/bi00tSlxyuu | base64 -d; echo
372.874.168-09
```

Every CPF now has a `vault:v2:` ciphertext beside it, made with version 2 of `ipe-cpf` because
that is the latest. Support can turn one back into a CPF; the website, which wrote all 6,012,
could not read one of them.

## What changed, and what has not

**The database now holds a value it cannot read.** A dump of `sales.customers` carries
ciphertext in `cpf_ct`; so does a replica, so does a careless `SELECT *` by a role that was granted
too much, and so does the server's log if a statement mentions the column. None of them carries
the key, because the key never came near the database.

**The plaintext `cpf` column is still there**, and that is deliberate, for one more lesson. Support
finds a customer by CPF when they call, and the database cannot search ciphertext: two encryptions
of the same CPF are different strings. Dropping the plaintext needs a second column that *can* be
searched without being readable, and that is what lesson 5 calls a **token**. Until then, the
grants of lesson 2 are what keep the plaintext column away from analysts.

**And the website's code is now part of the protection.** It holds a token allowed to encrypt; if
it logged every CPF before encrypting it, the whole arrangement would leak through the
application's own log. Application-level encryption moves the trust from the database to the
application, which is the right place only if the application is reviewed as carefully as the
database was.
