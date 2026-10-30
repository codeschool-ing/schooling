---
title: Slots, warm-up and the swap
version: 1
---

**A deployment slot is a second running copy of an App Service app**, with its own host name,
`app-shop-api-staging.azurewebsites.net`, on the same plan and the same machines. The shop deploys every
new version into `staging`, never into production, and then swaps. `azure-compute` lesson 18 introduces
slots; this section is about using them as the deployment mechanism.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two panels, before and after a swap. Before: the production slot of app-shop-api runs version 41 and receives all traffic; the staging slot runs version 42, warmed up, receiving none. After the swap: production runs version 42 and receives all traffic; staging holds version 41, ready to be swapped back. The setting marked slot-sticky, the database connection, stays with its slot in both panels.\"><defs><marker id=\"ah-swap\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">before the swap</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">after the swap</text><rect x=\"40\" y=\"50\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">production slot</text><text x=\"180\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v41</text><text x=\"180\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">all traffic</text><rect x=\"40\" y=\"150\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">staging slot</text><text x=\"180\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v42</text><text x=\"180\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">warmed up, no traffic</text><path d=\"M330 140 L390 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-swap)\"></path><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">swap</text><rect x=\"400\" y=\"50\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">production slot</text><text x=\"540\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v42</text><text x=\"540\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">all traffic</text><rect x=\"400\" y=\"150\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">staging slot</text><text x=\"540\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v41</text><text x=\"540\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one swap away from back</text><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sticky: DB_CONNECTION stays with each slot</text></svg>", "caption": "A swap exchanges what runs, not where the traffic goes. A sticky setting stays with its slot."}
```

**A swap exchanges the contents of two slots; it does not move traffic between two hosts.** Before the
switch, App Service applies production's settings to the staging slot's processes and waits for them
to start, sending requests to the application's root, or to the paths you list in
`applicationInitialization`, until they answer. Only then does it switch routing. Done this way, the
first customer request on the new version lands on a process that has already loaded its code and
opened its connections, which is the whole point of the slot: **the cold start happens before the
customer, not to the customer.**

## Settings that stay behind

Most configuration travels with the code in a swap. Some must not: the staging slot's database is not
production's, and a swap that carried `DB_CONNECTION` across would point production at the staging
database. A setting marked **slot-specific**, or sticky, stays with its slot. In Bicep the slot and the
sticky list look like this; the file was **not compiled** here, because Bicep arrives in lesson 4, and
it was never deployed:

```bicep
// slot.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource staging 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: app
  name: 'staging'
  location: 'brazilsouth'
  properties: {
    siteConfig: {
      healthCheckPath: '/healthz'
    }
  }
}

resource sticky 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [ 'DB_CONNECTION' ]
  }
}
```

## Swapping

The swap itself is one command, **not run** here because it needs Resource Manager:

```sh
az webapp deployment slot swap -g rg-shop -n app-shop-api --slot staging --target-slot production
```

Two variants are worth knowing. **Swap with preview** stops after applying production's settings to the
staging processes, so you can test the new version with the configuration it will have, then complete
or cancel. **Auto swap** swaps on its own after every deployment to the slot, which removes the moment a
person or a gate looks; the shop does not use it in production for that reason.

Slots are not free of cost or of limits. They run on the same plan, so a busy staging slot takes
capacity from production; and the number of slots depends on the plan's tier. A plan that has none
cannot use this pattern at all, which is worth checking before a team designs around it.
