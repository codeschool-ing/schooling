---
title: Azure Hybrid Benefit, and the licence you already paid for
version: 1
---

**A Windows virtual machine's price has two parts, the machine and the Windows licence, and the
bill shows them as one.** The same size of machine costs more with Windows than with Linux, and the
difference is Microsoft charging for Windows Server by the hour. A company that already owns Windows
Server or SQL Server licences for its own datacentre, with **Software Assurance** (Microsoft's
maintenance contract for licences) or as a subscription, would otherwise pay for the same licence
twice. **Azure Hybrid Benefit** is the agreement that it does not: you declare that a machine is
covered by a licence you own, and Azure charges for that machine at the base compute rate, the
price without the Windows part.

## What it covers, and who is responsible

| | the benefit |
|---|---|
| Windows Server | a machine declared under the benefit is billed at the base compute rate |
| SQL Server | SQL Server licences cover SQL Server on Azure virtual machines and Azure's managed SQL services; Standard and Enterprise licences convert at different ratios |
| Red Hat Enterprise Linux and SUSE Linux Enterprise | a related benefit that lets an existing subscription with Red Hat or SUSE cover the machine |
| moving in | Microsoft's documentation allows a licence that supports a migration to be used both in the datacentre and in Azure for up to 180 days |

**Azure does not check that you own the licence.** Declaring the benefit is a statement you make, and
it is audited the way software licensing is always audited: by the vendor, later, against your
records. A machine marked as covered when the company has no licence left is a cheaper bill this
month and a licensing liability afterwards. So the people who count licences, the procurement or
software asset team, have to agree with the number of machines that carry the flag. Microsoft's own
documentation says to start there, and it is the step most often skipped.

## Where the flag goes

On a virtual machine, the benefit is one property, `licenseType`. This lesson is not about machines,
which `azure-compute` builds whole; the fragment below carries only the properties this lesson is
about. Save it as `vm.bicep` in `~/azure/bill`:

```bicep
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-shop-reports'
  location: location
  properties: {
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
  }
}
```

Compile it, and then a copy where the value is misspelt:

```
ana@laptop:~/azure/bill$ az bicep build --file vm.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'
{"name":"vm-shop-reports","licenseType":"Windows_Server"}
ana@laptop:~/azure/bill$ sed "s/'Windows_Server'/'Windows_Sever'/" vm.bicep > typo.bicep
ana@laptop:~/azure/bill$ az bicep build --file typo.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'
{"name":"vm-shop-reports","licenseType":"Windows_Sever"}
```

**Both compiled.** Bicep knows `licenseType` as a string, as lesson 13 found for a budget's threshold
type, so `Windows_Sever` is a perfectly good string to it. Resource Manager is where the value is
checked. And notice what is missing without a word from the compiler: a real machine needs a disk,
an operating system profile and a network interface, and none of them is required by the type. **A
fragment that compiles is a fragment**, which is what lesson 1 meant by a file with the right shape.

## Reading it on the bill

The benefit shows on the bill as an absence: the hours of a covered Windows machine appear under the
compute meter alone, without the Windows licence meter beside them. Two checks follow, both in cost
analysis and both **not run here**:

- **group the virtual machines' costs by meter** and look for Windows licence meters on machines the
  company believes are covered. Each one is a licence paid twice;
- **count the machines carrying the flag** and compare with the number of licences the asset team
  says are available. More flags than licences is the liability described above.

For SQL Server, Microsoft also lets the benefit be managed centrally, at the scope of a subscription
or of the whole billing account, by assigning a number of licences rather than flagging machine by
machine, and Azure applies them to the SQL Server usage in that scope. The arithmetic of the previous section applies to
it too: a licence assigned to a machine that is off most of the month saves the licence price for
the hours it runs and nothing for the hours it does not.
