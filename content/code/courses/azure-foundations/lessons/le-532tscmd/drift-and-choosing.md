---
title: Drift, and choosing a door
version: 1
---

**Declaring the infrastructure only helps for as long as the file and Azure agree. The day somebody
changes a resource through another door, they stop agreeing, and that gap has a name: drift.** Nothing
in Azure prevents it. A colleague opens a port in the portal at two in the morning to stop an outage,
and the file in the repository still says the port is closed.

## How each tool sees drift

The two tools find drift in different places, because they remember different things:

- **Terraform keeps a state file**, its own record of every resource it created and the values it last
  saw. `terraform plan` refreshes that record from Azure, compares the three, file, state and reality,
  and proposes to put reality back to what the file says. A change made in the portal shows up as
  something Terraform will undo.
- **Bicep keeps no state.** Its memory is Resource Manager's: what exists now. `what-if` compares the
  template with what is there, and a property changed in the portal shows up as one the deployment will
  modify back.

**Either way, applying the file again undoes the change made by hand**, which is right if the change was
a mistake and an outage if it was the fix. So a change made through another door in an emergency has to
be written into the file the same day, and that is a rule about people, not tools.

**None of this was run**: drift needs a resource that exists, and a door that changed it.

## What a deployment does to what it does not mention

A Bicep or ARM deployment to a resource group runs in one of two **modes**, and the difference is what
happens to resources the template does not name:

| mode | resources in the group the template does not mention |
|---|---|
| incremental, the default | left alone |
| complete | deleted |

**Complete mode makes the group match the file exactly, and it deletes whatever somebody added by
hand**, which is why it is not the default and why `what-if` matters most before it. Microsoft's newer
answer to the same need is the **deployment stack**, which remembers the resources it deployed and can
delete or detach the ones that leave the file, and can deny changes to them from other doors.
Terraform behaves like a stack by construction: it deletes what leaves the file, and only what it
created. **None of these was run here.**

## Choosing a door

Each door has a job it does best:

- **the portal** for looking: what exists, what it costs, what the metrics say, and for learning what a
  service's settings are before writing them down;
- **the command line** for questions and for one-off actions, and for scripts that glue the others
  together, such as the step that runs a deployment in a pipeline;
- **a declarative file** for everything that should still exist next month: it is reviewed before it
  runs, it can build the same environment twice, and it is the record of why things are as they are.

Between the two declarative tools the choice is mostly about what else you manage. **Bicep is Azure's
own**: every new resource type and version is in it on the day it ships, there is no state file to look
after, and it needs nothing but the Azure CLI. **Terraform reaches other providers too**, Entra ID,
GitHub, a DNS host outside Azure, with one language and one workflow, at the price of a state file that
has to be stored, locked and protected. A team already writing Terraform for other systems has the
answer chosen for it.

::: track cloud-engineering
In your track `azure-operations` comes next, and its lessons 4 to 7 take both tools much further: modules,
parameters, deployment stacks, and Terraform's state kept in a storage account with a lock.
:::

::: track *
With a real subscription, the next step is the one this lab could not take: run `what-if` or
`terraform plan` against an empty resource group, read every line, and only then deploy.
:::
