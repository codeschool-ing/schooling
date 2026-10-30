---
title: Anonymous access, one setting away
version: 1
---

**A container can be made readable by anybody on the internet with one setting, and no signature of
any kind.** Blob Storage calls it the container's public access level, and it has three values:
`off`, which is private; `blob`, where anybody who knows a blob's name can read it; and `container`,
where anybody can also list the names. It exists for good reasons, such as the product images of a
public website, and it is the shape behind most of the storage leaks that made the news. The setting
is on the container, so a container made public on Friday afternoon for a quick test is public on
Monday.

## On Azurite

```
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access blob -o none
ana@laptop:~/azure$ curl -s "$BLOB"
order_id,customer_id,total_cents
29-1,c-17,4590
29-2,c-03,12800
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access container -o none
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Name>[^<]*</Name>"
<Name>exports/2026/10/orders-2026-10-29.csv</Name>
ana@laptop:~/azure$ az storage container set-permission -n orders-raw --public-access off -o none
ana@laptop:~/azure$ curl -s -o /dev/null -w "%{http_code}\n" "$BLOB"
403
```

**`blob` made the export readable by a `curl` with no credentials**, and refused the listing: with
that level, a stranger has to know the exact name. `container` added the listing, and the listing
handed over the name. Setting it back to `off` closed both. On Azurite, as on Azure, the setting
takes effect on the next request.

**Knowing the name is not protection.** Names in a lake are predictable by design: lesson 2 chose
`exports/2026/10/orders-2026-10-29.csv` so that a program could find the next day's file by itself,
and a stranger can find it the same way. Level `blob` is public for every name somebody can guess.

## The switch above the container

On Azure there is one more layer, which Azurite does not have: **the account's setting for anonymous
access**, `allowBlobPublicAccess`. When it is false, no container in the account can be public,
whatever its own level says, and a request to set a level is refused. Microsoft's documentation says
new storage accounts are created with it set to false by default. That closes the commonest leak for
anybody who does nothing, and leaves it open in older accounts created before the change and in any
account where somebody turned it on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A request signed by nobody, from outside, has to pass two settings to reach a blob. The outer one is the account's allowBlobPublicAccess, which Azurite does not have; set to false, it wins over any container. The inner one is the container's public access level: off is private, blob allows reading by name, container allows reading and listing; Azurite enforces it.\" data-fig=\"l06-layers\"><defs><marker id=\"l06-layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"230\" y=\"20\" width=\"470\" height=\"260\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"244\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">account: allowBlobPublicAccess</text><text x=\"686\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Azurite: no such setting</text><rect x=\"254\" y=\"58\" width=\"422\" height=\"202\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"268\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container: public access level</text><text x=\"662\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Azurite: enforced</text><rect x=\"278\" y=\"98\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">off</text><text x=\"410\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">private</text><rect x=\"278\" y=\"132\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">blob</text><text x=\"410\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">read by name</text><rect x=\"278\" y=\"166\" width=\"120\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"338\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">container</text><text x=\"410\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">read and list</text><rect x=\"500\" y=\"120\" width=\"150\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"575\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the blob</text><text x=\"575\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">orders-2026-10-29.csv</text><text x=\"268\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">false on the account wins over any container level</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a request</text><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signed by nobody</text><line x1=\"150\" y1=\"150\" x2=\"496\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.8\" marker-end=\"url(#l06-layers-ah)\"/></svg>", "caption": "Anonymous access is decided twice. The lab can show the inner decision and not the outer one."}
```

That makes anonymous access a decision taken twice, once on the account and once on the container,
and the safe arrangement keeps the account switch false everywhere except an account made for public
files and nothing else. The last section declares it with Terraform.
