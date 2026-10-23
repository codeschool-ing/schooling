---
title: Who registered the domain, and when
version: 1
---

**Every domain name has a registration record**: when it was created, through which registrar, and,
less and less often, by whom. For a link in a suspicious message, the most useful line in that record is
the **creation date**. A domain registered last week and already sending payment slips to Jatobá's
clients is the shape of the lookalike domains lesson 14 blocked.

## WHOIS and RDAP

The old protocol for asking is **WHOIS**, plain text on port 43, with a different format for every
registry. Its replacement is **RDAP**, the Registration Data Access Protocol, which answers the same
questions over HTTPS in structured JSON, so a script can read the dates without guessing at a layout.
ICANN has required RDAP from the registries and registrars it accredits, and most clients now prefer it.

Neither was reached for this course: the lab has no internet, and the `whois` client is not among the
lab's packages. These are the documented forms, shown so you can run them on a computer that has both.
They were not run here, and no output is shown:

```sh
whois example.com
curl -s https://rdap.org/domain/example.com
```

`rdap.org` is a public service that sends each query to the registry responsible for the domain. In
the JSON that comes back, the `events` list holds the `registration` and `expiration` dates, and
`entities` holds the registrar.

## Reading the record

| what you see | what it suggests |
|---|---|
| created in the last few weeks | new domains are cheap and disposable, which is why phishing uses them; many reputation feeds of lesson 14 list them for that reason |
| a name one letter away from the firm's own, or a client's | a lookalike, whatever its age |
| the registrant hidden | ordinary since data-protection laws, GDPR and the LGPD among them; not a signal on its own |
| expiry within a year | ordinary for a domain nobody intends to keep |

**No single line convicts a domain.** A new domain can belong to a new, honest business, and an old one
can be taken over. Age, resemblance to a name you trust, and what urlscan saw the page do, read
together, are the evidence, and the decision they support is lesson 14's: whether the name goes on the
list.

## What this lesson adds to the others

Every tool in this lesson turns one suspicious thing into **indicators**: a hash, a domain, an address,
a technique. Those are what the controls of the earlier lessons consume.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l19-indicators\" aria-label=\"One suspicious file on the left becomes four kinds of indicator in the middle: a hash, a domain, an address and a technique. Each goes to a control of an earlier lesson on the right: the hash to antivirus signatures in lesson 7 and hunting in lesson 8, the domain to the resolver's blocklist in lesson 14, the address to firewall rules in lesson 10, the technique to detection rules in lesson 8.\"><defs><marker id=\"l19-indicators-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-indicators-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"100.0\" width=\"140.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one file</text><text x=\"90.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fatura-outubro.pdf</text><rect x=\"260.0\" y=\"30.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hash</text><path d=\"M160.0 125.0 L260.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 48.0 L440.0 48.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">signatures, lesson 7; hunting, lesson 8</text><rect x=\"260.0\" y=\"85.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">domain</text><path d=\"M160.0 125.0 L260.0 103.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 103.0 L440.0 103.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resolver blocklist, lesson 14</text><rect x=\"260.0\" y=\"140.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">address</text><path d=\"M160.0 125.0 L260.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 158.0 L440.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">outbound rules, lesson 10</text><rect x=\"260.0\" y=\"195.0\" width=\"120.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">technique</text><path d=\"M160.0 125.0 L260.0 213.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-paper-dim)\"></path><path d=\"M380.0 213.0 L440.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-indicators-dh-ah-phosphor)\"></path><text x=\"448.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">detection rules, lesson 8</text></svg>", "caption": "Analysis is worth what it feeds into the controls."}
```

The skill is less in using the services than in using them in the right order, keeping the firm's data out of them, and writing
down what they said and when.
