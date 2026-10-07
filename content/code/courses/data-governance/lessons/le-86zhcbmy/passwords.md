---
title: A password the server never sees
version: 1
---

The obvious way to give somebody a password is a statement, `ALTER ROLE … PASSWORD '…'`. **It
works, and it is the wrong way**, and the server's log shows why. Many teams set
`log_statement = 'ddl'`, precisely so that every change to the schema is recorded. Ana turns it on
and sets `lia`'s password the obvious way:

```sql
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo -u postgres psql < logddl.sql
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -c "ALTER ROLE lia PASSWORD 'lab-lia-2026'"
ALTER ROLE
ana@lab:~/gov$ sudo grep PASSWORD /var/log/postgresql/postgresql-16-gov.log
2026-10-07 02:09:23.078 -03 [1191] ana@ipe LOG:  statement: ALTER ROLE lia PASSWORD 'lab-lia-2026'
```

The password is in the server's log, in clear, with the date and the name of the person who set
it. It is also in `~/.psql_history` on the machine it was typed on. A password that has been in
two files nobody thinks of as secret is a password with an unknown number of copies — so Ana
turns the setting back off, deletes her history and changes `lia`'s password again, properly:

```sh
sudo -u postgres psql -c "ALTER SYSTEM RESET log_statement" -c "SELECT pg_reload_conf()"
rm -f ~/.psql_history
```

psql has a command for this instead:

```
ana@lab:~/gov$ psql -c "\password bruno"
Enter new password for user "bruno": 
Enter it again: 
```

The prompts read the password from the terminal without echoing it. Then psql does something the
statement above cannot: **it computes the stored form on the client and sends that**, so the
password itself never crosses the connection and never reaches a log.

## What the server keeps

Only the superuser can read the stored form, from the catalogue table `pg_authid`:

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe -c "SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'bruno'"
 rolname |                                                              rolpassword                                                              
---------+---------------------------------------------------------------------------------------------------------------------------------------
 bruno   | SCRAM-SHA-256$4096:EGrxBzlETsmbu22MLvwfLQ==$1EMHD/y93uf78xrPPMD1C7s0PFXIgVTT+HSGmnvYzZU=:1jL0rJ3JwmEHj4BYh3284xBKyjOdZYoV87iW085CPp0=
(1 row)
```

That string is a **SCRAM-SHA-256 verifier**, and it is worth reading once, field by field:

| part | what it is |
|---|---|
| `SCRAM-SHA-256` | the method, so the server knows how to check against it |
| `4096` | the iteration count: how many times the password was hashed to make it slow to guess |
| the first base64 field | the **salt**, random per password, so two people with the same password store different strings |
| the two after the `$` | a **stored key** and a **server key**, derived from the salted, iterated password |

What is not there is the password, or anything from which it can be computed quickly. Somebody who
steals a backup of `pg_authid` has to guess passwords one at a time, 4,096 hashes per guess, per
role. That is slow enough to make a long password safe and not slow enough to save a short one,
which is why length matters more than the rules about symbols.

**SCRAM also never sends the password when Bruno logs in.** The client proves it knows the
password by answering a challenge, and the server proves it holds the verifier. A program
listening on the wire learns neither. The older method, `md5`, stored a hash that was itself
enough to log in with, and since PostgreSQL 14 the default for new passwords is
`password_encryption = scram-sha-256`. A cluster upgraded from an older one may still hold `md5`
hashes: the query above, run over every role, is how you find them, because a stored value
starting `md5` is one.

Bruno's password in the lab is `lab-bruno-2026`. The other five roles get theirs the same way,
unechoed, on the same pattern: `lab-carla-2026`, `lab-davi-2026`, `lab-lia-2026`, `lab-site-2026`
for `site_app` and `lab-etl-2026` for `etl_loader`. Ana's password file, which section 11 sets up,
keeps them all. In a real company each one is known to exactly one person or one program.