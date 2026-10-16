---
title: Probing production without hurting it
version: 1
---

Everything a probe does in production, it does for real. **Every booking it makes is a seat a
customer cannot buy**, every request is load, and every record it writes lands in the same tables
the business reads its sales from. A probe running once a minute books 1,440 seats a day. The box
office has twenty shows of 300 seats on sale; left alone, the probe sells out the first show within hours
and then fails every check, having caused the outage it reports.

## Marking test data, and cleaning it up

Three habits keep synthetic traffic from becoming a problem of its own.

**Mark it.** The probe books as `synthetic-probe`, a customer that no person is, so every row it
leaves can be found and every report can leave it out. Some teams send a header instead, such as
`X-Synthetic: 1`, and have the application tag the row; the mark has to reach the database either
way, because that is where the sales report reads.

**Give it somewhere harmless to write.** In a real box office the probe would book a show that is
never on public sale, a test event the operators agreed on, so it never takes a seat a person
wanted. boxoffice has no such show, which is why this probe books the first show on sale, and why
it must clean up after itself.

**Clean up, on a schedule of its own.** Every probe that writes needs a matching deletion, agreed
with whoever owns the data, run as often as the probe runs or soon after. boxoffice has no endpoint
to cancel a booking, so on this machine the cleanup is a statement against the database, in
`~/boxoffice`:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "SELECT show_id, seat, customer FROM bookings WHERE customer = 'synthetic-probe'"
981|190|synthetic-probe
981|6|synthetic-probe
981|30|synthetic-probe
981|175|synthetic-probe
981|236|synthetic-probe
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DELETE FROM bookings WHERE customer = 'synthetic-probe'; SELECT changes()"
5
```

Five bookings: one from the first run, three from the loop and one from the slow version, all on
show 981, all marked, all gone in one statement. **In production you would not type that at a
prompt**: it would be a reviewed job, or better an endpoint the application offers for its own test
customer, so that nobody needs write access to the sales table to tidy up after a monitor.

## From more than one place

A probe on the server's own machine proves the application answers. It says nothing about the DNS,
the certificate, the load balancer or the network between your customers and you, which is where
many real outages live. **Hosted synthetic services run the same check from several regions** —
São Paulo, Virginia, Frankfurt, Singapore — for that reason, and the pattern of failures says where
the problem is:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l23-regions\" aria-label=\"Two panels, each with three probes, São Paulo, Virginia and Frankfurt, sending a check to one service on the right. In the left panel all three checks fail: the problem is the service. In the right panel only the check from Frankfurt fails and the other two pass: the service is working, and the problem is on the path from Frankfurt.\"><defs><marker id=\"l23-regions-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-regions-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"185.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">all fail: the service</text><rect x=\"250.0\" y=\"110.0\" width=\"100.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"20.0\" y=\"54.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">São Paulo</text><path d=\"M132.0 70.0 L246.0 124.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fail</text><rect x=\"20.0\" y=\"124.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Virginia</text><path d=\"M132.0 140.0 L246.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fail</text><rect x=\"20.0\" y=\"194.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"75.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Frankfurt</text><path d=\"M132.0 210.0 L246.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"180.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fail</text><text x=\"535.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one fails: its path</text><rect x=\"600.0\" y=\"110.0\" width=\"100.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"370.0\" y=\"54.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">São Paulo</text><path d=\"M482.0 70.0 L596.0 124.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-regions-nf-ah-phosphor)\"></path><text x=\"530.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pass</text><rect x=\"370.0\" y=\"124.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Virginia</text><path d=\"M482.0 140.0 L596.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-regions-nf-ah-phosphor)\"></path><text x=\"530.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pass</text><rect x=\"370.0\" y=\"194.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"425.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Frankfurt</text><path d=\"M482.0 210.0 L596.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l23-regions-nf-ah-amber)\"></path><text x=\"530.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fail</text></svg>", "caption": "The same check from three places. Which ones fail says where to look."}
```

All regions failing points at the service. One region failing points at the path from that region:
a cloud provider's network, a DNS resolver, a routing change. That distinction is also why a single
failure from a single place should not wake anybody up.

## What a synthetic check cannot see

A probe only walks the journey somebody wrote. Real users take paths nobody scripted: the search
with an accent in it, the phone on a slow train, the browser extension that breaks the page, the
show that sells out while three hundred people are on its page at once. **A green probe means the
scripted path works, from the probe's location, at the probe's rate of one user.** It does not mean
the system works for the people using it, and lesson 24 is about the defects that only appear when
they do: an error rate that only rises under real traffic, which is what real-user metrics and the
server's own error ratio are for.

The two kinds of monitoring fail in opposite directions, which is why they are paired. A synthetic
check raises its alarm at 04:00 when nobody is affected yet; real-user data stays silent then, and
is the only one that notices when a tenth of customers on one browser cannot pay.
