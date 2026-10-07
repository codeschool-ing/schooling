---
title: Choosing where to encrypt
version: 1
---

Each layer in this lesson protects against a different person, and none replaces another. The
decision is not which one to use but which threats a dataset has to survive — and then the cost
of each layer, because the cost is real.

| layer | protects against | does not protect against | costs |
|---|---|---|---|
| **TLS, `verify-full`** | anybody on the network path, and a server impersonating the real one | anybody at either end | a certificate to issue and renew; a client configured to check it |
| **client certificates** | a stolen password for a program | a stolen private key | a CA, and renewal on a schedule |
| **volume encryption** | a disk, a snapshot or a server that leaves your control | every reader with a login; every copy made through the database | almost none at run time; a key to manage |
| **encrypted backups and exports** | the copy that travels furthest and lives longest | readers of the live database | a key that must survive as long as the backup does |
| **column encryption in the database** | copies of the data without the key | the database, its administrators, its logs | the key passes through the server; no indexing or searching on the plaintext |
| **encryption in the application** | the database and everybody with access to it | the application and whoever controls it | queries cannot filter or join on the value; the application needs a key service |

Three rules come out of the table.

**Encrypt in transit and at rest everywhere, by default.** Both are cheap, both protect against
threats nobody can rule out, and the cost of being wrong is a breach notification (lesson 7). There
is no dataset for which "nobody will ever steal the disk" is a design decision.

**Encrypt individual values only where the threat is the people inside.** Application-level
encryption of a column means the column cannot be searched, sorted, joined or aggregated by the
database — a CPF encrypted that way can no longer find a customer by CPF without a second, keyed
column built for that (lesson 5's tokens are that column). It is right for the few values whose
exposure to a database administrator would itself be a breach, and wrong as a default.

**Every layer ends at a key, and the key decides who the layer really protects against.** A
volume encrypted with a key stored on the same disk protects against nobody; a backup encrypted
with a key in the same bucket protects against nobody; a column encrypted with a key in the query
protects against nobody who can read a log. Where keys live, who can use them and how they are
changed is the whole of lesson 4.
