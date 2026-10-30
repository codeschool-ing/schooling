---
title: What the lab answers, and what it cannot
version: 1
---

**Nothing on your computer answers like Azure's control plane.** The control plane is Azure Resource
Manager, the API behind every subscription, resource group, virtual machine, role assignment and alert
rule, and no emulator of it exists. The AWS world has moto, which imitates most of that API; Azure has
nothing comparable, and the course will not pretend otherwise by writing a script that prints what
Azure would have said. So the command line, asked for anything Resource Manager owns, stops at the
first step:

```
ana@laptop:~/azure$ az group list
ERROR: Please run 'az login' to setup account.
```

That message is the line between the two halves of this course. **What runs on your computer is
captured**: every transcript in these lessons was run, and the output is pasted as it was printed.
**What needs Resource Manager is taught from Microsoft's documentation and marked as not run**, with no
transcript and no invented output.

## Where the line falls

| what the course does | what you run | what is read, not run |
|---|---|---|
| pipelines and deployments | the YAML, read line by line | a pipeline run, an approval, a slot swap |
| Bicep and ARM | `bicep build`, `bicep lint`, `bicep decompile` | a deployment, `what-if`, a deployment stack |
| Terraform | `init`, `validate`, `fmt`; the state's blob and its lock, in Azurite | `plan` and `apply` against a subscription |
| monitoring | KQL, in the Kusto emulator, over tables you load | metrics and logs flowing from real resources |
| alerts | the query a log alert runs, evaluated by you | an alert firing, an e-mail arriving |
| security | the Bicep that declares a vault, a firewall policy, a private endpoint | Defender's findings, a vault's refusal |
| cost | KQL over a cost export you build | the bill itself |

Read the "not run" sentences as seriously as the transcripts. A Bicep file that compiles proves that it
is well formed, and nothing about whether Azure would accept it from you.

## Prices

Every number about money in this course is Microsoft's list price, and **the machine this course was
recorded on could not reach Microsoft's price list**: the public Retail Prices API at
`prices.azure.com` was outside its network. So where a lesson does arithmetic with a price, it says
the price is round and illustrative, and you check today's figure yourself. The API needs no account:

```sh
curl -sG https://prices.azure.com/api/retail/prices \
  --data-urlencode "\$filter=serviceName eq 'Log Analytics' and armRegionName eq 'brazilsouth'" \
  | jq -r '.Items[] | [.meterName, .retailPrice, .unitOfMeasure] | @tsv'
```

That command was **not run** for this course, for the reason above. It prints one line per meter, in US
dollars, for the region `brazilsouth`, which is the region every example in this course uses.

## A real subscription, if you want one

Nothing in this course needs a real Azure subscription. **If you open one anyway**, `azure-foundations`
lesson 1 has the section on doing it safely, and the order is the part to remember: multi-factor
authentication on the account, then a budget with an alert, before anything else. A free allowance is
one possibility for a small bill, never a promise: what it covers changes, and a forgotten resource is
billed whether or not you meant to keep it. Those steps were not run for this course. Two rules hold
either way: **never put a real secret in a file this course has you create**, and remember that the
Bicep and Terraform in these lessons, pointed at a real subscription, create things that are billed by
the hour.
