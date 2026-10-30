---
title: The tunnel, written in Bicep
version: 1
---

**A site-to-site VPN in Azure is four resources, and only one of them is the tunnel.** The gateway is
Azure's end. A **local network gateway** is Azure's description of *your* end: the public address of
the office firewall and what lies behind it. A **connection** joins the two and carries the shared
secret. And the gateway needs its subnet and its public addresses before any of that.

Make the lesson's directory:

```sh
mkdir -p ~/azure/hybrid && cd ~/azure/hybrid
```

Save this as `vpn.bicep`. It adds the gateway subnet to the hub network, which exists already, and
builds the rest:

```bicep
param location string = resourceGroup().location

@secure()
@description('The pre-shared key both ends of the tunnel agree on. Given at deployment, never written here.')
param sharedKey string

resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-hub'
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: hub
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: '10.0.255.0/27'
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for n in [1, 2]: {
  name: 'pip-vpng-shop-${n}'
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
}]

resource vpng 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: 'vpng-shop'
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    activeActive: true
    enableBgp: true
    bgpSettings: {
      asn: 65515
    }
    ipConfigurations: [for n in [0, 1]: {
      name: 'ipconfig${n + 1}'
      properties: {
        subnet: {
          id: gatewaySubnet.id
        }
        publicIPAddress: {
          id: pip[n].id
        }
      }
    }]
  }
}

resource office 'Microsoft.Network/localNetworkGateways@2024-05-01' = {
  name: 'lgw-shop-office'
  location: location
  properties: {
    gatewayIpAddress: '203.0.113.10'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.255.1/32'
      ]
    }
    bgpSettings: {
      asn: 65010
      bgpPeeringAddress: '192.168.255.1'
    }
  }
}

resource connection 'Microsoft.Network/connections@2024-05-01' = {
  name: 'cn-shop-office'
  location: location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpng.id
      properties: {}
    }
    localNetworkGateway2: {
      id: office.id
      properties: {}
    }
    sharedKey: sharedKey
    enableBgp: true
  }
}
```

Five things in it are worth a sentence each.

- **`existing`** names a resource without creating it: the hub network was built in another lesson, and
  this file only needs to hang a subnet under it. The subnet's name is `GatewaySubnet`, exactly.
- **`[for n in [1, 2]: ...]`** makes two public addresses from one block, `pip-vpng-shop-1` and
  `pip-vpng-shop-2`, and `pip[n].id` picks them up again in the gateway's two `ipConfigurations`.
  Two addresses because `activeActive` is `true`.
- **`asn: 65515`** is the gateway's BGP number. It is the number Azure gives a VPN gateway by default,
  and the office firewall uses a private number of its own, `65010`, in the local network gateway.
- **`localNetworkAddressSpace` holds one `/32`**, the address the office firewall uses for BGP, and
  not the office's `192.168.0.0/16`. With BGP on, the firewall tells Azure which networks are behind it,
  and the only route Azure must know beforehand is the one to reach the firewall's BGP session.
- **`sharedKey` is a parameter marked `@secure()`**, with no default. Its value is given when the
  file is deployed, and the template never carries it.

Compile it and read what the template says about its parameters and resources:

```
ana@laptop:~/azure/hybrid$ az bicep build --file vpn.bicep --stdout | jq -c '.parameters, [.resources[] | {type, name}]'
{"location":{"type":"string","defaultValue":"[resourceGroup().location]"},"sharedKey":{"type":"securestring","metadata":{"description":"The pre-shared key both ends of the tunnel agree on. Given at deployment, never written here."}}}
[{"type":"Microsoft.Network/virtualNetworks/subnets","name":"[format('{0}/{1}', 'vnet-shop-hub', 'GatewaySubnet')]"},{"type":"Microsoft.Network/publicIPAddresses","name":"[format('pip-vpng-shop-{0}', createArray(1, 2)[copyIndex()])]"},{"type":"Microsoft.Network/virtualNetworkGateways","name":"vpng-shop"},{"type":"Microsoft.Network/localNetworkGateways","name":"lgw-shop-office"},{"type":"Microsoft.Network/connections","name":"cn-shop-office"}]
```

**`sharedKey` became a `securestring`**, which Resource Manager keeps out of the deployment's history
and its logs. The two addresses are one resource with a `copyIndex()` in its name, a loop the
template carries for Resource Manager to unroll.

## The mistake the compiler does catch

A shared key is a password both ends of the tunnel hold. The convenient mistake is to write it into
the file, so that a deployment needs no extra argument. Make that mistake on purpose, in a copy:

```sh
sed 's/^param sharedKey string$/param sharedKey string = '"'"'office-tunnel-2026'"'"'/' vpn.bicep > leaky.bicep
```

```
ana@laptop:~/azure/hybrid$ az bicep build --file leaky.bicep --stdout > /dev/null
WARNING: /home/ana/azure/hybrid/leaky.bicep(5,24) : Warning secure-parameter-default: Secure parameters should not have hardcoded defaults (except for empty or newGuid()). [https://aka.ms/bicep/linter-diagnostics#secure-parameter-default]
```

**The file still compiled, and the linter objected**: `secure-parameter-default` says a secure
parameter must not carry a written value, because that value is now in the file, in the repository it
is committed to, and in every copy of both. It is a warning and not an error, so nothing stops a
deployment; a pipeline that treats Bicep's warnings as failures is how a team stops it. Delete the copy
with `rm leaky.bicep`.

**Deploying `vpn.bicep` was not run**: like every resource in this course it needs Resource Manager,
and here it would also need a real firewall at `203.0.113.10`, an address from a range reserved for
documentation, to answer.

## BGP, in one paragraph and one rule

Without BGP, each side holds a static list of the other's networks, typed by somebody, and a network
added in the office is unreachable from Azure until somebody types it again on the Azure side. **With
BGP, the two ends tell each other what they can reach**, keep telling each other every few seconds,
and withdraw a route the moment its tunnel dies. That is what makes several tunnels at once workable:
each side always knows which tunnels are alive. The one rule BGP adds is about numbers: the two ends
need **different autonomous system numbers**, and a private network takes them from the private range,
which is why the office is `65010` and Azure keeps its `65515`.
