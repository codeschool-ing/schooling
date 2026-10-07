---
title: Encrypting one column
version: 1
---

**Column-level encryption encrypts a single sensitive value before it is stored, so that the
database holds only ciphertext for it and a query without the key returns bytes.** It is the one
layer that protects a value from the people who run the database, and the most expensive to live
with, because the database can no longer search, sort or index what it cannot read.

## pgcrypto, the obvious way

PostgreSQL's `pgcrypto` extension encrypts inside SQL. Vereda stores two patients, who happen to share
a CPF in this lab, encrypted with `encrypt(…, 'aes')`:

```
ana@lab:~/lab$ psql -c 'CREATE TABLE patients (id int PRIMARY KEY, name text, cpf bytea)'
CREATE TABLE
ana@lab:~/lab$ psql -c "INSERT INTO patients VALUES (1, 'Marina Duarte', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes')), (2, 'Joao Pires', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes'))"
INSERT 0 2
ana@lab:~/lab$ psql -c 'SELECT id, name, encode(cpf, '\''hex'\'') FROM patients'
 id |     name      |              encode              
----+---------------+----------------------------------
  1 | Marina Duarte | 6dcb6aeebf8d296550dfa0244f23af02
  2 | Joao Pires    | 6dcb6aeebf8d296550dfa0244f23af02
(2 rows)
```

**Both ciphertexts are identical.** `encrypt()` with `'aes'` uses CBC with an all-zero initialisation
vector unless told otherwise, so equal CPFs give equal bytes: lesson 1's fixed-IV problem, in a
database. An administrator who cannot decrypt anything can still see which patients share a value,
and with a column like a diagnosis code, that is often the secret. With the key, the value comes back:

```
ana@lab:~/lab$ psql -c "SELECT id, convert_from(decrypt(cpf, 'k-lab-0123456789abcdef0123456789', 'aes'), 'UTF8') FROM patients WHERE id = 1"
 id |  convert_from  
----+----------------
  1 | 111.444.777-35
(1 row)
```

`pgp_sym_encrypt` does it properly: OpenPGP's format, a random session key and IV for every value,
and an integrity check. The same CPF, re-encrypted in both rows, now gives two different
ciphertexts:

```
ana@lab:~/lab$ psql -c "UPDATE patients SET cpf = pgp_sym_encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'cipher-algo=aes256')"
UPDATE 2
ana@lab:~/lab$ psql -c 'SELECT count(*) AS rows, count(DISTINCT cpf) AS distinct_values FROM patients'
 rows | distinct_values 
------+-----------------
    2 |               2
(1 row)
```

And both decrypt to the same value:

```
ana@lab:~/lab$ psql -c "SELECT id, pgp_sym_decrypt(cpf, 'k-lab-0123456789abcdef0123456789') FROM patients"
 id | pgp_sym_decrypt 
----+-----------------
  1 | 111.444.777-35
  2 | 111.444.777-35
(2 rows)
```

## The problem with encrypting in SQL

Look at where the key was in every command above: **in the query text.** It crossed the connection
to the server, sat in the server's memory, and appears in its logs whenever statement logging is on,
in `pg_stat_statements`, and in any monitoring tool that captures slow queries. The database
administrator the column was meant to be protected from can read the key in the log.

So column encryption that protects against the database's own operators is done **in the
application**: it encrypts with AES-GCM (lesson 1) before sending the value, binds the row's id as
associated data so a ciphertext cannot be moved to another row, and gets its key from a key
management service (next section). The database only ever sees bytes.

## What it costs

- **No searching on the encrypted column.** `WHERE cpf = '…'` cannot work on randomised ciphertext.
  The usual answer is a separate **blind index**: an HMAC (lesson 6) of the normalised value, with its
  own key, stored beside the ciphertext for equality lookups. It reveals equality, deliberately, and
  nothing else.
- **No sorting, ranges or partial matches** on that column.
- **Key rotation means re-encrypting rows**, unless the scheme stores a key identifier per row and
  rotates gradually, as lesson 5 did for password hashes.

That cost is why column encryption is kept for the few values whose exposure would be worst: identity
numbers, card numbers, clinical notes. The LGPD's sensitive personal data is the natural list for a
clinic.
