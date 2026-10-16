---
title: Workforce identity, and where a person's login should live
version: 1
---

**People sign in once, to IAM Identity Center, and reach every account they are allowed into as a
role for a few hours.** No account holds a user for them and no laptop holds a key. Lesson 6 met
the IAM user, and lesson 12 explains why its access key is the last resort; this lesson is the
arrangement that replaces both for everybody who works at the shop.

The wrong picture is the one that grows by itself. The shop starts in one account, gives `bia` an
IAM user there, and then gets a second account. **Now `bia` has two users, two passwords, two MFA
devices and two keys**, and when she leaves somebody has to remember both. With six accounts, as
lesson 3 built, and five people, that is thirty users that each have to be created, audited and
deleted on the right day.

## Three pieces: an identity, a permission set, an assignment

Identity Center separates the three questions an IAM user answers all at once:

- who the person is lives in one **identity source**, outside every account;
- what a kind of access means is a **permission set**: a name, a session length and the
  policies, written once for the whole organisation;
- who gets which access where is an **account assignment**: a user or a group, a permission
  set, and one account.

When an assignment is made, Identity Center provisions the permission set into the account: it
creates a role there, named `AWSReservedSSO_<permission set>_<suffix>`, under the path
`/aws-reserved/sso.amazonaws.com/`, with the permission set's policies attached and a trust policy
that only Identity Center can satisfy. When `caio` opens `shop-prod` with `ReadOnly`, he is
assuming that role, and CloudTrail records `assumed-role/AWSReservedSSO_ReadOnly_…/caio`.
Change the permission set and Identity Center updates the role in every account that has it; delete
the assignment and the role stops accepting him.

Those roles are managed for you, and **nobody should edit them by hand**. An edit made inside one
account is overwritten the next time the permission set is provisioned, and until then that account
quietly disagrees with the others.

## The identity source, inside or outside AWS

Identity Center has exactly one identity source at a time, chosen when it is set up and
changeable later:

| identity source | where users and passwords live | when it fits |
|---|---|---|
| the **Identity Center directory** | inside Identity Center | a small team with no directory of its own |
| **Active Directory** | an AWS Managed Microsoft AD, or your own through a connector | a company already running AD |
| an **external identity provider** | Google Workspace, Microsoft Entra ID, Okta and others | a company whose people already sign in there for everything else |

The shop's people already have Google Workspace accounts for mail, so the shop's choice is the third
row. **Two protocols connect an external provider, and they do different jobs.**

**SAML 2.0 is the sign-in.** When `caio` opens the access portal, Identity Center sends his browser
to Google, Google checks his password and his second factor, and sends back a signed assertion that
says who he is. Identity Center trusts that assertion because the two sides exchanged certificates
when the provider was connected. No password ever reaches AWS.

**SCIM is the provisioning.** SAML says who is signing in at the moment they do; it cannot tell
Identity Center that a person exists before they arrive, which groups they belong to, or that they
have left. SCIM is an API that the identity provider calls to create, update and disable users and
groups in Identity Center as they change on its side. **Without SCIM, every change is made twice**:
a new person has to be created in Identity Center by hand before their first sign-in, and a person
removed from Google can no longer sign in but leaves their user, groups and assignments behind for
somebody to remember.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-federation\" aria-label=\"How a person reaches an account through Identity Center. Caio signs in, with his second factor, at the identity provider, Google Workspace. The provider talks to IAM Identity Center in two ways: SAML says who is signing in at that moment, and SCIM says ahead of time which users and groups exist. Identity Center provisions a role into each account an assignment names: AWSReservedSSO_ReadOnly in shop-prod, AWSReservedSSO_Developer in shop-staging, and so on. No account holds a user for him.\"><defs><marker id=\"l11-federation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-federation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-federation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"30.0\" width=\"150.0\" height=\"44.0\" rx=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">caio, in a browser</text><path d=\"M105.0 76.0 L105.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-phosphor)\"></path><text x=\"115.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">signs in, with MFA</text><rect x=\"30.0\" y=\"150.0\" width=\"150.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">identity provider</text><text x=\"105.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Google Workspace</text><rect x=\"280.0\" y=\"140.0\" width=\"170.0\" height=\"94.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">IAM Identity Center</text><text x=\"365.0\" y=\"195.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permission sets</text><text x=\"365.0\" y=\"208.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and assignments</text><path d=\"M182.0 166.0 L278.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-phosphor)\"></path><text x=\"230.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">SAML: who, now</text><path d=\"M182.0 210.0 L278.0 210.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-amber)\"></path><text x=\"230.0\" y=\"221.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">SCIM: who</text><text x=\"230.0\" y=\"234.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">exists</text><rect x=\"530.0\" y=\"28.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"615.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_ReadOnly_…</text><path d=\"M452.0 170.3 L527.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"128.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"615.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_Developer_…</text><path d=\"M452.0 187.0 L527.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"228.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sandbox</text><text x=\"615.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_…</text><path d=\"M452.0 203.7 L527.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><text x=\"365.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">provisions one role per</text><text x=\"365.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">assigned account</text><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no account holds a user for a person</text></svg>", "caption": "The person lives at the identity provider; the accounts hold only roles that Identity Center manages."}
```

None of this was run. **Connecting a real identity provider needs a real Identity Center, a real
directory and a browser**, and moto has none of the three; the description is AWS's documented
arrangement. What moto does have is the Identity Center side of it, the permission sets, users,
groups and assignments, and the next section builds them.

## Why a short session beats a user with a key

For a person, the Identity Center session wins on every count that matters when something goes
wrong:

- **it expires on its own.** The permission set in the next section asks for four hours; a key
  works until somebody deletes it, and lesson 12 reads key ages out of the credential report;
- **it inherits the second factor.** Every session starts at the identity provider, where MFA is
  enforced once for everything, rather than per user in every account;
- **leaving is one action.** Disabling the person in Google refuses every sign-in after it, SCIM
  carries the removal across, and sessions already open run out within their duration;
- **the record names the person.** The role's session carries the user's name, so an audit reads
  `caio` and not a shared user.

What is left for IAM users is the short list lesson 12 ends with: a program that runs outside AWS
and cannot use any of the mechanisms of lesson 10, and the account's emergency access. **People are
not on that list.**

The access portal is the page where a person who signed in sees the accounts and permission
sets assigned to them, and opens the console in one, or copies short-lived credentials for the
command line. Its address is `https://<something>.awsapps.com/start`, shown in Identity Center's
settings, and the last section of this lesson points the command line at it.
