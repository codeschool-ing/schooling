---
title: On the internet: a domain and a free tier
version: 1
---

Moving from the lab to the internet changes three things, and none of them is the application.

**A domain.** A name you register, which costs a small yearly fee at any registrar, and a DNS record
that points it at your server: an `A` record to the server's IPv4 address, or a `CNAME` to a name the
host gives you. Subdomains of a domain you already have are free, and a portfolio needs only one.

**A real certificate.** With a public name, Caddy obtains the certificate from a public authority by
itself, so the Caddyfile loses its `tls internal` line:

```
loans.example.org {
	reverse_proxy 127.0.0.1:8000
}
```

This file was **not run in this course**; the lab has no public name. It is the whole difference, and
Caddy needs ports 80 and 443 reachable from the internet to prove it controls the name.

**Somewhere to run.** Free tiers exist for small virtual machines, for containers and for static sites,
and they change: providers add, shrink and withdraw them, which is why this lesson names none and quotes
no limits. Before choosing one, check five things on the provider's own current pages:

- **whether it sleeps** when idle, so the first visit is slow;
- **whether it expires** after a trial period;
- **whether it needs a card**, and what happens when a limit is crossed;
- **where the data lives**, if the free tier has no persistent disk;
- **how you leave**, since a portfolio outlives most free tiers.

And keep the lab. **A recorded deploy is evidence that does not expire**: if the free tier disappears
the week before an interview, the transcript of this lesson, run on your own project, still shows a
reviewer everything the address would have.
