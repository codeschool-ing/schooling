---
title: "Sizes, and what happens when the process exits"
version: 1
---

A container group is sized by what its containers ask for, not by a menu of machine sizes like
lesson 1's, and it is billed per second for what it was given. **Two numbers per container decide
the size, and one setting per group decides what happens when a process ends.** Both are fixed
for the life of the group: changing either means deleting the group and creating it again. This
section declares the shop's group in Bicep, compiles it, and runs the restart policies' Docker
equivalents on the laptop, because a restart policy only shows itself when something exits.

## Requests and limits

Every container states a **request**: how many CPU cores and how many gigabytes of memory it
needs. The request is compulsory, and it is what the group is allocated. A container may also
state a **limit**, which must be at least its request, and lets it use more when the group has
room. Microsoft's documentation describes the arithmetic with two containers each requesting one
CPU. The group is allocated two, and either container may be given a limit of up to two, the
group's whole allocation, so that it can borrow what the other is not using. Without a limit, a
container's ceiling is its request.

The group as a whole has a floor and a ceiling. Microsoft's documentation, read on 30 October 2026,
sets the floor at **1 CPU and 1 GB for a group**, while a single container inside one may request
less, and the ceiling for a standard group at 31 CPUs and 240 GB. It also warns that groups above 4
CPUs and 16 GB may fail to deploy when a region is short of capacity. A small part of what a group
is allocated goes to the service's own processes, so a container that requests exactly what the
program needs will have slightly less than that.

The command line says what it accepts. Asked about the four settings of this section:

```
ana@laptop:~/azure$ az container create --help | awk '/^    --/{p=0} /^    --(cpu|memory|ports|restart-policy) /{p=1} p'
    --cpu                                          : The required number of CPU cores of the
                                                     containers, accurate to one decimal place.
    --memory                                       : The required memory of the containers in GB,
                                                     accurate to one decimal place.
    --ports                                        : A list of ports to open. Space-separated list
                                                     of ports.  Default: [80].
    --restart-policy                               : Restart policy for all containers within the
                                                     container group.  Allowed values: Always,
                                                     Never, OnFailure.
```

CPU and memory go to one decimal place, and the restart policy takes three values, which the next
part of this section is about. Look at `--ports`. **Leave it out and the CLI opens port 80**,
which nothing in the shop listens on: a group created from flags with no `--ports 8080` starts,
runs, and answers nobody.

## The group in Bicep

The YAML file of the previous section, as a Bicep declaration. Save it as `~/azure/shop.bicep`:

```bicep
// shop.bicep
param location string = 'brazilsouth'
param image string = 'shopregistry.azurecr.io/shop:1.0'

resource shop 'Microsoft.ContainerInstance/containerGroups@2025-09-01' = {
  name: 'shop'
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    containers: [
      {
        name: 'shop'
        properties: {
          image: image
          environmentVariables: [
            { name: 'SHOP_VERSION', value: '1.0' }
          ]
          ports: [
            { port: 8080, protocol: 'TCP' }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: json('1.5')
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: 'shop-sp'
      ports: [
        { port: 8080, protocol: 'TCP' }
      ]
    }
  }
}

output fqdn string = shop.properties.ipAddress.fqdn
```

The API version is a newer one than the YAML file's, `2025-09-01`, the newest this compiler has
types for; the properties used here are the same in both. Compiled:

```
ana@laptop:~/azure$ bicep build shop.bicep
ana@laptop:~/azure$ ls shop.*
shop.bicep
shop.json
ana@laptop:~/azure$ jq ".resources[0].properties.containers[0].properties.resources" shop.json
{
  "requests": {
    "cpu": 1,
    "memoryInGB": "[json('1.5')]"
  }
}
```

No warnings, and a template beside the file. **The odd line is `json('1.5')`.** Bicep has whole
numbers and no others, so a memory of one and a half gigabytes cannot be written as a number. The
`json` function reads the text `'1.5'` as JSON, and the template carries it as an expression that
Resource Manager evaluates into 1.5 when it deploys. Writing the number plainly is not a warning,
it is a file the compiler cannot read:

```
ana@laptop:~/azure$ sed "s/json('1.5')/1.5/" shop.bicep > float.bicep
ana@laptop:~/azure$ bicep build float.bicep
/home/ana/azure/float.bicep(25,29) : Error BCP020: Expected a function or property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP020]
/home/ana/azure/float.bicep(25,29) : Error BCP236: Expected a new line or comma character at this location. [https://aka.ms/bicep/core-diagnostics#BCP236]
/home/ana/azure/float.bicep(25,29) : Error BCP022: Expected a property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP022]
/home/ana/azure/float.bicep(25,29) : Error BCP055: Cannot access properties of type "1". An "object" type is required. [https://aka.ms/bicep/core-diagnostics#BCP055]
/home/ana/azure/float.bicep(25,30) : Error BCP018: Expected the ":" character at this location. [https://aka.ms/bicep/core-diagnostics#BCP018]
ana@laptop:~/azure$ ls float.*
float.bicep
```

Five errors on line 25, all of them the compiler failing to make sense of the dot after the 1,
and no `float.json`: unlike a warning, an error writes no template.

### What the compiler lets through

Bicep's types for the restart policy accept the three words and, beside them, any other text.
A misspelt policy therefore compiles without a word, while the CLI, which carries its own list of
allowed values, refuses the same mistake at once:

```
ana@laptop:~/azure$ sed "s/'Always'/'OnFaliure'/" shop.bicep > typo.bicep
ana@laptop:~/azure$ bicep build typo.bicep
ana@laptop:~/azure$ jq -r ".resources[0].properties.restartPolicy" typo.json
OnFaliure
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --restart-policy OnFaliure 2>&1 | head -n 1
ERROR: az container create: 'OnFaliure' is not a valid value for '--restart-policy'. Allowed values: Always, OnFailure, Never.
```

The template now asks Azure for a restart policy called `OnFaliure`, and only Azure can say what
it does with that. **The compiler checks the names and the types, and not every value.** Read a
restart policy, an IP address type and a SKU yourself before a deployment does it for you.

## The three restart policies

The policy belongs to the group and applies to every container in it. Microsoft's documentation
defines the three:

| policy | a container that exits is restarted | fits |
|---|---|---|
| `Always`, the default | whatever its exit code | a server, which should never stop |
| `OnFailure` | only if its exit code is not 0 | a job that should finish once, and try again if it fails |
| `Never` | not after exit code 0; after a failure the platform may still restart it | a job that must not run twice after succeeding |

**For the shop's order API the policy is `Always`**, and so is the default: a server that exits
has failed, whatever its code, and should come back. **For the nightly sales report it is
`OnFailure`**: the report runs, writes its file, exits 0, and the group stops, with its state
shown as *Terminated* and its billing stopped with it. A report that crashes halfway exits with
an error and is started again. Pay attention to the note on `Never`. The documentation says a
container that exits with a non-zero code may be restarted by the platform even then, so a job
that must run at most once has to catch its own failures and exit 0.

Docker has the same three ideas under its own names, `always`, `on-failure` and `no`, and runs
them on your laptop, which Container Instances cannot. A report that fails every time, started
with `on-failure` and Docker's optional cap of three retries:

```
ana@laptop:~/azure$ docker run -d --name report --restart on-failure:3 shop:1.0 python -c "import sys; print('report failed'); sys.exit(1)" > /dev/null
ana@laptop:~/azure$ docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report
3 exited 1
ana@laptop:~/azure$ docker logs report
report failed
report failed
report failed
report failed
```

Four runs, the first and three restarts, and then Docker stopped trying, with the container left
`exited` with code 1. The same policy with a report that succeeds:

```
ana@laptop:~/azure$ docker run -d --name report-ok --restart on-failure:3 shop:1.0 python -c "print('report written')" > /dev/null
ana@laptop:~/azure$ docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report-ok
0 exited 0
ana@laptop:~/azure$ docker logs report-ok
report written
```

No restart, because a code of 0 means done. Container Instances documents no retry cap for
`OnFailure`, and Docker's `:3` is Docker's own; the two meanings of the policy are the same.

**A restart starts from nothing.** Run the shop, give it an order, and restart it:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8080/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ docker restart shop
shop
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/orders
[]
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "ed31bcd5ec6c", "up_s": 0.7}
```

The order is gone and `up_s` started again, because `ORDERS` lived in the process. In Container
Instances a restart can also change the group's IP address, as section 02 said. Anything that has
to survive goes into a database, or onto an Azure Files share mounted as a volume.

## Spot and confidential groups

Two variants of the group are chosen by one property each.

**Spot**, `priority: 'Spot'`, runs the group on spare capacity at a discount that Microsoft's
documentation, read on 30 October 2026, puts at up to 70%. Lesson 5 is about Spot virtual
machines, and the container version differs in ways that matter. There is no eviction policy to
choose: an evicted group is restarted by Azure on its own. A Spot group has no public address, no
place in a virtual network and no confidential SKU, and is limited to 4 CPUs and 16 GB. **It is
in preview, and offered in three regions, East US 2, West Europe and West US**, so not in
`brazilsouth`. The compiler accepts one there all the same, because it checks types and not
regions. Here is the shop's file with one line added after the restart policy:

```
ana@laptop:~/azure$ sed "s/restartPolicy: 'Always'/&\n    priority: 'Spot'/" shop.bicep > spot.bicep
ana@laptop:~/azure$ grep -n -A1 restartPolicy spot.bicep
10:    restartPolicy: 'Always'
11-    priority: 'Spot'
ana@laptop:~/azure$ bicep build spot.bicep
ana@laptop:~/azure$ jq -r ".resources[0].properties.priority" spot.json
Spot
```

A template asking for a Spot group in São Paulo, written without a word of warning. Only the
deployment would find out that the region does not offer it.

**Confidential**, `sku: 'Confidential'`, runs the group inside a trusted execution environment on
AMD SEV-SNP processors, with its memory encrypted by a key the processor holds. It also lets the
group prove to a remote party what it is running before that party releases a secret to it. What may run
inside is fixed by a policy, which Microsoft says must be generated by the CLI's `confcom`
extension and cannot be written by hand. It is for data that the people running the hardware are
not allowed to see; the shop's orders are not that.

## Changing a group later

A group is updated by running the create again with the same name and at least one changed
property, and every container in it restarts in place. Some properties cannot change that way.
**The restart policy, the CPU and memory, the operating system, the network profile and the
availability zone** can be changed only by deleting the group and creating it anew, which pulls
the image again from scratch and may give it a new address. Choose them as if they were permanent,
because for the life of the group they are.
