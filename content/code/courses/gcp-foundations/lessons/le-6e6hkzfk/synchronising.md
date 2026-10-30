---
title: When the people already live in another directory
version: 1
---

**Most companies have a directory before they have Google Cloud**: Microsoft Active Directory on the
premises, Microsoft Entra ID, Okta, or something similar. Nobody wants to maintain the same people twice,
so the question is how Google Cloud learns about people who already exist elsewhere. There are three
answers, and they differ in **where the accounts live** and **where the password is checked**.

| | accounts live in | password checked by | typical tool |
|---|---|---|---|
| **synchronise** | Cloud Identity, as copies | Google, or the other directory via single sign-on | Google Cloud Directory Sync, or the provider's own provisioning |
| **single sign-on** on top of synchronising | Cloud Identity, as copies | the other directory, through SAML or OIDC | Entra ID or Okta as the identity provider |
| **workforce identity federation** | the other directory only | the other directory | a workforce pool on the organisation |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-three-ways\" aria-label=\"Three ways a company's existing directory reaches Google Cloud, one per row. Synchronise: GCDS copies users and groups one way into Cloud Identity, and Google checks the password. Synchronise with single sign-on: the same copies, but the password is checked by the company's identity provider. Workforce identity federation: no copies at all; a workforce pool trusts the company's identity provider directly.\"><defs><marker id=\"l10-three-ways-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-three-ways-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"20.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">synchronise</text><rect x=\"20.0\" y=\"54.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">company directory</text><rect x=\"500.0\" y=\"54.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cloud Identity copies</text><path d=\"M192.0 71.0 L496.0 71.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-three-ways-af-ah-paper)\"></path><text x=\"344.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one way</text><text x=\"344.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">password: Google</text><text x=\"20.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">synchronise + single sign-on</text><rect x=\"20.0\" y=\"126.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">company directory</text><rect x=\"500.0\" y=\"126.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cloud Identity copies</text><path d=\"M192.0 143.0 L496.0 143.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-three-ways-af-ah-paper)\"></path><text x=\"344.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one way</text><text x=\"344.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">password: the company's provider</text><text x=\"20.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">workforce identity federation</text><rect x=\"20.0\" y=\"198.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">company directory</text><rect x=\"500.0\" y=\"198.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a workforce pool</text><path d=\"M496.0 215.0 L192.0 215.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-three-ways-af-ah-amber)\"></path><text x=\"344.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">trusts</text><text x=\"344.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no copies; trusted directly</text></svg>", "caption": "Copy the people in, sign in through them, or trust them where they are."}
```

## Synchronising, and single sign-on on top

**Google Cloud Directory Sync**, GCDS, is a program Google provides that reads an LDAP directory such as
Active Directory and creates, updates and suspends the matching users and groups in Cloud Identity. It runs
**one way**, from the company's directory to Google's, so the company's directory stays the source of truth.
Entra ID and Okta do the same job with their own provisioning connectors.

Synchronising copies the accounts; it does not decide where people type their password. Adding **single
sign-on**, a SAML or OIDC profile in Cloud Identity that points at the company's identity provider, sends the
sign-in there: Ana types her password into Entra ID, Entra ID tells Google who she is, and Google Cloud sees
`ana@example.com` as usual. This is the most common arrangement in companies that came to Google Cloud with
a directory of their own, and its strength is that **a disabled account in the company's directory is a
disabled account everywhere**, as long as the sync runs.

## Workforce identity federation

The third answer skips the copies. A **workforce pool**, on the organisation, trusts the company's identity
provider directly, the way lesson 9's workload pool trusts GitHub, and people sign in as
`principal://iam.googleapis.com/locations/global/workforcePools/staff/subject/ana@example.com`. Nothing is
synchronised and no Cloud Identity account exists for them.

It fits a company that wants Google Cloud and nothing else from Google, and does not want a second copy of
its directory. It has costs a team should know before choosing it: grants name the long `principal://` and
`principalSet://` forms of lesson 5 rather than `user:` and `group:`, and some Google Cloud products, mostly
the ones that grew from Workspace, do not accept federated identities at all. **Google's documentation keeps
a list of the products that do, and it is the page to read before deciding.**

## Choosing

For the planner company, which signs in with Entra ID and uses Google Cloud only for the planner, both
synchronise-plus-single-sign-on and a workforce pool would work. The deciding question is usually which
other Google products the company will use: if it will one day use Google Workspace, Looker or another
product that needs Cloud Identity accounts, synchronising now avoids a migration later.

Nothing in this lesson ran: GCDS, single sign-on and workforce pools all need a real directory on both sides.
