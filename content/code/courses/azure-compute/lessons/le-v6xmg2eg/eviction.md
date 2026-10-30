---
title: Eviction, its two reasons and its two policies
version: 1
---

The usual worry about Spot is the price: it goes up, and the machine goes. That is one reason for an
eviction, and it is the one you can switch off. **A Spot machine is evicted when Azure needs the
capacity for pay-as-you-go work, or when the Spot price rises above the most you said you would
pay.** The first reason is always there. The second exists only if you set a maximum. And what is
left of the machine afterwards is a second decision, the eviction policy, made when the machine is
created.

## Capacity, and price if you ask for it

The portal calls the two choices *eviction types*, capacity only and price or capacity. The API has
no property of that name. **The eviction type is the value of `maxPrice`**:

- `-1` means the machine is never evicted for price. You pay the current Spot price, or the
  standard price if that is lower, and Microsoft's documentation is explicit that you are never
  charged above the standard price. Only capacity can take the machine.
- A number is a maximum in US dollars an hour, with up to five decimal places: `0.05` is five
  cents. The machine is evicted for capacity as before, and also whenever the Spot price rises above
  it.

A maximum does not lower the bill, since you pay the Spot price of the moment whatever it is. It
buys a ceiling on what one hour can cost, and pays for the ceiling in evictions. The documentation's
table of outcomes, in short:

| situation | what happens |
| --- | --- |
| creating a machine with a maximum at or above the current price | created, if there is capacity and quota |
| creating one with a maximum below the current price | not created: the error says the maximum must be at least the current price |
| the price rises above the maximum of a running machine | evicted, with notice attempted up to 30 seconds before |
| the price falls back after that eviction | nothing: the machine is not restarted, and if you restart it, it is charged at the current price |
| changing the maximum | only while the machine is deallocated |

The CLI's help gives the two choices a line each:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--eviction-policy : [^:]*: [A-Za-z, ]*\."
--eviction-policy : The eviction policy for the Spot priority virtual machine. Default eviction policy is Deallocate for a Spot priority virtual machine. Allowed values: Deallocate, Delete.
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--max-price \[Preview\] : [^.]*\. [^.]*\."
--max-price [Preview] : The maximum price (in US Dollars) you are willing to pay for a Spot VM/VMSS. -1 indicates that the Spot VM/VMSS should not be evicted for price reasons.
```

**Copying the portal's vocabulary into a file is the first mistake waiting here**, and the second is
writing `-1` as text. Both at once, into a copy of the previous section's file:

```
ana@laptop:~/azure$ sed -e "s/maxPrice: -1/maxPrice: '-1'/" -e "s/    evictionPolicy: 'Deallocate'/&\n    evictionType: 'CapacityOnly'/" report-vm.bicep > wrong.bicep
ana@laptop:~/azure$ diff report-vm.bicep wrong.bicep
12a13
>     evictionType: 'CapacityOnly'
14c15
<       maxPrice: -1
---
>       maxPrice: '-1'
ana@laptop:~/azure$ bicep build wrong.bicep
/home/ana/azure/wrong.bicep(13,5) : Warning BCP037: The property "evictionType" is not allowed on objects of type "VirtualMachineProperties". Permissible properties include "additionalCapabilities", "applicationProfile", "availabilitySet", "capacityReservation", "diagnosticsProfile", "extensionsTimeBudget", "host", "hostGroup", "licenseType", "platformFaultDomain", "proximityPlacementGroup", "scheduledEventsPolicy", "scheduledEventsProfile", "securityProfile", "userData", "virtualMachineScaleSet". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP037]
/home/ana/azure/wrong.bicep(15,17) : Warning BCP036: The property "maxPrice" expected a value of type "int | null" but the provided value is of type "'-1'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Both are caught. `evictionType` is not a property of a virtual machine at all, and the warning lists
what is; the quoted `'-1'` is text where the type wants a number. The second line of the warning has
a detail worth reading: the type says `int`. **Bicep has no decimal numbers**, and Microsoft's
Bicep documentation says so in a sentence, "floating point, decimal, or binary formats aren't
currently supported". So a maximum of five cents cannot be written the obvious way:

```
ana@laptop:~/azure$ sed "s/maxPrice: -1/maxPrice: 0.05/" report-vm.bicep > price.bicep
ana@laptop:~/azure$ bicep build price.bicep
/home/ana/azure/price.bicep(14,19) : Error BCP020: Expected a function or property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP020]
/home/ana/azure/price.bicep(14,19) : Error BCP236: Expected a new line or comma character at this location. [https://aka.ms/bicep/core-diagnostics#BCP236]
/home/ana/azure/price.bicep(14,19) : Error BCP022: Expected a property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP022]
/home/ana/azure/price.bicep(14,19) : Error BCP055: Cannot access properties of type "0". An "object" type is required. [https://aka.ms/bicep/core-diagnostics#BCP055]
/home/ana/azure/price.bicep(14,21) : Error BCP018: Expected the ":" character at this location. [https://aka.ms/bicep/core-diagnostics#BCP018]
ana@laptop:~/azure$ ls price.*
price.bicep
```

These are errors, not warnings. A warning, as lesson 1 showed, still writes a template; an error
writes none, which is why `ls` found only the `.bicep`. The way to write
a decimal in Bicep is the `json` function, which turns the text `'0.05'` into the JSON number
`0.05` when the template is deployed:

```
ana@laptop:~/azure$ sed -i "s/maxPrice: 0.05/maxPrice: json('0.05')/" price.bicep
ana@laptop:~/azure$ bicep build price.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.billingProfile" price.json
{
  "maxPrice": "[json('0.05')]"
}
```

That compiled with no warning, and the template carries the expression `[json('0.05')]` that Resource
Manager evaluates. The shop's report file keeps `-1`: a report that runs at night has no reason to
be evicted for price as well as for capacity.

## What is left afterwards

The eviction policy decides what the eviction leaves, and there are two:

| after an eviction | `Deallocate`, the default | `Delete` |
| --- | --- | --- |
| the machine | still there, stopped and deallocated | gone |
| its disks | kept, and billed | deleted with it |
| its cores | still counted against your Spot quota | released |
| its non-static IP addresses | released | gone with the machine |
| coming back | you start it again, in the same region and zone, when there is capacity; that may fail | you create a new one, of any size, anywhere |

**Deallocate keeps the machine and keeps charging for its disks while it waits.** The documentation
is careful to add that a restart is not guaranteed to succeed: capacity comes back when it comes
back, and a deallocated machine cannot move to another zone or region to find it. Something has to
keep trying, because nothing restarts it for you. Microsoft's guide suggests a scheduled pipeline
that attempts the restart until it works.

The quota line is the one people meet by surprise. Suppose, with an illustrative figure, a Spot quota
of 20 vCPUs, and ten `D2s_v5` machines evicted with `Deallocate`. All 20 vCPUs are still counted
against the quota by machines that are not running, so the replacements cannot be created until
somebody deletes the old ones or capacity returns and they restart.

**Delete leaves nothing to pay for and nothing to restart**, so the replacement has to come from
something outside the machine: a scale set raising its count, or your own automation. In exchange it
can be any size and any zone that has room, which the guide calls the more flexible policy and
recommends first when the work allows it. The same guide adds one detail that follows from Delete:
the operating system disk dies with the machine at every eviction, so an ephemeral OS disk, lesson
3's subject, costs nothing to lose and starts faster.

The guide's own rule of thumb for choosing:

- `Delete` when the work and its data are disposable, when you do not want to pay for disks
  between runs, and when the replacement can be a different size or zone.
- `Deallocate` when the work needs this exact size in this exact place, when installing it again
  takes long, and when waiting an unknown time for capacity is acceptable.

The shop's report machine keeps `Deallocate`: it is one machine, its tools are installed on its own
disk, and the report can wait for that machine to come back. Its work in progress is kept somewhere
else, as the next section explains. The scale set in this lesson's last section takes `Delete`.

## How often it happens

The rate is published, in two places, and neither is a promise. The portal shows an eviction rate
per size and region beside the price history, **quoted per hour**. In the documentation's words, a
rate of 10% means a 10% chance of the machine being evicted within the next hour, based on the last
seven days. Azure Resource Graph holds the same data in a table called `SpotResources`, with 90 days
of prices and the eviction rates of the last 28 days, which can be queried across sizes and
regions. The guide reports the rates in bands, 0 to 5%, 5 to 10% and so on up to 20% and more. None
of this was queried here, since every route to it needs a subscription; what this course can do is
the arithmetic with a rate, in the section after next.
