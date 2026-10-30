---
title: What a move is, and what it leaves behind
version: 1
---

**Moving a resource in Azure does not move it anywhere.** The wrong picture is a lorry: the machine
is unplugged in one place and plugged in again in another. A move between resource groups, or
between subscriptions, changes which box the resource is filed in and nothing else. The virtual
machine keeps running in the same datacentre, on the same disk, with the same address, and its
users notice nothing. What changes is its name.

## The id changes, and everything that held it breaks

Lesson 2 took resource ids apart. A move rewrites the left-hand end of one:

| | resource id |
|---|---|
| before | `/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |
| after a move to another group | `/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod-network/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |
| after a move to another subscription | `/subscriptions/ddddeeee-3333-ffff-4444-aaaa5555bbbb/resourceGroups/rg-shop-network/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod` |

**Everything that stored the old id is now pointing at nothing**: a script, a dashboard, an alert
rule, a Bicep file that names it, another resource's reference to it. Microsoft's own checklist
says it in one line: if you use the resource id anywhere, change it. Nothing does that for you, and
nothing tells you which places to look. That is the first cost of a move, and the reason to choose a
resource group carefully the first time.

**The region does not change.** A move between groups or subscriptions keeps a resource where it
is. Taking it to another region is a different operation, done by recreating it there, either by
hand or with Azure Resource Mover, and lesson 26's idea of a resource written down in a file is what
makes recreating it cheap.

## What happens while it moves

Four things the documentation states and this lab cannot show:

- **Both resource groups are locked for the duration.** Nothing can be created, deleted or changed
  in the source group or in the destination group until the move finishes. The resources keep
  working; they just cannot be modified. A move of many resources can take hours, which is hours in
  which nobody can deploy to either group.
- **Child resources go with their parent, and only with it.** A subnet moves with its network and an
  extension with its virtual machine. You ask to move the parent; asking to move a child on its own
  is refused.
- **Role assignments on the resource do not move.** A permission given on the resource itself, which
  lesson 9 explains, is left behind and becomes an orphan that Azure eventually removes. It has to be
  created again at the destination. Permissions inherited from above simply change: the resource now
  inherits from its new group and its new subscription.
- **Between subscriptions, both must trust the same tenant.** A move cannot carry a resource from one
  company's directory to another's. That is a different operation, done to the whole subscription,
  and the last section of this lesson says what it costs.

## Moving a subscription is not moving a resource

A subscription can be moved between management groups, and that is an ordinary operation: one
request, nothing locked, no id changes, since a subscription's id does not mention its management
group. **What changes is what it inherits.** Lesson 2's warning about moving a subscription between
branches of the tree comes from here: the resources stay exactly where they are, and the policies of
lesson 4 and the permissions of lesson 9 that apply to them change in the same second.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-three-moves\" aria-label=\"Three kinds of move compared in three columns. A resource moved to another resource group: its id changes, its region does not, and both groups are locked while it moves. A resource moved to another subscription: its id changes, its region does not, both subscriptions must trust the same tenant, and its dependencies move with it. A subscription moved to another management group: no id changes and nothing is locked, but what it inherits changes at once.\"><rect x=\"20.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"128.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a resource, to another group</text><path d=\"M36.0 78.0 L220.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"128.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">id changes</text><text x=\"128.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">region stays</text><text x=\"128.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">both groups locked</text><text x=\"128.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">own role assignments lost</text><rect x=\"252.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a resource, to another subscription</text><path d=\"M268.0 78.0 L452.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">id changes</text><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">region stays</text><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">same tenant required</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dependencies go together</text><rect x=\"484.0\" y=\"20.0\" width=\"216.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"592.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a subscription, to another group</text><path d=\"M500.0 78.0 L684.0 78.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"592.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no id changes</text><text x=\"592.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing locked</text><text x=\"592.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">inheritance changes</text><text x=\"592.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">at once, for everything in it</text></svg>", "caption": "Two kinds of move rename a resource; the third renames nothing and changes the rules."}
```
