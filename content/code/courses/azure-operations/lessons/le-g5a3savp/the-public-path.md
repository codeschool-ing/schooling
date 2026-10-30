---
title: Three ways to reach a service, and the one that closes the door
version: 1
---

**A PaaS service such as Azure SQL, Storage or Key Vault has a public endpoint by default.** Its name
resolves to a public address, and what stands between the internet and the data is the service's
firewall and its authentication. Three ways exist to narrow that:

| | how traffic reaches the service | does the public endpoint remain? |
|---|---|---|
| **firewall rules** | over the internet, from listed addresses | yes, filtered |
| **service endpoints** | over Azure's backbone, from listed subnets | yes, filtered by subnet |
| **private endpoint** | a network interface with a private address in your subnet | only if you leave it on |

A **private endpoint** is the strongest: the service appears inside your virtual network, at a private
address, and traffic to it never leaves the network. With the public endpoint then turned off, there is
no address on the internet for an attacker to try, which is the point lesson 19 ended on. The shop puts
its SQL server, its Key Vault and its state storage account behind private endpoints.

Service endpoints are older and cheaper, and they keep the public endpoint, merely restricting who may use
it; they also only work from Azure subnets. Private endpoints are billed per hour and per gigabyte
processed, and they need DNS, which is where most of the trouble is:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The DNS chain for sql-shop. From inside vnet-shop, the name sql-shop.database.windows.net is a CNAME to sql-shop.privatelink.database.windows.net, which the private DNS zone linked to the network answers with the private endpoint&#x27;s address in the subnet. From the internet, the same CNAME leads to Azure&#x27;s public answer, and with public network access disabled the server refuses the connection.\"><defs><marker id=\"ah-dns\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"230\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop.database</text><text x=\"135\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.windows.net</text><rect x=\"290\" y=\"90\" width=\"200\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop.privatelink</text><text x=\"390\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.database.windows.net</text><path d=\"M250 115 L288 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path><text x=\"269\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CNAME</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">inside vnet-shop</text><text x=\"615\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">private address</text><rect x=\"530\" y=\"140\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">from the internet</text><text x=\"615\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refused</text><path d=\"M490 105 L528 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path><path d=\"M490 125 L528 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-dns)\"></path></svg>", "caption": "One name, two answers, depending on who asks."}
```
