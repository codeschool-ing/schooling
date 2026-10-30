---
title: Tags, and the rules they follow
version: 1
---

**A tag is a name and a value stuck on a resource, and it is the only way a bill can say whose a cost
is.** The subscription and the resource group already say something: lesson 2 built the tree so that
production and staging are paid apart. But a company's money is divided by more than environments:
by team, by product, by cost centre, by customer. One resource group can hold the checkout team's web
servers and the catalogue team's cache, and the bill names neither team unless a tag does.

## What a tag is, by Azure's rules

A tag is a pair, such as `cost-centre: cc-410`, and Microsoft's documentation sets its limits:

| rule | what it means for the shop |
|---|---|
| **up to 50 pairs** on each resource, resource group and subscription | enough for any sane scheme; a scheme that needs more is describing the resource rather than its owner |
| a name up to **512 characters**, a value up to **256** (a storage account: 128 for the name) | short is better: a tag is typed into filters by people |
| **names are case-insensitive, values are case-sensitive** | `Cost-Centre` and `cost-centre` are the same tag; `cc-410` and `CC-410` are two cost centres |
| **resources do not inherit their group's tags** | a tag on `rg-shop-prod-app` says nothing about the machines inside it, unless something copies it down |

The third rule is the quiet one. **Azure keeps whatever case the first person typed for a name**, and
cost reports show it, so a report can carry `Cost-Centre` from one team and `cost-centre` from
another, which Azure treats as one tag and a spreadsheet treats as two columns. And a value typed
`CC-410` by one person and `cc-410` by another splits one cost centre's money into two rows.
**Agree the spelling once, write it down, and let a policy enforce it**, which is the next section.

The fourth rule is the expensive one, and it gets the whole next section.

## A tagging scheme, decided before the first resource

The shop's scheme is four tags, and every one answers a question somebody will ask about a cost:

| tag | example | the question |
|---|---|---|
| `cost-centre` | `cc-410` | whose budget pays for it? |
| `environment` | `prod` | can it be switched off at night? |
| `owner` | `checkout@shop.example` | who do we ask before deleting it? |
| `workload` | `checkout` | which product is it part of? |

`owner` is a shared mailbox, not a person, for the same reason as the budget's e-mail in lesson 13.
And none of them repeats what the resource id already says: the subscription and the resource group
are in every line of cost data whether or not anybody tags anything.

## Tags in Bicep

A tag is a property of a resource, so it goes in the file that creates the resource, and the cheap
way to keep a scheme consistent is to write it once as a parameter. Make the lesson's directory:

```sh
mkdir -p ~/azure/tags && cd ~/azure/tags
```

and save this as `pip.bicep`, a public IP address for the shop's web front, with the scheme as a
parameter and one tag of its own added:

```bicep
param tags object = {
  'cost-centre': 'cc-410'
  environment: 'prod'
  owner: 'checkout@shop.example'
  workload: 'checkout'
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-shop-web'
  location: resourceGroup().location
  tags: union(tags, {
    role: 'web'
  })
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
```

`union` merges two objects, so the resource gets the four tags of the scheme and `role: web` besides.
`cost-centre` is quoted because a hyphen is not allowed in a bare property name. Compile it:

```
ana@laptop:~/azure/tags$ az bicep build --file pip.bicep --stdout | jq '{default: .parameters.tags.defaultValue, tags: .resources[0].tags}'
{
  "default": {
    "cost-centre": "cc-410",
    "environment": "prod",
    "owner": "checkout@shop.example",
    "workload": "checkout"
  },
  "tags": "[union(parameters('tags'), createObject('role', 'web'))]"
}
```

The scheme travels as the parameter's default, and the resource's tags are an expression that
Resource Manager evaluates when the template arrives, as lesson 2 found for parents. Every file that
creates a resource for the shop can take the same `tags` parameter, and a deployment can pass a
different one for staging.

With an account, tags can also be set from the command line, `az tag update` on any resource id, and
in the portal. **Neither was run**, and both are how schemes decay: one resource tagged by hand,
with the case somebody felt like that day.
