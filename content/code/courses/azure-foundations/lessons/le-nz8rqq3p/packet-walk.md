---
title: Walking a packet through the rules
version: 1
---

**The question an NSG answers is always about one packet: from here, to there, on this port, is the
first matching rule an allow?** Azure answers it with a tool called IP flow verify, in Network
Watcher, and shows the merged list for a machine as its *effective security rules*. Both need a
machine in Azure. What the lab can do is follow the same documented rules by hand, and a short
program follows them faster than a person.

Save this as `~/azure/nsg/nsg.py`:

```schooling-example
{"language": "python", "file": "nsg.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"nsg.py TEMPLATE SOURCE DEST PORT: the course's model of one NSG judging an inbound TCP packet.\n\nA model of Azure's documented rules, not Azure: it reads the NSG out of a compiled template.\"\"\"\nimport ipaddress\nimport json\nimport re\nimport sys\n\nVNET = ipaddress.ip_network('10.20.0.0/16')\nPROBE = ipaddress.ip_address('168.63.129.16')\nMEMBERS = {'10.20.1.4': 'asg-shop-web', '10.20.1.5': 'asg-shop-web', '10.20.2.4': 'asg-shop-app'}\n\n", "note": "**This is the course's model, not Azure.** It reads one NSG out of a compiled template and follows the rules Microsoft documents. `VNET` is the shop's network, `PROBE` the address Azure's health probes come from, and `MEMBERS` stands in for the interfaces Azure would know are in each ASG: here, two web servers and one application server."}, {"code": "DEFAULTS = [\n    {'name': 'AllowVnetInBound', 'priority': 65000, 'access': 'Allow',\n     'source': 'VirtualNetwork', 'dest': 'VirtualNetwork', 'port': '*'},\n    {'name': 'AllowAzureLoadBalancerInBound', 'priority': 65001, 'access': 'Allow',\n     'source': 'AzureLoadBalancer', 'dest': '*', 'port': '*'},\n    {'name': 'DenyAllInBound', 'priority': 65500, 'access': 'Deny',\n     'source': '*', 'dest': '*', 'port': '*'},\n]\n\n\n", "note": "The three inbound defaults, at the priorities Azure gives them. Every NSG has them, so the model adds them to whatever the template says."}, {"code": "def side(p, which):\n    groups = p.get(which + 'ApplicationSecurityGroups')\n    if groups:\n        return 'asg:' + re.findall(r\"'([^']+)'\", groups[0]['id'])[-1]\n    return p.get(which + 'AddressPrefix', '*')\n\n\n", "note": "A side of a rule is an ASG or an address prefix. In the template an ASG is a `resourceId(...)` expression, and its last quoted word is its name."}, {"code": "def rules(path):\n    template = json.load(open(path))\n    nsg = next(r for r in template['resources']\n               if r['type'] == 'Microsoft.Network/networkSecurityGroups')\n    found = []\n    for r in nsg['properties']['securityRules']:\n        p = r['properties']\n        if p['direction'] == 'Inbound' and p['protocol'] in ('Tcp', '*'):\n            found.append({'name': r['name'], 'priority': p['priority'], 'access': p['access'],\n                          'source': side(p, 'source'), 'dest': side(p, 'destination'),\n                          'port': p['destinationPortRange']})\n    return sorted(found + DEFAULTS, key=lambda r: r['priority'])\n\n\n", "note": "Keeps the inbound rules that can match TCP, adds the defaults and sorts by priority: the order Azure reads them in."}, {"code": "def matches(spec, ip):\n    if spec == '*':\n        return True\n    if spec.startswith('asg:'):\n        return MEMBERS.get(str(ip)) == spec[4:]\n    if spec == 'VirtualNetwork':\n        return ip in VNET or ip == PROBE\n    if spec == 'AzureLoadBalancer':\n        return ip == PROBE\n    if spec[0].isdigit():\n        return ip in ipaddress.ip_network(spec)\n    sys.exit(f'the model does not know the service tag {spec}')\n\n\n", "note": "How each kind of source or destination matches an address. `VirtualNetwork` is the network plus the host address `168.63.129.16`, as the documentation says; the real tag also takes in peered networks and offices, which this network has none of yet. A tag the model does not know stops it rather than guessing."}, {"code": "def main():\n    path, port = sys.argv[1], sys.argv[4]\n    src, dst = ipaddress.ip_address(sys.argv[2]), ipaddress.ip_address(sys.argv[3])\n    for r in rules(path):\n        hit = matches(r['source'], src) and matches(r['dest'], dst) and r['port'] in ('*', port)\n        print(f\"{r['priority']:>6}  {r['name']:<31}{r['access'] if hit else '-'}\")\n        if hit:\n            return\n\n\nmain()\n", "note": "Reads the rules in order, prints each one with the decision or a dash, and **stops at the first match**, which is the whole of how an NSG works."}]}
```

## The draft, and the door it leaves open

Start from a draft of the NSG with only its first rule, the one letting the web tier in on 8080.
`jq` removes the next two rules from the compiled template, which is what the file looked like
before they were written:

```
ana@laptop:~/azure/nsg$ jq 'del(.resources[2].properties.securityRules[1,2])' nsg.json > draft.json && python3 nsg.py draft.json 10.20.1.4 10.20.2.4 8080
   100  AllowWebToApp                  Allow
```

A web server reaching the application on 8080: rule 100 matched, which is what it was written for.
Now the same web server trying SSH on port 22:

```
ana@laptop:~/azure/nsg$ python3 nsg.py draft.json 10.20.1.4 10.20.2.4 22
   100  AllowWebToApp                  -
 65000  AllowVnetInBound               Allow
```

**Allowed, by a rule nobody in the shop wrote.** `AllowVnetInBound` at 65000 lets anything in the
network reach anything in the network on any port, and the draft never said otherwise. A web server
taken over by an attacker could reach the application's SSH, its debugging ports, anything that
listens. This is the reason the shop's NSG closes the door at 4000.

## The deny, and the probe it caught

With the deny at 4000 and without the rule at 3900, which is the template minus its second rule, ask
about the packet Azure's load balancer sends to check the application is alive:

```
ana@laptop:~/azure/nsg$ jq 'del(.resources[2].properties.securityRules[1])' nsg.json > noprobe.json && python3 nsg.py noprobe.json 168.63.129.16 10.20.2.4 8080
   100  AllowWebToApp                  -
  4000  DenyVnetInBound                Deny
```

**Denied, at 4000, and the default rule for probes at 65001 never got a turn.** Microsoft's
documentation lists `168.63.129.16` inside `VirtualNetwork`, so a deny on `VirtualNetwork` catches
the probe too, and a load balancer whose probes fail marks every machine unhealthy and sends traffic
to none of them. The model follows the documentation here; **the effect was not observed on Azure**,
since nothing in this course runs there. The cure is an allow for `AzureLoadBalancer` above the deny,
which is the rule at 3900 in the real file:

```
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 168.63.129.16 10.20.2.4 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         Allow
```

## Three more packets

SSH from the web server again, a request from the internet straight at the application, and a web
server reaching a new application machine, `10.20.2.5`, that somebody built and forgot to put in
`asg-shop-app`:

```
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 10.20.1.4 10.20.2.4 22
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                Deny
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 203.0.113.50 10.20.2.4 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                -
 65000  AllowVnetInBound               -
 65001  AllowAzureLoadBalancerInBound  -
 65500  DenyAllInBound                 Deny
ana@laptop:~/azure/nsg$ python3 nsg.py nsg.json 10.20.1.4 10.20.2.5 8080
   100  AllowWebToApp                  -
  3900  AllowLoadBalancerProbe         -
  4000  DenyVnetInBound                Deny
```

The first stops at 4000, where it should. The second walks the whole list to `DenyAllInBound`: the
internet never had a way in, and the application tier does not need one, because customers reach the
web tier through a load balancer and only the web tier reaches the application. **The third is the
one to remember**: a machine missing from its ASG is not reached by the rule written for its role,
and the deny catches it. The rule was right; the membership was wrong, and the symptom is an
application server that the web tier cannot see. When a rule naming an ASG does not seem to work,
look at the interface before the rule.
