---
title: A Standard Load Balancer with a zone-redundant front end
version: 1
---

**A load balancer is four lists, and the rule is the one that joins the other three.** A front end
says where traffic arrives, a backend pool says where it may go, a probe says which members of the
pool are fit, and a rule says: traffic arriving at this front end on this port goes to this pool on
that port, for as long as the probe says yes. Everything else is detail, and most of it is in the
rule.

Make the lesson's directory:

```sh
mkdir -p ~/azure/balancing && cd ~/azure/balancing
```

Save this as `lb.bicep`. It is the shop's public load balancer, in front of the web tier, with a
public address customers reach on port 443:

```bicep
param location string = resourceGroup().location

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-shop-web'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource lb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'lb-shop-web'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe-web'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'be-web'
      }
    ]
    probes: [
      {
        name: 'probe-http'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/healthz'
          intervalInSeconds: 5
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rule-https'
        properties: {
          protocol: 'Tcp'
          frontendPort: 443
          backendPort: 443
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb-shop-web', 'fe-web')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-shop-web', 'be-web')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb-shop-web', 'probe-http')
          }
          disableOutboundSnat: true
        }
      }
    ]
  }
}
```

Read it as the four lists. `frontendIPConfigurations` holds one front end, `fe-web`, whose address
is the public IP `pip-shop-web` declared above it. `backendAddressPools` holds one empty pool,
`be-web`: the web tier's machines join it from their own side, through their network interfaces,
which is how Azure attaches a machine to a pool. `probes` holds `probe-http`, which asks every member
for `/healthz` over HTTP every five seconds. And `loadBalancingRules` holds the rule that names one
of each, by its id inside the load balancer.

Compile it, and ask the template what each resource says about zones:

```
ana@laptop:~/azure/balancing$ az bicep build --file lb.bicep --stdout | jq -c '.resources[] | {type, name, zones, sku: .sku.name}'
{"type":"Microsoft.Network/publicIPAddresses","name":"pip-shop-web","zones":["1","2","3"],"sku":"Standard"}
{"type":"Microsoft.Network/loadBalancers","name":"lb-shop-web","zones":null,"sku":"Standard"}
```

## Where the zones are

**The load balancer has no zones of its own, and its front end is zone-redundant anyway.** The
`zones` of the load balancer came back `null`, and the public address carries all three. In
Azure a Standard load balancer's front end takes its zone behaviour from the address it uses. An
address in zones 1, 2 and 3 is **zone-redundant**, served from all three, and survives losing any
one of them. An address in one zone only is **zonal**, and goes down with its zone. The load balancer
itself is a regional piece of Azure's network, not a machine sitting in a zone, which is why it has
nothing to say on the subject.

The pool is the other half. A zone-redundant front end in front of three machines all in zone 1 has
moved the single point of failure without removing it. **The front end survives a zone; the
service survives only if the pool does too**, which means machines in at least two zones, and a
probe that notices when a zone's machines stop answering.

## What the rule hides

Two settings in the rule look like detail and decide behaviour:

- **`disableOutboundSnat: true`** stops the machines in the pool from using this front end's
  address for connections *they* open to the internet. Microsoft recommends exactly that, and gives
  outbound traffic its own way out: a NAT gateway on the subnet, or an outbound rule. Without it,
  a busy pool runs short of source ports on one shared address, and outbound connections start
  failing in a way that looks like a fault in the remote service.
- **No session persistence** is set, so the default holds: each new flow is placed by the hash of
  its five-tuple. A user who opens two connections may reach two machines. An application that keeps
  a session in a machine's memory needs either a client-IP persistence setting or, better, a session
  that lives somewhere else.

**The compiler checked the shape and nothing else.** That `Standard` is a SKU the region sells, that
a public address with `zones` is allowed in `brazilsouth`, that the probe's path exists on the
machines: each is a fact about Azure, and only a deployment would find out. Deploying the file would
be `az deployment group create --resource-group rg-shop-prod --template-file lb.bicep`, and **it was
not run**, for the reason every lesson gives: it is a request to Resource Manager.

## An internal one, and an Application Gateway, in words

The internal load balancer in front of the application tier is the same file with one change: the
front end takes a private address from `snet-app` instead of a public IP, through a `subnet` and a
`privateIPAddress` in place of `publicIPAddress`. Everything else, the pool, the probe, the rule, is
identical, and that is the point of the four lists.

An Application Gateway in Bicep is longer, because a reverse proxy has more lists: listeners for each
host name and port, HTTP settings for how it talks to the backends, routing rules joining a listener
to a pool, and a URL path map when `/api/` goes elsewhere. It deploys into `snet-agw` and nothing else
may share that subnet. This lesson leaves it in words; the shape is the same idea, more of it.
