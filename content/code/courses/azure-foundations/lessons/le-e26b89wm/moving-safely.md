---
title: Moving safely, and the move that is not a move
version: 1
---

**A move is checked before it starts, and the check is a separate request you can make on its own.**
Resource Manager has an action called `validateMoveResources`: it takes the source group, the
destination and the list of ids, and answers whether the move would succeed, without moving
anything. The portal runs it for you before every move. From the command line it is two commands,
the check and the move:

```
ana@laptop:~/azure/moves$ az resource invoke-action --action validateMoveResources --ids /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod --request-body '{"resources": ["/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod"], "targetResourceGroup": "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod-network"}'
ERROR: Please run 'az login' to setup account.
```

```
ana@laptop:~/azure/moves$ az resource move --destination-group rg-shop-prod-network --ids /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod
ERROR: Please run 'az login' to setup account.
```

**Neither was answered here**, for the reason every request to Resource Manager goes unanswered in
this lab. With an account, a validation that passes returns nothing at all, and one that fails
returns an error naming the resource and the reason. `az resource move` takes
`--destination-subscription-id` as well, for a move across subscriptions.

## The checklist Microsoft publishes

Before a move, the documentation lists what has to be true. Read as a list of the ways a move
fails, it is short:

| what has to be true | what happens otherwise |
|---|---|
| the type can move, by the table in the previous section | the validation refuses |
| source and destination subscriptions are active and trust the same tenant | the validation refuses |
| the destination subscription is **registered** for the resource's provider namespace | the move fails with *the subscription isn't registered for a resource type* |
| the destination has quota for what arrives | the move fails at the destination |
| no read-only lock on the source group, the destination group or either subscription | the move is refused |
| you may `moveResources` on the source group and `write` on the destination | the request is refused |

Registration is the one people meet first. A subscription has to be registered with a provider
namespace, such as `Microsoft.Network`, before it can hold that provider's resources. Creating a
resource registers it on the way, which is why nobody notices, but a move does not: a new
subscription that has never held a network refuses one moved into it until somebody registers
`Microsoft.Network` with `az provider register`.

## Across subscriptions, dependencies travel together

**Between subscriptions, a resource and everything it depends on must be in the same resource group,
and move in the same request.** A virtual machine is not one resource: it has disks, a network
interface, and the interface sits in a subnet of a network. Moving the machine to another
subscription means moving all of that at once. Microsoft describes it as three steps:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-cross-subscription\" aria-label=\"Moving a virtual machine to another subscription in three steps. Before: the machine is in rg-shop-prod-app and its network in rg-shop-prod-network, both in shop-prod. Step 1, gather: the network is moved into rg-shop-prod-app, inside shop-prod. Step 2, move: the whole group's worth, machine, disk, interface and network, moves to shop-shared in one request. Step 3, spread: at the destination they may be split into groups again.\"><defs><marker id=\"l03-cross-subscription-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-cross-subscription-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">before</text><rect x=\"20.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><text x=\"34.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><rect x=\"32.0\" y=\"80.0\" width=\"176.0\" height=\"90.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"120.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"120.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><rect x=\"32.0\" y=\"182.0\" width=\"176.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-network</text><text x=\"120.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  gathered</text><rect x=\"260.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><text x=\"274.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><rect x=\"272.0\" y=\"80.0\" width=\"176.0\" height=\"110.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"360.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><text x=\"360.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"600.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2  moved, 3  spread</text><rect x=\"500.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"686.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-shared</text><text x=\"514.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><rect x=\"512.0\" y=\"80.0\" width=\"176.0\" height=\"90.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-app</text><text x=\"600.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm-shop-1</text><text x=\"600.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">disk</text><text x=\"600.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nic</text><rect x=\"512.0\" y=\"182.0\" width=\"176.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-network</text><text x=\"600.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><path d=\"M222.0 160.0 L258.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-cross-subscription-af-ah-paper-dim)\"></path><path d=\"M462.0 160.0 L498.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l03-cross-subscription-af-ah-amber)\"></path></svg>", "caption": "Across subscriptions a machine travels with its disk, its interface and its network, in one request."}
```

1. **gather**: if the dependencies are spread over several groups, move them into one group first,
   inside the same subscription;
2. **move** the whole group's worth to the other subscription, in one request;
3. **spread** them again, if you want, into groups at the destination.

Some dependencies refuse to travel at all, and the networking guidance names the ones the shop
would meet. **A peered virtual network has to have its peering removed before it moves**, and put
back afterwards, which is lesson 20's subject. A network with a service deployed into one of its subnets,
such as Azure Databricks, carries a link from that service and cannot move to another subscription. And anything tied
to a Standard public IP address stays in its subscription, as the previous section found.

## The move that is not a move: a subscription to another tenant

A subscription can also be handed to a **different tenant**, which is what happens when a company is
bought, or when a subscription opened with somebody's personal account is brought into the company's
directory. In the portal it is called *change directory*. **It is not a move in this lesson's sense,
and it is far more destructive**: every identity the subscription trusted belonged to the old
tenant, so Microsoft's documentation warns that the role assignments, the custom roles and the
managed identities of lesson 8 do not survive it, and that resources holding a tenant id, such as a
key vault, have to be told the new one.

**None of this was run**, and none of it should be run casually with an account either. A move
between groups is a filing change; a change of tenant is closer to moving house and losing the keys
on the way.
