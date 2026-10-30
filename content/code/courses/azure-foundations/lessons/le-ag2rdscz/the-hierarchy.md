---
title: Tenant, management groups, subscriptions and resource groups
version: 1
---

**The usual first picture of Azure has one box, the account, with everything inside it. Azure has
four boxes, nested, and two different things that people call "the account".** One is the box of
identity, the other is the box of money, and keeping them apart is the first thing this course asks
of you.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" data-fig=\"l02-hierarchy\" aria-label=\"The shop's hierarchy as four nested kinds of box. The tenant, shop.onmicrosoft.com, holds the root management group. Under it hangs mg-shop, and under that three management groups: mg-shop-prod, mg-shop-nonprod and mg-shop-platform. Each holds one subscription: shop-prod, shop-staging and shop-shared. Inside shop-prod sit two resource groups, rg-shop-prod-app and rg-shop-prod-data, and inside those the resources. A note says that identity lives in the tenant and money in the subscription.\"><rect x=\"20.0\" y=\"14.0\" width=\"680.0\" height=\"362.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tenant</text><text x=\"684.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.onmicrosoft.com</text><rect x=\"270.0\" y=\"46.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">root management group</text><path d=\"M360.0 80.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"290.0\" y=\"96.0\" width=\"140.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop</text><path d=\"M125.0 142.0 L595.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 126.0 L360.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M125.0 142.0 L125.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"45.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-prod</text><path d=\"M125.0 184.0 L125.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"27.0\" y=\"198.0\" width=\"196.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"37.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><text x=\"213.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><path d=\"M360.0 142.0 L360.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"280.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-nonprod</text><path d=\"M360.0 184.0 L360.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"262.0\" y=\"198.0\" width=\"196.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><text x=\"448.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><path d=\"M595.0 142.0 L595.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"515.0\" y=\"154.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-platform</text><path d=\"M595.0 184.0 L595.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"497.0\" y=\"198.0\" width=\"196.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">subscription</text><text x=\"683.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-shared</text><rect x=\"40.0\" y=\"228.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"125.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><rect x=\"40.0\" y=\"286.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-data</text><text x=\"125.0\" y=\"319.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sql-shop-prod</text><text x=\"470.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">identity lives in the tenant</text><text x=\"470.0\" y=\"324.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">money lives in the subscription</text><text x=\"470.0\" y=\"348.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resource groups do not nest</text></svg>", "caption": "Four kinds of box. The tree in the middle can be six levels deep; the shop needs two."}
```

From the outside in:

- **The tenant** is an instance of Microsoft Entra ID: one directory of users, groups and
  applications, with a GUID for an id and a domain such as `shop.onmicrosoft.com`. It is the box of
  identity, and lessons 6 to 12 live inside it. A company has one, normally, and every identity it
  owns is in it.
- **Management groups** are folders for subscriptions. Every tenant has one at the top, the **root
  management group**, whose id is the tenant's own id and which the portal calls *Tenant Root
  Group*. Below it you build a tree, up to **six levels deep**, not counting the root or the
  subscriptions at the bottom. Their whole purpose is inheritance: a policy or a permission given to
  a management group reaches everything under it, which is lessons 4 and 9.
- **A subscription** is the box of money. Resources are created in it, it is billed for them, its
  quotas are counted inside it, and it trusts **exactly one tenant** for the identities allowed to
  touch it. A subscription has one parent: a management group, or the root if nobody placed it.
- **A resource group** is a box inside one subscription, holding resources that live and die
  together. Every resource is in exactly one resource group, and **resource groups do not nest**.
  Deleting a group deletes everything in it, which is why lesson 1 used it as the unit of cleaning up.

## What each box is for

| box | it decides | how many |
|---|---|---|
| tenant | who exists: every identity, and how it signs in | one per company, as a rule |
| management group | what is inherited: policies and permissions for a whole branch | up to 10,000 in a tenant, six levels below the root |
| subscription | who pays, and the limits: the bill, the quotas, the boundary of a mistake | as many as the company needs; never just one |
| resource group | what lives and dies together: one application in one environment | up to 980 in a subscription |

**A resource group has a location, and it does not mean what it looks like.** `rg-shop-prod` is
created in `brazilsouth`, and that is only where Azure keeps the group's own record: the list of
what is in it. A virtual machine inside the group can be in any other region. Choose the region
where the resources are, so that the record and the things it describes live under the same law
and fail together.

## The shop's tree

The online shop this course follows has one tenant and three subscriptions, and the tree is drawn
around what differs between them, not around the company's departments:

- `mg-shop` under the root, holding everything the shop runs;
- `mg-shop-prod` under it, with the subscription `shop-prod`, where customers' orders are;
- `mg-shop-nonprod` beside it, with `shop-staging`, where releases are tried first;
- `mg-shop-platform`, with `shop-shared`, for what both environments use: the hub network of
  lesson 20, the DNS zones of lesson 21, the logs.

**The tree follows the rules, not the organisation chart.** A branch exists because everything
under it is governed the same way: production with stricter policies, non-production with cheaper
ones. A department that reorganises every two years would drag the tree with it, and every move of
a subscription between branches changes what it inherits.

## Creating the boxes, and what this lab can do about it

Each box is created by a different door. A tenant comes with signing up for Azure, as in lesson 1.
A management group is a resource of Resource Manager at the level of the tenant, and so are the
subscription's placement in the tree and the resource group:

```
ana@laptop:~/azure$ az group create --name rg-shop-prod --location brazilsouth
ERROR: Please run 'az login' to setup account.
```

**Nothing was created**: every one of these is a request to Resource Manager, and the lab never
signs in. The commands are worth knowing by name, `az account management-group create` for a
management group, `az account management-group subscription add` to place a subscription,
`az group create` for a resource group; the rest of this lesson builds the same tree in a file,
which is something the lab can check.
