---
title: Watching the door
version: 1
---

A refused login tells the client almost nothing, on purpose. The server keeps the reason, in its
own log, where only the people who run it can read it:

```
ana@lab:~/gov$ sudo grep DETAIL /var/log/postgresql/postgresql-16-gov.log
2026-10-06 23:46:05.049 -03 [9907] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 123: "local   all             all                                     peer"
2026-10-06 23:46:05.452 -03 [9992] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 4: "host    ipe       all       127.0.0.1/32   scram-sha-256"
2026-10-06 23:46:05.459 -03 [9993] bruno@ipe DETAIL:  Connection matched file "/etc/postgresql/16/gov/pg_hba.conf" line 4: "host    ipe       all       127.0.0.1/32   scram-sha-256"
2026-10-06 23:46:05.513 -03 [10000] nobody@ipe DETAIL:  Role "nobody" does not exist.
2026-10-06 23:46:05.519 -03 [10001] nobody@ipe DETAIL:  Role "nobody" does not exist.
2026-10-06 23:46:05.574 -03 [10008] lia@ipe DETAIL:  User "lia" has an expired password.
2026-10-06 23:46:05.580 -03 [10009] lia@ipe DETAIL:  User "lia" has an expired password.
```

Every refusal of this lesson so far is there, each network attempt twice, and the client saw
almost the same sentence for all of them:

- **The first line is Bruno at the socket**, in section 7, before Ana replaced the file. It
  matched line 123 of Ubuntu's default, the `peer` rule, and the operating-system user was wrong.
- **Bruno's wrong password** has no reason beyond the rule that matched: line 4 asked for a
  password, and the one offered did not fit.
- **`nobody`** does not exist, and the log says so in exactly those words.
- **Lia's** password expired: the control from section 9 doing its job, recorded.

The `Connection matched` detail names the rule in `pg_hba.conf` that decided. When a login fails
that should work, it is the line to read before anything else: it says which of your rules the
server thinks applies, which is often not the one you meant. For `nobody` and `lia` the same
detail is there too, on the line after the one `grep` printed.

## Recording who came in, too

Failures are logged by default. Successes are not, and a log of who was refused without a log of
who was let in answers only half of any question somebody will ask about access. One setting
changes that:

```
ana@lab:~/gov$ sudo -u postgres psql -c "ALTER SYSTEM SET log_connections = on" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -h db.ipe.example -U carla -c "SELECT 1" >/dev/null
ana@lab:~/gov$ sudo tail -n 2 /var/log/postgresql/postgresql-16-gov.log
2026-10-06 23:46:07.779 -03 [10047] carla@ipe LOG:  connection authenticated: identity="carla" method=scram-sha-256 (/etc/postgresql/16/gov/pg_hba.conf:4)
2026-10-06 23:46:07.779 -03 [10047] carla@ipe LOG:  connection authorized: user=carla database=ipe application_name=psql SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
```

`ALTER SYSTEM` writes the setting to `postgresql.auto.conf`, which overrides the main
configuration file, and the reload applies it without restarting. From now on every connection
leaves two lines: who it **authenticated** as and by which method and rule, and what it was
**authorised** to open — the database, the program that asked, and whether the connection was
encrypted.

That last part says `SSL enabled`, with a protocol and a cipher. **Carla's session was encrypted,
and nobody in this lesson configured encryption.** Ubuntu turns TLS on for every new cluster with
a certificate generated on the spot — one no client can verify, because nobody vouches for it.
Lesson 3 starts from exactly that line.

## What a log of the door is for

Three questions come up, sooner or later, and only a connection log answers them:

- **Is somebody guessing?** Dozens of failures for one role in a minute, or failures for roles
  that do not exist, from one address.
- **Is a service account being used by a person?** `etl_loader` connecting at two in the
  afternoon with `application_name=psql` is a person with the pipeline's password.
- **Did the person who left still get in?** A successful line for a role after the date it should
  have stopped.

None of them needs anything more than these lines and a `grep`. Lesson 10 adds the other half —
what a session did once it was in — with `pgaudit`. Both are only worth keeping if somebody reads
them, which is why the questions are written down before the log is.
