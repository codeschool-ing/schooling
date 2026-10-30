---
title: A resource is a URL, and creating it is a PUT
version: 1
---

**Resource Manager's API is REST in the plainest sense: every resource is a URL, and what you do to
it is the HTTP method.** The URL is the resource id from lesson 2 placed after
`https://management.azure.com`, with an `api-version` at the end. So the whole API is four verbs over
one shape:

| method | does | answers, when it works |
|---|---|---|
| `GET` | reads the resource, or lists a collection | 200 and the resource |
| `PUT` | creates it, or replaces it with the body sent | 200 if it replaced, 201 if it created, sometimes 202 |
| `PATCH` | changes only the fields sent, such as tags | 200 or 202 |
| `DELETE` | removes it | 200, 202, or 204 if there was nothing to remove |

**`PUT` is the one that matters, because it is idempotent**: sending the same body twice leaves the
resource exactly as sending it once. That single property is why Bicep and Terraform can describe a
whole environment and apply it again and again, which lesson 26 builds on.

## From a template to the requests

A compiled Bicep file already holds, for each resource, the type, the name, the `api-version` and the
body. A short program can lay out the request each one becomes. Save this Bicep file as `vnet.bicep` in
`~/azure/arm`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
  tags: {
    environment: 'prod'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
  }
}

resource app 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-app'
  properties: {
    addressPrefix: '10.20.2.0/24'
  }
}
```

and this program as `request.py`:

```schooling-example
{"language": "python", "file": "request.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"request.py TEMPLATE SUBSCRIPTION GROUP: the REST call each resource of a compiled template becomes.\"\"\"\nimport json\nimport sys\n\nARM = 'https://management.azure.com'\nLEFT_OUT = ('type', 'apiVersion', 'name', 'dependsOn', 'condition', 'copy')\n\ntemplate, sub, group = sys.argv[1], sys.argv[2], sys.argv[3]\nresources = json.load(open(template))['resources']\n\n", "note": "It reads a template `az bicep build` produced. `LEFT_OUT` are the fields a template uses to say *what* to create and *in what order*; they become the address and the sequence of requests, not the body."}, {"code": "for r in resources:\n    if r['name'].startswith('['):\n        print(f\"{r['type']}: the name is {r['name']}\")\n        print('  an expression, which only Resource Manager evaluates; no address can be written yet')\n        continue\n", "note": "A value in square brackets is a **template expression**, evaluated by Resource Manager when the deployment runs. The program refuses to guess what it becomes, and says so."}, {"code": "    namespace, *types = r['type'].split('/')\n    names = r['name'].split('/')\n    path = f'/subscriptions/{sub}/resourceGroups/{group}/providers/{namespace}'\n    for t, n in zip(types, names):\n        path += f'/{t}/{n}'\n", "note": "The address is the resource id of lesson 2, built from the pieces: the namespace, then each type paired with its name. A child resource has two of each."}, {"code": "    print(f\"PUT {ARM}{path}?api-version={r['apiVersion']}\")\n    body = {k: v for k, v in r.items() if k not in LEFT_OUT}\n    print(json.dumps(body, indent=2))\n", "note": "**`PUT` creates or replaces**: the body is the whole resource as it should be. The `api-version` is the version after the `@` in the Bicep file, and it decides which properties the body may carry."}]}
```

Compile the file, look at what each resource carries, and run the program with the shop's production
subscription and group:

```
ana@laptop:~/azure/arm$ az bicep build --file vnet.bicep && jq -c '.resources[] | {type, apiVersion, name, dependsOn}' vnet.json
{"type":"Microsoft.Network/virtualNetworks","apiVersion":"2024-05-01","name":"vnet-shop-prod","dependsOn":null}
{"type":"Microsoft.Network/virtualNetworks/subnets","apiVersion":"2024-05-01","name":"[format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]","dependsOn":["[resourceId('Microsoft.Network/virtualNetworks', 'vnet-shop-prod')]"]}
ana@laptop:~/azure/arm$ python3 request.py vnet.json bbbbcccc-1111-dddd-2222-eeee3333ffff rg-shop-prod
PUT https://management.azure.com/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod?api-version=2024-05-01
{
  "location": "brazilsouth",
  "tags": {
    "environment": "prod"
  },
  "properties": {
    "addressSpace": {
      "addressPrefixes": [
        "10.20.0.0/16"
      ]
    }
  }
}
Microsoft.Network/virtualNetworks/subnets: the name is [format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]
  an expression, which only Resource Manager evaluates; no address can be written yet
```

The network became a complete request: the address, the version, and a body of `location`, `tags` and
`properties`, the three parts every resource's body has. **The subnet did not**, and the reason is the
lesson. Its name in the template is `[format('{0}/{1}', 'vnet-shop-prod', 'snet-app')]`, an expression,
and it carries a `dependsOn` naming the network. Resource Manager evaluates the expression and **orders
the two requests by that dependency**: the network first, and the subnet only once the network exists.
A client that sent them in the wrong order would get the subnet refused, because its parent is not
there yet.

Sending the first one by hand is what `az rest` is for: it adds the token and the address of Resource
Manager, and sends any method with any body.

```
ana@laptop:~/azure/arm$ az rest --method put --url "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod?api-version=2024-05-01" --body @body.json
ERROR: Please run 'az login' to setup account.
```

Refused before it was sent, like every request of this course. It would also need a `body.json`, which
is the body the program printed.

## The `api-version` is a contract

Each resource type is published in dated versions of its API, and **the version decides which
properties exist and what they mean.** It is the date after the `@` in Bicep and the `api-version` in
the URL. A property added to networks in a 2024 version does not exist for a request that names a 2020
one, and is ignored or refused as unknown, depending on the provider. So a version is not a detail to bump
without reading what changed. A version Bicep has never heard of is a warning, not an error; save
this as `future.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2099-01-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
}
```

```
ana@laptop:~/azure/arm$ az bicep build --file future.bicep --stdout > /dev/null
WARNING: /home/ana/azure/arm/future.bicep(1,15) : Warning BCP081: Resource type "Microsoft.Network/virtualNetworks@2099-01-01" does not have types available. Bicep is unable to validate resource properties prior to deployment, but this will not block the resource from being deployed. [https://aka.ms/bicep/core-diagnostics#BCP081]
```

Bicep carries the definitions of every type it knows, and checks each property against the version
named. For an unknown version it cannot check anything, says so with `BCP081`, and compiles anyway:
the question of whether `2099-01-01` exists belongs to Resource Manager.

## Long operations

Some requests finish while you wait, and some cannot: a virtual network appears in seconds, a VPN
gateway takes tens of minutes. For those, Resource Manager answers **201 or 202** at once, with a
`provisioningState` that is not yet final and a header to poll: **`Azure-AsyncOperation`**, or
**`Location`** when that one is absent, and a **`Retry-After`** saying how many seconds to wait between
polls. The operation is finished when the state reads `Succeeded`, `Failed` or `Canceled`. The Azure CLI
does this polling for you, which is why `az network vnet-gateway create` sits silent for a long time;
`--no-wait` returns at once and leaves the polling to you. **None of it was run here**; the header names
and the three final states are Microsoft's documentation.
