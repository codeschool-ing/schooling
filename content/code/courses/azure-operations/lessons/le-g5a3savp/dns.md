---
title: DNS: one name, two answers
version: 1
---

**The application keeps using the public name, and DNS decides which address it gets.** This is how Azure
documents it for SQL, and it was not observed here because no name was resolved:

```
sql-shop.database.windows.net             CNAME  sql-shop.privatelink.database.windows.net
sql-shop.privatelink.database.windows.net A      10.20.2.4   (asked from inside vnet-shop)
```

The first record is Azure's, and public: the service's name always points at its `privatelink` name.
The second is answered by **whichever DNS the client asks**. Inside `vnet-shop`, Azure's resolver
consults the linked private zone and returns the private address. From the internet, the same chain ends
at Azure's public answer, and with public access off the connection is refused.

Three failures cover most of the support tickets:

- **the name resolves to a public address from inside the network**: the zone is not linked to that
  network, or the network uses a custom DNS server that does not forward to Azure's resolver at
  `168.63.129.16`;
- **it works from Azure and not from the office**: the office's DNS has no idea the private zone exists;
  the fix is a DNS forwarder or Azure's **DNS Private Resolver**, so on-premises queries for
  `privatelink` domains reach Azure;
- **somebody created a second `privatelink.database.windows.net` zone** in another resource group and
  linked it too. A network may be linked to only one zone of a given name, so private DNS zones belong in
  one shared place, owned by the platform team.

The test is the same in every case: resolve the name **from where the client runs**, with `nslookup` or
`dig`, and compare the answer with the endpoint's address. A connection error to a private endpoint is a
DNS question until proven otherwise.
