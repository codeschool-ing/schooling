---
title: What each door checks before it knocks
version: 1
---

**The two declarative tools do their checking on your computer, and stop at the same line: the moment
they need to know what exists in Azure.** This section takes both files of the previous section as far
as the lab goes, and then one step further, to watch each stop.

## Bicep: build, and back

From `~/azure/doors`:

```
ana@laptop:~/azure/doors$ az bicep build --file main.bicep && jq -c '.resources[] | {type, apiVersion, name}' main.json
{"type":"Microsoft.Network/virtualNetworks","apiVersion":"2024-05-01","name":"vnet-shop-prod"}
```

The template is the ARM JSON the portal's *download a template* link produces, which is what makes the
two doors meet: **a template can be decompiled back to Bicep**. To see what survives the trip, drop the
part of the template that says Bicep made it, as a template exported from the portal would not have it,
and decompile that:

```
ana@laptop:~/azure/doors$ jq 'del(.metadata)' main.json > exported.json && az bicep decompile --file exported.json
WARNING: WARNING: Decompilation is a best-effort process, as there is no guaranteed mapping from ARM JSON to Bicep Template or Bicep Parameters.
You may need to fix warnings and errors in the generated bicep/bicepparam file(s), or decompilation may fail entirely if an accurate conversion is not possible.
If you would like to report any issues or inaccurate conversions, please see https://github.com/Azure/bicep/issues.

ana@laptop:~/azure/doors$ diff main.bicep exported.bicep
3c3
< resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
---
> resource vnet_shop_prod 'Microsoft.Network/virtualNetworks@2024-05-01' = {
23c23
< output vnetId string = vnet.id
---
> output vnetId string = vnet_shop_prod.id
```

The warning is fair, and the `diff` says how fair: **everything came back except the symbolic name**.
`vnet`, the name the file uses to refer to the resource, does not exist in the JSON, so the decompiler
made one up from the resource's own name. On a template from a real portal export the result needs
more tidying, with hard-coded values where parameters should be and properties Azure filled in that
nobody chose. It is a starting point, which is all Microsoft promises.

Bicep also knows each type's properties. Give the address space a string where the API wants a list,
saved as `typo.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
  properties: {
    addressSpace: {
      addressPrefixes: '10.20.0.0/16'
    }
  }
}
```

```
ana@laptop:~/azure/doors$ az bicep build --file typo.bicep --stdout > /dev/null
WARNING: /home/ana/azure/doors/typo.bicep(6,24) : Warning BCP036: The property "addressPrefixes" expected a value of type "null | string[]" but the provided value is of type "'10.20.0.0/16'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

`BCP036`, with the line and column, the type it expected and the one it got. **It is a warning, and the
file still compiled**, because Bicep's type definitions are generated from Microsoft's API descriptions
and are sometimes wrong; the message itself says to report it if so. Treat it as an error anyway: the
request it would produce is one Resource Manager refuses.

## Terraform: validate, and the graph

From `~/azure/doors/tf`:

```
ana@laptop:~/azure/doors/tf$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/doors/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/doors/tf$ terraform fmt -check
ana@laptop:~/azure/doors/tf$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "azurerm_resource_group.prod" [label="azurerm_resource_group.prod"];
  "azurerm_subnet.app" [label="azurerm_subnet.app"];
  "azurerm_virtual_network.prod" [label="azurerm_virtual_network.prod"];
  "azurerm_subnet.app" -> "azurerm_virtual_network.prod";
  "azurerm_virtual_network.prod" -> "azurerm_resource_group.prod";
}
```

`init` downloaded the provider again, although lesson 2 fetched the same version: **a directory with no
lock file does not trust the cache**, and Terraform takes a provider from it only when
`.terraform.lock.hcl` already records that provider's checksum. That file is the one `init` just
created; keep it beside the configuration, and every later `init` takes the cached copy. `validate` checked
every block against the provider's schema, and `terraform fmt -check` printed nothing, which is its way
of saying the file is laid out as Terraform lays it out. **The graph is what Terraform will do with the
three resources**: the subnet depends on the network and the network on the group, read from the
references between them, exactly as Resource Manager ordered lesson 25's network and subnet by
`dependsOn`.

## The step neither can take here

Both tools have a command that compares the file with what exists and says what would change, and
both need Resource Manager for it:

```
ana@laptop:~/azure/doors/tf$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azurerm"],
│   on main.tf line 10, in provider "azurerm":
│   10: provider "azurerm" {
│ 
╵
ana@laptop:~/azure/doors/tf$ az deployment group what-if --resource-group rg-shop-prod --template-file ../main.bicep
ERROR: Please run 'az login' to setup account.
```

`terraform plan` asked the Azure CLI for an identity, as in lesson 2, and stopped. **`what-if` is
Bicep's equivalent**: `az deployment group what-if` sends the template to Resource Manager, which
evaluates every expression against the real subscription and answers with each resource marked to be
created, modified, deleted or left alone, property by property. It was refused at the same place. **On
a real subscription this is the most important command in either tool**, because it is the last moment
a mistake costs nothing. Read its output before every deployment, the way you read a `diff` before a
commit.
