---
title: The name stays the same, and the answer changes
version: 1
---

**The application does not change a single line when a private endpoint arrives.** It still opens
`stshopprod.blob.core.windows.net`, because that is the name the account's certificate carries and
the name every SDK builds from the account's name. What changes is the answer the name gets, and
whether it gets the private one depends on **where the question is asked from**. That is the whole
trick, and most failures of private endpoints are failures of it.

## A CNAME in the middle

When a private endpoint is created for an account, Azure changes the account's public DNS: the name
no longer points straight at the public endpoint but at an intermediate name in a zone called
`privatelink.blob.core.windows.net`, and that one points at the public endpoint. Two resolvers then
walk the same chain and stop at different places:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l19-dns-split\" aria-label=\"The same name resolved from two places. The chain starts at stshopprod.blob.core.windows.net, a CNAME to stshopprod.privatelink.blob.core.windows.net. Asked from the internet, the public DNS answers the intermediate name with a further CNAME that ends at the public address of the storage service. Asked from inside vnet-shop-prod, Azure's resolver at 168.63.129.16 finds the linked private zone privatelink.blob.core.windows.net and answers the intermediate name with the A record 10.20.4.4.\"><defs><marker id=\"l19-dns-split-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-dns-split-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l19-dns-split-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"210.0\" y=\"20.0\" width=\"300.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod.blob.core.windows.net</text><path d=\"M360.0 55.0 L360.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-paper-dim)\"></path><text x=\"372.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"160.0\" y=\"88.0\" width=\"400.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stshopprod.privatelink.blob.core.windows.net</text><path d=\"M250.0 123.0 L160.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-amber)\"></path><rect x=\"20.0\" y=\"182.0\" width=\"280.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">asked from the internet</text><text x=\"160.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the public DNS answers the middle link</text><text x=\"160.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CNAME onwards to the public endpoint</text><text x=\"160.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a public address</text><path d=\"M470.0 123.0 L560.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-dns-split-af-ah-phosphor)\"></path><rect x=\"420.0\" y=\"182.0\" width=\"280.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">asked from vnet-shop-prod</text><text x=\"560.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">168.63.129.16 has a linked private zone</text><text x=\"560.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A  10.20.4.4</text><text x=\"560.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the private endpoint</text></svg>", "caption": "The private zone takes over the middle link, not the account's name."}
```

- **From the internet**, nobody has a zone called `privatelink.blob.core.windows.net`, so the public
  DNS answers it, and the chain ends at the public address. With `publicNetworkAccess` disabled, a
  connection there is refused: the name resolves and the account does not answer.
- **From inside `vnet-shop-prod`**, the network's resolver, Azure's own at `168.63.129.16`, finds
  that it has a private zone of exactly that name linked to the network. It answers the intermediate
  name from the zone, with the A record the zone group wrote: `10.20.4.4`.

So **the private zone does not take over the account's name; it takes over the middle link of its
chain**, which is why the zone in `pe.bicep` is called `privatelink.blob...` and not `blob...`. A
private zone called `blob.core.windows.net` would answer for every storage account in Azure, and
every one the shop did not give an endpoint would stop resolving.

## The same pattern, in a name you can ask about

The machine this course was recorded on resolves names through a resolver that only answers for the
hosts it is allowed to reach, so a storage account's chain could not be shown here. A made-up account
does not exist, and an existing one is not on that list. Microsoft's sign-in service is on it, and its
public chain has the same shape:

```
ana@laptop:~/azure/private-link$ dig login.microsoftonline.com +noall +answer +nottlid | grep CNAME
login.microsoftonline.com. IN	CNAME	login.mso.msidentity.com.
login.mso.msidentity.com. IN	CNAME	ak.privatelink.msidentity.com.
ak.privatelink.msidentity.com. IN CNAME	www.tm.a.prd.aadg.akadns.net.
```

`dig` asks the DNS a question and prints the answer; `+noall +answer` keeps only the answer, and
`+nottlid` leaves out each record's remaining lifetime, which changes every second. Three links, and
the second one is in a zone called `privatelink.msidentity.com`: **Microsoft's own sign-in name
passes through a `privatelink` zone on the public internet**, so that a network with a private zone
of that name can answer the middle link differently, exactly as with the storage account. The last
link hands the name to a service that spreads sign-ins across many places, and it is not stable: in two
runs made while this lesson was written it pointed once into Azure Traffic Manager's
`trafficmanager.net` and once into another provider's zone. Lesson 22 explains names that answer
differently on purpose. Expect the end of your chain to differ from this one; the `privatelink` link in
the middle is the part that matters.

## When the private answer does not arrive

Three mistakes account for nearly every endpoint that "does not work", and each shows as the public
address coming back to a machine that should have had `10.20.4.4`:

- **The zone is not linked to the network asking.** A zone answers only the networks it has a
  virtual network link to. The shop's endpoints are reached from the production spoke and from the
  hub, so the zone needs a link to each, or one zone in the hub that every spoke's DNS goes through;
  lesson 20 draws that hub.
- **The network does not use Azure's resolver.** A virtual network set to use a DNS server of its
  own, such as a domain controller, asks that server instead of `168.63.129.16`, and that server
  knows nothing about private zones unless it forwards the `privatelink` zones to Azure. Lesson 21
  covers the Private Resolver that does this for networks and offices alike.
- **The question comes from the office.** A laptop on the VPN of lesson 23 asks the office's DNS,
  which asks the internet, which gives the public answer. The office's DNS needs a **conditional
  forwarder** for `privatelink.blob.core.windows.net` pointing at a resolver inside Azure.

To see which case you are in, ask from the machine that fails: `nslookup` or `dig` of the account's
name there either returns `10.20.4.4` or it does not, and the chain it prints says at which link it
left the private path.
