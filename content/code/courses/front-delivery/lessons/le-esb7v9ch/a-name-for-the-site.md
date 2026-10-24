---
title: A name for the site
version: 1
---

**A custom domain is two things: a name you rent from a registrar, and DNS records that say where that
name points.** The host does not need to be told the name exists; it needs to be told the name is yours,
and the name's records need to point at the host. Web-fundamentals lesson 8 took DNS apart; this section
uses it.

None of this section was run for this course: it needs a domain, which costs money every year and is the
student's to own. The records are the part that lasts, and they are the same wherever you buy the name.

## Two records

A site usually answers on two names: the bare domain, `example.com`, called the **apex**, and
`www.example.com`. Each gets a record, and the two are different kinds:

| name | record | value | means |
|---|---|---|---|
| `www.example.com` | `CNAME` | the name the host gave you, such as `planner.pages.dev` | "this name is another name; ask that one" |
| `example.com` | `A` (and `AAAA` for IPv6) | the addresses the host's documentation lists | "this name is at these addresses" |

**The apex cannot be a `CNAME`.** The DNS standard forbids a `CNAME` beside any other record of the same
name, and the apex always has others: the `SOA` and `NS` records that make the zone exist, the `MX` that
receives its mail. So `www` can say "I am `planner.pages.dev`", and the apex has to say an address. That
rule catches everybody the first time, because the dashboard happily lets you type a `CNAME` for `@`, the
symbol many DNS providers use for the apex, and then refuses it or quietly breaks the mail.

Providers work around it in three ways, and you will meet each name:

- **`A` records to the host's fixed addresses**, which is what GitHub Pages and Vercel document for an
  apex. It works anywhere, and breaks if the host ever changes those addresses.
- **`ALIAS` or `ANAME`**, a record some DNS providers offer that behaves like a `CNAME` but answers with
  addresses, so it may sit at the apex. It is not part of the standard; each provider implements its own.
- **CNAME flattening**, Cloudflare's name for the same idea, applied automatically at the apex when
  Cloudflare runs the domain's DNS.

## How long a change takes

Every record carries a **TTL**, time to live, in seconds: how long a resolver may keep the answer before
asking again. A record with a TTL of 3600 can be served from somebody's cache for an hour after you
change it. Lower it to a few minutes a day before a move, make the change, and raise it again once the
site works at its new home. "DNS takes 48 hours to propagate" is folklore: a change takes as long as the
old TTL says, and the 48 hours come from TTLs nobody lowered.

## And the host's side

Each host has a screen where you add the domain to the project, and then tells you which records to
create, with its own values. Do what that screen says, not what a tutorial from last year says: the
addresses for an apex are exactly the kind of value that changes. GitHub Pages also wants the domain in
a file called `CNAME` at the root of the published folder, or set in the repository's Pages settings,
which writes that file for you.
