---
title: Proving the domain is yours, and the record you leave behind
version: 1
---

**A host serves a site under a domain only after the owner of the domain has proved it, usually with a
DNS record only the owner could have created.** Pointing a record at the host is not proof enough by
itself, because the danger runs the other way as well: a name you control pointing at a host where you
no longer have a site.

## Verification

The host shows a value, usually a random string, and asks for a `TXT` record holding it, under the domain
or under a name such as `_vercel.example.com` or `_github-pages-challenge-<user>.example.com`. The host
then looks the record up. Only someone who controls the domain's DNS can make that lookup answer, so the
lookup is the proof. Some hosts accept the `CNAME` pointing at them as the proof instead, and ask for a
`TXT` record only when another account has already claimed the domain.

Leave the `TXT` record in place after verification. GitHub's documentation describes what verification
is for in exactly this lesson's terms: it stops other users from taking the domain over when a repository
is deleted or Pages is switched off while the domain still points there.

## The record you leave behind

This is where most real incidents with custom domains come from, and it happens after the work is done.
A team deletes the site on the host, the project or the preview, and forgets the DNS record:
`docs.example.com` still has a `CNAME` to `example-docs.pages.dev`, which is now nobody's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Before: docs.example.com has a CNAME to example-docs.pages.dev, which is the team&#x27;s project. After the project is deleted, the CNAME is still there and points at a name nobody owns. Anybody who creates a project with that name now serves pages under docs.example.com.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">before</text><rect x=\"20\" y=\"42\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">docs.example.com</text><line x1=\"210\" y1=\"62\" x2=\"300\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,62.0 292.6,65.1 292.6,58.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"255\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"302\" y=\"42\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">example-docs.pages.dev</text><text x=\"530\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">your project</text><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after the project is deleted</text><rect x=\"20\" y=\"132\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">docs.example.com</text><line x1=\"210\" y1=\"152\" x2=\"300\" y2=\"152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,152.0 292.6,155.1 292.6,148.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"255\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"302\" y=\"132\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"407\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">example-docs.pages.dev</text><text x=\"530\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nobody's, until somebody claims it</text></svg>", "caption": "A record left pointing at a deleted site lends your domain to whoever takes the name next; delete the record first."}
```

**Anybody who can create a project with that name on that host can now serve pages under
`docs.example.com`**: your domain, your users' trust, sometimes your cookies. It is called a **subdomain
takeover**, and the defence is entirely on your side:

- **delete the DNS record first, the site second.** A record pointing at nothing of yours is the hazard;
  a site with no record pointing at it is harmless.
- **keep the domain verified at the host**, which is what verification records exist for: a verified
  domain cannot be attached to somebody else's project on that host.
- **review the zone now and then**: every `CNAME` should point at something your organisation still runs.
  A list of records nobody can explain is the list a takeover starts from.

## What you can check without a domain

On your own computer, a name can point at your own machine without any DNS at all, which is what the
rest of this lesson does: `planner.test` is a name that exists only in the commands that use it. The
`.test` domain is reserved by RFC 2606 so that it never exists on the internet, which makes it safe for
exactly this.
