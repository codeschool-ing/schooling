---
title: Six record types, and what each one answers
version: 1
---

The authoritative servers at the end of the last reading hold a set of **records** for the domain.
Each record is a name, a type, and a value, and the type decides what question it answers.

There are dozens. Six carry almost all of the work.

| type | answers | value |
|---|---|---|
| `A` | what IPv4 address? | `203.0.113.7` |
| `AAAA` | what IPv6 address? | `2001:db8::7` |
| `CNAME` | what other name should I ask about? | `target.example.net` |
| `MX` | where does mail for this domain go? | a priority and a name |
| `TXT` | free text, for whoever wants it | any string |
| `NS` | which servers are authoritative here? | a name |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A set of records for one domain: two address records, an alias for the documentation, two mail records with priorities, a text record for verification, and the two nameserver records that are the delegation itself.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. A 203.0.113.7</text> <text x=\"470\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the site, on IPv4</text> <rect x=\"20\" y=\"70\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. AAAA 2001:db8::7</text> <text x=\"470\" y=\"87\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the same site, on IPv6</text> <rect x=\"20\" y=\"110\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docs.example.com. CNAME pages.provider.net.</text> <text x=\"470\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">go and ask about that one</text> <rect x=\"20\" y=\"150\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. MX 10 mail1.provider.net.</text> <text x=\"470\" y=\"167\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lower number, tried first</text> <rect x=\"20\" y=\"190\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. TXT \"v=spf1 include:provider.net ~all\"</text> <text x=\"560\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">who may send</text> <rect x=\"20\" y=\"230\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"34\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. NS ns1.dnsprovider.net.</text> <text x=\"470\" y=\"247\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the delegation itself</text> <text x=\"360\" y=\"282\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one domain, six lines, five different destinations — and not one of them is a server of yours</text> </svg>", "caption": "A name, a type and a value. The type is the whole of what decides which question it answers."}
```

## The two address records

`A` gives an IPv4 address; `AAAA` gives an IPv6 one. The name is not an abbreviation of anything
interesting — an IPv6 address is four times the size of an IPv4 one, so four `A`s.

A name can have both, and should. A name can also have several of each, and a resolver hands them
out in varying order, which is the oldest and crudest way of spreading traffic over several
machines. It has no idea whether any of them is alive, which is why it is a way of sharing load and
not a way of surviving a failure.

## `CNAME`, and the two rules that catch everybody

A `CNAME` says *this name is another name for that one; go and ask again*. It is how you point at
something whose address you do not control and which may change without telling you — a hosting
provider, a CDN, a documentation service.

Two rules, and both produce confusing failures.

**A name with a `CNAME` may have no other records.** Not an `MX`, not a `TXT`, nothing. The alias
replaces the name entirely, so anything else at that name is either ignored or refused depending on
who you ask.

**The bare domain cannot have one**, because the bare domain must carry `NS` records and — by the
rule above — a `CNAME` cannot sit beside them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A CNAME may not sit at the bare domain, because the bare domain has to carry the nameserver records and a CNAME may not share a name with anything. On a subdomain it is fine.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">at the bare domain</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. NS ns1...</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com. CNAME ...</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">refused: an alias shares with nothing</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">on a subdomain</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docs.example.com. CNAME ...</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nothing else is at that name</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">accepted, and it is the usual way</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">this is why so much hosting documentation quietly insists on www</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and why providers invented ALIAS and flattening, which are theirs rather than the standard's</text> </svg>", "caption": "Two rules with one consequence: the bare domain is the one name you cannot point at a name."}
```

That second rule is the reason so much hosting documentation asks you to use `www`. It is also why
providers invented non-standard record types — `ALIAS`, `ANAME`, or a feature called flattening —
which behave like a `CNAME` at the bare domain by resolving the target themselves and answering
with an address. They work, they are not part of the specification, and they only exist where your
DNS provider offers them.

## `MX`, where mail goes

Mail does not use the address records. A message for `you@example.com` is delivered by looking up
the `MX` records of `example.com`.

```
example.com.  MX  10 mail1.provider.net.
example.com.  MX  20 mail2.provider.net.
```

The number is a priority, and **lower is preferred**. A sender tries 10 first and falls back to 20,
which is how a backup mail server is expressed.

Two mistakes are common enough to name. An `MX` names a **server, not an address** — putting an
address there fails. And the name it points at must not itself be a `CNAME`, which is a rule people
break precisely because a `CNAME` seems like the tidy way to do it.

## `TXT`, which became the one that matters most

`TXT` was a place to put a note. It became the general-purpose mechanism for proving you control a
domain and for saying things about your mail.

Everything that asks you to *verify your domain* — a certificate authority, a mail provider, an
analytics service — does it by telling you to publish a string they gave you. Publishing it proves
you control the records, which proves you control the domain.

And three arrangements that decide whether your mail is believed all live here:

**SPF** lists the servers allowed to send mail claiming to be from you. **DKIM** publishes a key
that signs your outgoing messages, so a recipient can check they were not altered. **DMARC** says
what a recipient should do when a message fails the first two, and where to send a report about it.

They deserve a lesson of their own and they earn their line here for one reason: **a domain with
nothing in these records is a domain anybody can send mail as.** It is the most consequential empty
setting in this entire lesson.

## `NS`, which is the delegation itself

The `NS` records name the servers that are authoritative for this domain. They are the thing the
TLD servers hand back during the walk, and changing them is what *changing nameservers* means in a
control panel.

It is also the one change in this lesson that moves everything at once: point your `NS` records at
a new DNS provider and all your records change to whatever is in that provider's account, including
records that are not there. The usual failure is mail stopping, because the `MX` records were on
the old provider and nobody copied them across.

## Three more worth recognising

Not everything, and these appear often enough that a blank look is a cost.

`CAA` names which certificate authorities may issue certificates for your domain. It closes a real
hole in the padlock of lesson six: without it, any authority in the browser's list may issue for
your name.

`SRV` gives a service, a protocol, a priority, a weight, a port and a host. It is the general
answer to *where does this service live*, and you meet it in chat systems and internal tooling more
than on the public web.

`PTR` maps an address back to a name — the reverse lookup. You rarely set one, and a mail server
that has no reverse name is a mail server whose messages get filed as spam, which is how most
people first hear of it.
