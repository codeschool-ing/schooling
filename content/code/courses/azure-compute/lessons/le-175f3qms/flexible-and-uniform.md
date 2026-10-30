---
title: "Flexible and Uniform: two ways to hold the instances"
version: 1
---

A scale set has an **orchestration mode**, and it is chosen once: Microsoft's documentation says the
mode is set when the scale set is created and cannot be changed afterwards. The picture many people
carry is that Uniform is the real scale set and Flexible a variant for unusual cases. It is the
other way round now. **Flexible is the mode Microsoft recommends for new scale sets, and it is what
the Azure CLI creates when you do not say:**

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Flexible, Uniform. Default: [A-Za-z]*"
Allowed values: Flexible, Uniform. Default: Flexible
```

Uniform is the older mode, and it is still the right answer in a few named places.

## What the difference is

The difference is what kind of resource an instance is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Two panels. Left, Flexible: inside a resource group, the scale set shop-vmss holds the model and the count, and three separate resources of type virtualMachines, each with its own disk, network interface and tags, are members of it. Right, Uniform: the scale set shop-vmss contains three instances of type virtualMachines numbered 0, 1 and 2, which are its children and are managed through the scale set’s API.\"><text x=\"184\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Flexible: each instance is a VM</text><text x=\"536\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Uniform: instances live inside the set</text><rect x=\"16\" y=\"36\" width=\"336\" height=\"270\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resource group</text><rect x=\"56\" y=\"66\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-vmss</text><text x=\"184\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the model and the count</text><text x=\"338\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">members of the set</text><path d=\"M184 116 L80 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"32\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"80\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">its own disk, NIC</text><text x=\"80\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">and tags</text><path d=\"M184 116 L184 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"136\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"184\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">its own disk, NIC</text><text x=\"184\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">and tags</text><path d=\"M184 116 L288 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"240\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"288\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"288\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">its own disk, NIC</text><text x=\"288\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">and tags</text><rect x=\"368\" y=\"36\" width=\"336\" height=\"270\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"380\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resource group</text><rect x=\"392\" y=\"66\" width=\"288\" height=\"226\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-vmss</text><text x=\"536\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the model and the count</text><text x=\"536\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the scale set’s children</text><rect x=\"404\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"446\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">0</text><rect x=\"496\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"538\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">1</text><rect x=\"588\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"630\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">2</text><text x=\"536\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">managed through the scale set’s API</text></svg>", "caption": "The same three instances in the two modes. In Flexible mode they are ordinary virtual machines that belong to the set; in Uniform mode they exist only inside it, addressed by a number."}
```

**In a Flexible scale set every instance is an ordinary virtual machine**, of type
`Microsoft.Compute/virtualMachines`. Its network interface and disk are separate resources of its
own.
What works on a virtual machine works on it: tags, a role assignment on that one machine, Azure
Backup, Azure Site Recovery, the `az vm` commands lesson 1 read. A virtual machine that already
exists can be attached to a Flexible set. When an instance is deleted, you choose whether its disks
and network interface go with it.

**In a Uniform scale set the instances belong to the scale set**, as
`Microsoft.Compute/virtualMachineScaleSets/virtualMachines`, addressed by a number inside it and
managed through the scale set's own API. Microsoft's comparison says they are not compatible with the
standard virtual machine commands, with Resource Manager tagging, with role assignments, with Azure
Backup or with Site Recovery. The set is managed as a whole. That is what made it simple, and why it
was the first kind of scale set.

The same comparison lists two things only Uniform supports: Service Fabric, and AKS, which builds its
node pools on scale sets and is where lesson 11 begins. Uniform also has a second way to report
health, the load balancer's probe. Flexible accepts only the Application Health extension, which
section 05 installs. And two differences matter on the first day. A Flexible set has no default
outbound internet access, so its instances reach the internet only through something you set up, such
as a NAT gateway or the load balancer's outbound rules. And a Flexible set takes only a user-assigned
managed identity, the kind `azure-foundations` lesson 8 creates as its own resource.

## Mixing what Uniform would not

A Flexible scale set does not have to be made of one size. **Instance mix** lists up to five sizes in
a `skuProfile`, sets `sku.name` to `Mix`, and lets Azure choose among them at each scale-out with an
allocation strategy:

- `lowestPrice`, the default, which takes the cheapest size it can get;
- `capacityOptimized`, for when getting a machine at all matters more than what it costs;
- `Prioritized`, in preview on 2026-10-30, which follows a ranking you write.

It exists only in Flexible mode, and the sizes in the list have to agree on processor architecture,
storage interface, local disk and security profile. For the shop, listing `Standard_D2s_v5` and
`Standard_D2as_v5`, an Intel and an AMD size of the same shape, makes a scale-out in São Paulo less
likely to fail on a shortage of one of them. The same mode lets Spot and regular instances share a
set, which lesson 5 uses, and lets Linux and Windows share one.

## Fault domains and placement groups

The other two of the shop's three lines are about where in a datacentre the instances land.

**`platformFaultDomainCount` is how many fault domains the instances are spread over**, a fault domain
being a group of hardware that shares power, network and maintenance. `1` does not mean "all in one".
It means **max spreading**: Azure spreads the instances over as many fault domains as it can, and the
instance view shows a single fault domain because the spreading is implicit. A number above 1 is
fixed spreading, over exactly that many. For a Flexible set the documented values are `1`, `2` or `3`
when the set is regional, and only `1` when it uses zones, as the shop's does. Uniform accepts `1` or
`5` across zones and `1` to `5` in a region, where `5` is its default.

**`singlePlacementGroup` comes from Uniform.** A placement group behaves like an availability set,
with its own fault domains, and one group holds at most 100 instances; set to `false`, a Uniform set
may span several groups and grow to 1,000. Flexible does not use it the same way. Its orchestration
page lists single placement group among the parameters Flexible does not support and says it can be
left null for the platform to choose. The shop's file writes `false`, as Microsoft's own Flexible
template does.

## What the compiler checks, and what it lets through

Here is the shop's file with three mistakes typed into a copy: the mode shortened to `Flex`, fixed
spreading over three fault domains in a set that spans zones, and a letter dropped from a property
name:

```
ana@laptop:~/azure$ sed -e "s/'Flexible'/'Flex'/" -e 's/platformFaultDomainCount: 1/platformFaultDomainCount: 3/' -e 's/singlePlacementGroup/singlePlacmentGroup/' shop-vmss.bicep > flex-wrong.bicep
ana@laptop:~/azure$ diff shop-vmss.bicep flex-wrong.bicep
43,45c43,45
<     orchestrationMode: 'Flexible'
<     platformFaultDomainCount: 1
<     singlePlacementGroup: false
---
>     orchestrationMode: 'Flex'
>     platformFaultDomainCount: 3
>     singlePlacmentGroup: false
ana@laptop:~/azure$ bicep build flex-wrong.bicep
/home/ana/azure/flex-wrong.bicep(45,5) : Warning BCP089: The property "singlePlacmentGroup" is not allowed on objects of type "VirtualMachineScaleSetProperties". Did you mean "singlePlacementGroup"? [https://aka.ms/bicep/core-diagnostics#BCP089]
```

**One warning, for three mistakes.** The misspelt property was caught, with the right spelling
offered, because the compiler knows every property a scale set has. The other two compiled cleanly.
The mode is typed in Microsoft's published definition as one of the two words *or any other string*,
so `Flex` is a string and passes. The fault domain count is typed as a number, and `3` is a number.
The rule that a Flexible set with zones takes only `1` is in the compute service's documentation,
not in the type. So it can only be checked once Resource Manager receives the request, and a laptop
cannot find out how it answers.

That is lesson 1's rule seen from the other side. **No warning means the shape is right, not that the
values are.** Where a property has a short list of meanings, compare the value with the documentation
yourself.
