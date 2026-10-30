---
title: Resource providers, request limits, and the other plane
version: 1
---

**Resource Manager does not know how to build a network. It knows who may ask, and which service to
pass the request to.** The services behind it are the **resource providers**, one per namespace:
`Microsoft.Network`, `Microsoft.Compute`, `Microsoft.Storage`, `Microsoft.KeyVault` and many
more. This section is about three consequences of that arrangement.

## A provider has to be registered

**A subscription can only create a type whose provider is registered in it.** Registration configures
the subscription to work with that provider, and Microsoft's documentation recommends registering only
the ones you use: each registration can add an application from Microsoft to the tenant, and a provider
nobody registered is one a stolen credential cannot use either. Some are registered from the start. A
deployment through the portal, or of a Bicep or ARM template, registers the providers it names; a
resource that quietly needs a second provider, for monitoring for instance, is where somebody meets the
error `MissingSubscriptionRegistration`. The cure is one command,
`az provider register --namespace Microsoft.Insights`, and `az provider show --namespace
Microsoft.Network --query registrationState` says where a provider stands. **Neither was run here**:
both are questions about a subscription.

A provider also says, for each of its types, **which regions offer it and which `api-version`s exist**.
That is the authoritative answer to "can I create this in `brazilsouth`?", and it comes from
`az provider show` with an account. Without one, the provider's documentation pages carry the same
list.

## Request limits

Resource Manager counts requests, and refuses them past a limit. **Since 2024 it uses a token bucket per
subscription and per region**: each kind of request draws a token from a bucket, and the bucket refills
at a fixed rate. Microsoft's documentation gives these figures:

| scope | requests | bucket size | refill per second |
|---|---|---|---|
| subscription | reads | 250 | 25 |
| subscription | writes | 200 | 10 |
| subscription | deletes | 200 | 10 |
| tenant | reads | 250 | 25 |
| tenant | writes | 200 | 10 |
| tenant | deletes | 200 | 10 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-bucket\" aria-label=\"A token bucket for subscription reads, drawn as a column of 250 tokens. A burst of 250 reads empties it in one go. After that, 25 tokens come back each second, so the script can go on at 25 reads a second. A request when the bucket is empty is answered with 429 and a Retry-After.\"><defs><marker id=\"l25-bucket-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25-bucket-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"44.0\" y=\"44.0\" width=\"82.0\" height=\"142.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">250</text><text x=\"85.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">full</text><text x=\"85.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250 tokens</text><rect x=\"240.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"285.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after a burst</text><text x=\"285.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">250 reads at once</text><rect x=\"440.0\" y=\"40.0\" width=\"90.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"444.0\" y=\"179.0\" width=\"82.0\" height=\"7.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">25</text><text x=\"485.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">one second later</text><text x=\"485.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25 more</text><path d=\"M131.0 115.0 L239.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-paper-dim)\"></path><path d=\"M331.0 115.0 L439.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"60.0\" width=\"140.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">429</text><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Retry-After</text><text x=\"630.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">if the bucket</text><text x=\"630.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">is empty</text><path d=\"M285.0 39.0 L285.0 22.0 L630.0 22.0 L630.0 59.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-bucket-af-ah-amber)\"></path></svg>", "caption": "Subscription reads: a burst of 250, then 25 a second for as long as you keep going."}
```

So a script may read 250 times in one burst, and after that 25 times a second for as long as it
keeps going. Past the limit the answer is **429 Too Many Requests** with a `Retry-After` in seconds,
and a request sent before that time is refused again with a new one. Answers also carry
headers such as `x-ms-ratelimit-remaining-subscription-reads`, which say how much is left. **A script
that loops over hundreds of resources should read those headers and honour `Retry-After`**, rather than
retrying at once and spending the next token too. Some providers also return 429 for their own
reasons, such as another operation holding a lock on the resource, and the error code in the body is
what tells the two apart.

## The control plane and the data plane

**Everything in this lesson so far is the control plane**: creating, configuring and deleting
resources, through `management.azure.com`. Using a resource is another plane altogether, with its own
address:

| | control plane | data plane |
|---|---|---|
| storage | create the account `shopassets`, set its replication | read and write blobs at `shopassets.blob.core.windows.net` |
| virtual machine | create it, resize it, stop it | sign in to it over SSH |
| key vault | create the vault, set who may manage it | read a secret at `kv-shop-prod.vault.azure.net` |
| who answers | Resource Manager, then the provider | the service itself |

The difference decides three things. **Permissions are separate**: a role can allow managing a storage
account without allowing reading a single blob in it, which lesson 9 calls *data actions*. **The path is
separate**: a data plane request never passes through Resource Manager, so its limits are the service's
own, not the table above. And **the network rules apply to the data plane**: lesson 19's private
endpoint closes `shopassets.blob.core.windows.net` to the internet, while the account can still be
managed through `management.azure.com` as before.

The `storage` suffix lesson 1 read from `az cloud show`, `core.windows.net`, is the data plane's address,
and `management.azure.com` beside it the control plane's: the CLI keeps both, because it speaks to
both.
