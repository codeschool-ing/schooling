---
title: Encrypting a column, and where the key went
version: 1
---

The CPF is the column Ipê would least like to see in somebody else's hands: a Brazilian taxpayer
number, printed on documents and asked for everywhere, which is why it is used to impersonate
people. Encrypting just that column, inside the table, would mean a backup, a replica and a
careless `SELECT` all carry ciphertext. PostgreSQL ships an extension for it, **pgcrypto**:

```sql
-- pgcrypto in a schema of its own: the public schema is closed to
-- everybody (lesson 1's schema), and functions should not live there anyway.
CREATE SCHEMA crypto;
CREATE EXTENSION pgcrypto SCHEMA crypto;
GRANT USAGE ON SCHEMA crypto TO ipe_owner;
```

```
ana@lab:~/gov$ sudo -u postgres psql < pgcrypto.sql
CREATE SCHEMA
CREATE EXTENSION
GRANT
```

The extension goes in a schema of its own, `crypto`, because lesson 1's schema closed `public` to
everybody, and because a schema named for what is in it can be granted on its own. Then Ana's
first attempt:

```sql
-- A FIRST ATTEMPT: the CPF encrypted by the database, with a key in the SQL.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD COLUMN cpf_enc bytea;
UPDATE sales.customers
   SET cpf_enc = crypto.pgp_sym_encrypt(cpf, 'chave-da-ipe-2026');
SELECT customer_id, cpf, left(encode(cpf_enc, 'hex'), 40) AS cpf_enc
FROM sales.customers WHERE customer_id = 1;
```

```
ana@lab:~/gov$ psql -f encrypt.sql
SET
ALTER TABLE
UPDATE 6012
 customer_id |      cpf       |                 cpf_enc                  
-------------+----------------+------------------------------------------
           1 | 372.874.168-09 | c30d040703020722140bf6f1c35668d23f0119ea
(1 row)
```

Every one of the 6,012 CPFs now has an encrypted copy beside it. `pgp_sym_encrypt` produces an
OpenPGP message — the leading `c30d04` bytes are its packet header — encrypted with a key derived
from the passphrase, with a random salt so that two equal CPFs give different ciphertexts. The
plaintext column is still there, because this is a first attempt; the plan would be to drop it.

## The key travelled with the query

Reading it back needs the passphrase too, and that is where the design breaks. Ana turns on full
statement logging — which teams do to debug, and leave on longer than they meant to — and reads
one CPF:

```sql
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo -u postgres psql < leak.sql
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT crypto.pgp_sym_decrypt(cpf_enc, 'chave-da-ipe-2026') FROM sales.customers WHERE customer_id = 1"
SET
 pgp_sym_decrypt 
-----------------
 372.874.168-09
(1 row)

ana@lab:~/gov$ sudo grep -c "chave-da-ipe-2026" /var/log/postgresql/postgresql-16-gov.log
1
ana@lab:~/gov$ sudo grep -m 1 "pgp_sym_decrypt" /var/log/postgresql/postgresql-16-gov.log
2026-10-07 02:17:53.732 -03 [3958] ana@ipe LOG:  statement: SELECT crypto.pgp_sym_decrypt(cpf_enc, 'chave-da-ipe-2026') FROM sales.customers WHERE customer_id = 1
```

**The key is in the server's log**, in clear, in the same line as the query that used it. The
statement travelled to the server as text, so the key did too, and every place a statement can
land now holds it: the log, `pg_stat_activity` while the query runs, `pg_stat_statements` if it is
installed, a slow-query report, a screenshot of a monitoring dashboard. And the database server,
the thing the encryption was supposed to protect the column from, holds the key in memory every
time it decrypts. Ana turns statement logging off again before going on:

```sh
sudo -u postgres psql -c "ALTER SYSTEM RESET log_statement" -c "SELECT pg_reload_conf()"
```

**Encrypting inside the database protects against whoever gets a copy of the data without the
key.** It does not protect against the database, its administrators or its logs, because the key
passes through all three. That is not a flaw of pgcrypto; it is where the encryption ends, asked
the question from the first section of this lesson.

## Where the key should be

The alternative is to encrypt **before** the data reaches the database, in the application, with
a key the database never sees. The database then stores ciphertext it cannot read, and a stolen
backup, a curious administrator and a verbose log all hold nothing useful. The application needs
the key instead, so the question moves: where does the application get it, and who else can? A
key in the application's configuration file is a password in a file again. Lesson 4 puts it in a
key-management service that hands out the *use* of a key without handing out the key — and
replaces this column.
