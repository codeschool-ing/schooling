---
title: Two questions at the door
version: 1
---

Every request to a database answers two questions, and most of the confusion about access comes
from treating them as one.

**Authentication asks who you are.** A password, a certificate, the operating system vouching for
the user who opened the socket, a token from a company's identity provider. It is answered once,
when the connection opens, and the answer is a name: from then on the session *is* that role.

**Authorisation asks what that name may do.** Whether `bruno` may read `sales.customers`, insert
into `support.tickets`, see the `cpf` column, or see the rows of customers in a state other than
his own. It is asked again on every statement, against privileges stored in the database itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l1-two-gates\" aria-label=\"A connection to PostgreSQL passes two gates. The first, pg_hba.conf with the authentication method, decides who you are and whether you may connect at all. The second, the privileges inside the database, decides what that role may do with each object.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"120.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a client</text><text x=\"80.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">psql -U bruno</text><rect x=\"180.0\" y=\"30.0\" width=\"220.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · authentication</text><text x=\"290.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">who are you?</text><rect x=\"200.0\" y=\"96.0\" width=\"180.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg_hba.conf</text><rect x=\"200.0\" y=\"146.0\" width=\"180.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">peer · scram · cert</text><rect x=\"440.0\" y=\"30.0\" width=\"260.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · authorisation</text><text x=\"570.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what may this role do?</text><rect x=\"460.0\" y=\"96.0\" width=\"220.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CONNECT · USAGE · SELECT</text><rect x=\"460.0\" y=\"146.0\" width=\"220.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">asked on every statement</text><path d=\"M140.0 115.0 L178.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M400.0 115.0 L438.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path></svg>", "caption": "Authentication is answered once, at the door; authorisation is asked again on every statement."}
```

The two fail differently, and the failure tells you which one you are looking at. Ana's first
attempt to use the lab, before any role exists for her:

```
ana@lab:~/gov$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  role "ana" does not exist
```

That is the first gate: the server does not know who `ana` is, so there is nothing to
authorise. The other gate sounds like this, from a session that got in:

```
ERROR:  permission denied for schema sales
```

The connection worked. The statement did not. Section 15 of this lesson produces that line, and
lesson 2 is entirely about the second gate.

## Why the difference matters for data

**Authentication without authorisation gives everybody who logs in everything.** That is the most
common state of a company's first database: one shared account, used by the website, the
analysts and the nightly job, with every privilege there is. Nobody can say who read the
prescriptions table last month, because "who" is one name for twenty people and three programs.

**Authorisation without authentication is worse, because it looks finished.** A careful set of
grants on a role whose password is in a spreadsheet, or a `trust` line in the configuration that
lets anybody on the network claim any name, protects nothing: the grants are checked against a
name somebody chose.

So a data platform needs both, and needs each one to say something true. A role should be one
person or one program, so that what it did can be attributed. And the method that proves the name
should be strong enough that the name means something.

## Where each gate lives in PostgreSQL

| | authentication | authorisation |
|---|---|---|
| configured in | `pg_hba.conf`, a file on the server | `GRANT`, `REVOKE` and policies, inside the database |
| decided | once, when the connection opens | on every statement |
| fails with | `FATAL` and the connection closes | `ERROR` and the session goes on |
| this course | lesson 1, and certificates in lesson 3 | lessons 2 and 5 |

The rest of this lesson is the first gate: the roles that hold the names, the file that decides
how each name is proved, and the log that says who came in.
