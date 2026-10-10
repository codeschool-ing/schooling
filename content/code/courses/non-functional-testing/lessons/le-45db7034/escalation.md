---
title: Two directions of escalation
version: 1
---

Lesson 1 wrote one of its requirements for this lesson: **one customer's token cannot read another
customer's booking**. It is the requirement a tester is asked about most, because the defect behind
it is the most common serious one on the web, and because no scanner finds it. Before testing it,
two words have to be kept apart, since people use them as if they were one.

**Authentication** answers *who are you?* A password checked against its hash, a token found in the
sessions table. **Authorisation** answers *are you allowed to do this?* — and it is asked again on
every request, about one particular thing. `account.py` does the first in `who` and the second in
the two lines marked `# owner check` and `# role check`. A system can authenticate perfectly and
still let everybody read everything, which is exactly what the box office of lesson 1 does.
`security-fundamentals` lesson 8 is the place to go deeper into the difference.

## Sideways and upwards

When authorisation fails, somebody gets a privilege they were never given, and the failure has a
direction.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-escalation\" aria-label=\"Two roles drawn as two levels. On the lower level, two customers, ana and bia, each with her own booking. On the upper level, staff, with the list of every booking. An arrow sideways from bia to ana's booking is horizontal escalation: the same role, somebody else's data, tested by account.py's owner check. An arrow upwards from ana to the staff list is vertical escalation: a role she does not have, tested by the role check. Both arrows must end in a refusal.\"><defs><marker id=\"l17-escalation-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">two directions, one rule: the answer is a refusal</text><rect x=\"40.0\" y=\"50.0\" width=\"640.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"56.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">staff</text><rect x=\"40.0\" y=\"160.0\" width=\"640.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"56.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">customer</text><rect x=\"140.0\" y=\"70.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/staff/bookings</text><rect x=\"110.0\" y=\"190.0\" width=\"90.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"155.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ana</text><rect x=\"220.0\" y=\"190.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">booking 1</text><rect x=\"500.0\" y=\"190.0\" width=\"90.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"545.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bia</text><path d=\"M500.0 207.0 L334.0 207.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l17-escalation-nf-ah-amber)\"></path><text x=\"417.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">horizontal</text><text x=\"417.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owner check: 404</text><path d=\"M155.0 190.0 L155.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l17-escalation-nf-ah-amber)\"></path><text x=\"166.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">vertical</text><text x=\"236.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role check: 403</text></svg>", "caption": "Horizontal escalation reaches another customer's data; vertical escalation reaches a role. Each is a probe with two accounts."}
```

- **Horizontal escalation** is reaching sideways: a customer reading, changing or cancelling
  another customer's booking. Same role, somebody else's data. It usually comes from a route that
  looks a record up by its id and never asks whose it is, and the usual probe is the one you are
  about to send: a second account asking for the first one's record.
- **Vertical escalation** is reaching upwards: a customer doing what only staff may do, such as
  listing every booking. Same data, a role they do not have. It usually comes from a staff page
  that is merely not linked from the customer screens, as if a missing link were a lock.

Both are tested the same way: **two accounts, one request, and an answer that must be a refusal.**

## Horizontal: two customers

Register three customers with the same `/register` request as in lesson 16: `ana`, `bia`, and
`sam` for later. Sign the first two in, keeping each token in a file named after its owner, book a
seat as `ana`, and ask for that booking with `bia`'s token:

```
ana@nft:~/boxoffice$ for n in ana bia sam; do curl -s -X POST localhost:8001/register -d "{\"name\": \"$n\", \"password\": \"correct horse battery\"}"; done
{"ok": true}
{"ok": true}
{"ok": true}
ana@nft:~/boxoffice$ for n in ana bia; do curl -s -X POST localhost:8001/login -d "{\"name\": \"$n\", \"password\": \"correct horse battery\"}" | jq -r .token > ~/$n.token; done
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 990, "seat": 12, "holder": "Ana Lima"}'
{"id": 1}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/2 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
```

`bia` is refused booking 1, which is `ana`'s, with a `404`. She is also refused booking 2, which
does not exist, **with exactly the same answer.** That is deliberate: a `403` for one and a `404`
for the other would tell a stranger which booking numbers are in use, and how many people have
booked. A refusal that looks like absence is a common and reasonable choice; a `403` for both is
the other one. What a test must not accept is a `200`.

## Vertical: a customer and a member of staff

`/staff/bookings` lists every booking, and only an account with the `staff` role may read it.
There is no route that grants the role, on purpose: making somebody staff is done at the database,
by whoever runs the service, which here is you. Ask as `ana`, then promote `sam` and ask as him:

```
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "staff only"}
403
ana@nft:~/boxoffice$ sqlite3 data/account.db "UPDATE accounts SET role = 'staff' WHERE name = 'sam'"
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "sam", "password": "correct horse battery"}' | jq -r .token > ~/sam.token
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H "Authorization: Bearer $(cat ~/sam.token)"
[{"id": 1, "owner": 1, "show_id": 990, "seat": 12}]
200
```

The `403` is the refusal; the `200` is the control. Without the control, a staff route broken for
everybody would pass a test that only checked customers were refused.

Both refusals also reached the service's log, with the account that asked:

```
2026-10-10 16:35:38,308 WARNING refused GET /bookings/1 to account 2: no such booking
2026-10-10 16:35:38,364 WARNING refused GET /staff/bookings to account 1: staff only
```

**A customer asking for booking after booking that is not theirs is the visible trace of somebody
looking for a horizontal escalation**, and it shows up here rather than nowhere. Lesson 19 comes
back to what a log line has to carry to be useful.
