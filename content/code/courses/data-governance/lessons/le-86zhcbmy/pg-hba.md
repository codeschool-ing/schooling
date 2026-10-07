---
title: pg_hba.conf, the file at the door
version: 1
---

Bruno has a password now, and still cannot get in. Ana tries it from her own account, through
the server's local socket:

```
ana@lab:~/gov$ psql -U bruno
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  Peer authentication failed for user "bruno"
```

**`peer` is a method that does not ask for a password at all.** It asks the operating system which
user is on the other end of the socket, and lets that user in as the role with the same name.
Ana's operating-system user is `ana`, she asked to be `bruno`, and the two do not match. For a
person logged in to the database server itself, `peer` is the strongest method there is: there is
no secret to steal, because the kernel is the witness.

Which method applies to which connection is the job of one file, `pg_hba.conf` — *host-based
authentication*. Ubuntu ships the cluster with this one:

```
ana@lab:~/gov$ sudo grep -v -e '^#' -e '^$' /etc/postgresql/16/gov/pg_hba.conf
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

Each line is a rule with five columns: the **type** of connection (`local` for the socket, `host`
for TCP), the **database**, the **user**, the client's **address** for TCP, and the **method**.
Read as policy, Ubuntu's default says: on this machine, anybody may be the role named after them;
over TCP from this machine, anybody with the password may be anybody; and the same for
replication. It is a sensible default for one person's laptop. It is not a policy for a company's
data.

## Ana's version

```conf
# TYPE  DATABASE  USER      ADDRESS        METHOD
local   all       postgres                 peer
local   ipe       ana                      peer
host    ipe       all       127.0.0.1/32   scram-sha-256
host    all       all       all            reject
```

Four lines, and each says something deliberate:

- **only `postgres` and `ana` may use the socket**, and only as themselves;
- **everybody else connects over TCP, to `ipe` only, with SCRAM** — so every other login is a
  password checked by the server, and the address on the line limits it to this machine;
- **anything not described above is refused**, by name, rather than left to fall off the end.

The last line is not decoration. A connection that matches no line is refused anyway, so `reject`
changes nothing about who gets in. What it changes is **the reason in the log**: "rejects
connection" says a rule refused it, where "no entry" can mean the file was edited wrongly. A file
that ends in an explicit refusal is one whose author thought about the end.

## First match wins

The server reads the file from the top and stops at the first line whose type, database, user
and address all match. **Nothing below that line is read.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l1-hba-first-match\" aria-label=\"pg_hba.conf is read from the top, and the first line whose type, database, user and address all match decides. A connection from bruno over TCP skips the two local lines and stops at line 4, scram-sha-256. Line 5 is never reached by him.\"><defs><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"95.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bruno, over TCP</text><text x=\"95.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">db.ipe.example</text><rect x=\"220.0\" y=\"30.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"258.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">local   all  postgres          peer</text><rect x=\"220.0\" y=\"80.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"258.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">local   ipe  ana               peer</text><rect x=\"220.0\" y=\"130.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"258.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper)\">host    ipe  all  127.0.0.1/32 scram-sha-256</text><rect x=\"220.0\" y=\"180.0\" width=\"470.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"238.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"258.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" xml:space=\"preserve\" fill=\"var(--paper-dim)\">host    all  all  all          reject</text><path d=\"M170.0 125.0 L218.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><text x=\"455.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lines 2 and 3 do not match: wrong type. Line 4 does, and decides.</text></svg>", "caption": "First match wins, and nothing below it is read. An order mistake is a security mistake."}
```

That makes order a security property. Swap lines 4 and 5 and every TCP login is refused; put a
`host all all 0.0.0.0/0 trust` line at the top during an emergency and every rule below it stops
existing, for everybody, until somebody remembers. The second is the classic one, because it
works and nobody notices.

The file is read when the server starts and when it is told to reload, not on every edit, so the
change is two steps:

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql -c "SELECT pg_reload_conf()"
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ sudo -u postgres psql -c "SELECT line_number, type, database, user_name, address, auth_method FROM pg_hba_file_rules"
 line_number | type  | database | user_name  |  address  |  auth_method  
-------------+-------+----------+------------+-----------+---------------
           2 | local | {all}    | {postgres} |           | peer
           3 | local | {ipe}    | {ana}      |           | peer
           4 | host  | {ipe}    | {all}      | 127.0.0.1 | scram-sha-256
           5 | host  | {all}    | {all}      | all       | reject
(4 rows)
```

`pg_hba_file_rules` is the server's own reading of the file, and **it is the thing to look at
after every edit**. A line with a typo appears there with an `error` column filled in, and the
server keeps using the last version it could parse — so a broken edit fails silently unless
somebody asks. Line 1, the comment, is not a rule; the four rules are 2 to 5.

Now Bruno through the socket meets a different refusal:

```
ana@lab:~/gov$ psql -U bruno
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "bruno", database "ipe", no encryption
```

No line describes `local`, `bruno`, `ipe`: he is meant to come over TCP, with a password.
