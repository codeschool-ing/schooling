---
title: The perimeter, layer by layer
version: 1
---

**A perimeter is not one wall; it is layers, each stopping what the one outside it let through.** The
shop's has four:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The shop&#x27;s perimeter as layers from the internet inwards. First, Front Door at Microsoft&#x27;s edge, absorbing volumetric floods, with its WAF handling layer 7 attacks. Second, the App Service, which accepts traffic only from Front Door. Third, the virtual network, where network security groups allow only the expected flows. Fourth, private endpoints for the SQL database and the Key Vault, which have no public address at all.\"><defs><marker id=\"ah-layers\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"700\" height=\"225\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">internet</text><rect x=\"40\" y=\"50\" width=\"640\" height=\"185\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Front Door + WAF: floods and layer 7</text><rect x=\"70\" y=\"80\" width=\"580\" height=\"145\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">App Service: accepts only Front Door</text><rect x=\"100\" y=\"110\" width=\"520\" height=\"105\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">virtual network: NSGs allow the expected flows</text><rect x=\"130\" y=\"140\" width=\"460\" height=\"65\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">private endpoints: SQL, Key Vault</text><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no public address</text></svg>", "caption": "Each layer stops what the one before it lets through, and the innermost has no public address to attack."}
```

1. **Front Door with its WAF**, at the edge. Floods are absorbed across Microsoft's network; layer 7
   attacks meet the managed rules and the rate limit of lesson 18.
2. **App Service accepts traffic only from Front Door.** An access restriction allows the service tag
   `AzureFrontDoor.Backend` and checks the `X-Azure-FDID` header against the shop's own Front Door id,
   so an attacker who finds the app's `azurewebsites.net` address cannot go around the edge. Without
   this, every protection at the edge is optional for anyone who looks.
3. **Inside the virtual network, network security groups allow the expected flows only**: the app's
   outbound integration subnet to the database's private endpoint on 1433, and nothing else.
   `azure-foundations` lesson 17 covers NSGs.
4. **The database and the vault have no public address at all**, reached through private endpoints,
   which lesson 20 builds. There is nothing at the centre for a flood to hit.

The second layer is the one teams forget, and it matters more than any paid plan: **a protection that can
be bypassed protects nothing**. The same reasoning drives lesson 20: closing the public path is worth
more than guarding it.
