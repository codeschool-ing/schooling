---
title: Where the token comes from
version: 1
---

**On Azure, the credential of a managed identity never reaches the program, because the program asks
the platform for a token instead of asking Entra ID.** The wrong picture is a hidden secret somewhere
on the machine that the code reads; there is none. What the machine has is an address that only it
can reach, and the answer at that address is a token Azure obtained on its behalf.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-imds\" aria-label=\"How code on an Azure virtual machine gets a token without holding a credential. Inside the virtual machine, the application asks the Instance Metadata Service at 169.254.169.254, which only that machine can reach. The platform, outside the machine, obtains a token from Entra ID for the machine's managed identity and hands it back. The application then calls the storage account with the token. No credential ever enters the machine.\"><defs><marker id=\"l08-imds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-imds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l08-imds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the virtual machine</text><text x=\"605.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outside it</text><rect x=\"50.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the application</text><rect x=\"290.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">metadata service</text><text x=\"375.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">169.254.169.254</text><rect x=\"520.0\" y=\"70.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Entra ID</text><rect x=\"520.0\" y=\"180.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stshopassetsprod</text><path d=\"M221.0 88.0 L289.0 88.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-amber)\"></path><path d=\"M461.0 88.0 L519.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-paper-dim)\"></path><path d=\"M519.0 104.0 L461.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-paper-dim)\"></path><path d=\"M289.0 104.0 L221.0 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-amber)\"></path><text x=\"255.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 ask, 4 token</text><text x=\"490.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2, 3 the platform signs in</text><path d=\"M135.0 121.0 L135.0 205.0 L519.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-imds-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">5 the call, with the token</text></svg>", "caption": "The credential stays with the platform; only a token reaches the application."}
```

On a virtual machine the address is the **Instance Metadata Service**, IMDS for short, at
`169.254.169.254`. That address is **link-local**: it is never routed off the host, so it means "the
platform under this machine" on every Azure VM, and a request to it never crosses a network. A program
asks it for a token with an ordinary HTTP request:

| part | value | why |
|---|---|---|
| address | `http://169.254.169.254/metadata/identity/oauth2/token` | plain HTTP is enough: the request never leaves the host |
| `api-version` | `2018-02-01` | every Azure API takes a version, lesson 25 |
| `resource` | `https://management.azure.com/` | which API the token is for, as in lesson 7's scope |
| `client_id` | the user-assigned identity's client id | which identity, when the machine has more than one |
| header `Metadata: true` | required | a request without it is refused, which stops a page that tricks a server into fetching a URL from fetching this one |

The answer is JSON with an `access_token` and its expiry, and **the platform renews and caches it**:
asking again a minute later returns the same token, not a new sign-in. App Service, Functions and
Container Apps give the same service at an address of their own, which they put in two environment
variables of the application, `IDENTITY_ENDPOINT` and `IDENTITY_HEADER`.

**None of this was run.** The lab is not on Azure, so there is no platform under it to answer, and
nothing in this course pretends to be one. The table is Microsoft's documented interface.

## Which identity answers

A resource can have a system-assigned identity and several user-assigned ones at once, as the shop's
web app does. **A request that does not say which identity it wants gets the system-assigned one**, if
there is one. To use `id-shop-app` the program must name it, by its client id, which is exactly why
`app.bicep` put that client id in the application setting `AZURE_CLIENT_ID`: the code reads it from
the environment and never has the value written into it.

That one setting is easy to forget, and the failure it causes is quiet: the program signs in as the
**system-assigned** identity, which has no role on the storage account, and the read is refused with
an authorisation error that looks like a missing role rather than a wrong identity. When a managed
identity is refused something it was given, **first check which identity the token belongs to**: its
`oid` claim is the object id of the principal that signed in.

## What a managed identity does not protect

The credential cannot leak, and the token can. Whoever runs code on the machine can ask IMDS for a
token as easily as the application can: **a managed identity is exactly as safe as the machine it is
attached to.** Give it the roles the application needs and no more, on the narrowest scope that works,
which for the shop is one storage account rather than the subscription, and lesson 9 is how.
