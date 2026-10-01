---
title: Nornir, many devices at once
version: 1
---

Every script so far looped over a list of names typed into it, one router after another. **Nornir
replaces both halves**: the list becomes an inventory kept as data, and the loop becomes a task run on
every host in parallel threads. It is a Python library, not a tool with its own language, so a task
is an ordinary function.

The inventory is three YAML files. Hosts, with their address and whatever data describes them:

```yaml
---
core1:
  hostname: core1.example.net
  groups: [routers]
  data: {site: core}
edge1:
  hostname: edge1.example.net
  groups: [routers]
  data: {site: branch-1}
edge2:
  hostname: edge2.example.net
  groups: [routers]
  data: {site: branch-2}
edge3:
  hostname: edge3.example.net
  groups: [routers]
  data: {site: branch-3}
```

Groups, holding what several hosts share: here the Netmiko platform, and the NAPALM driver name:

```yaml
---
routers:
  platform: cisco_ios
  connection_options:
    napalm:
      platform: frr
      extras:
        optional_args: {key_file: /home/ana/.ssh/id_ed25519}
```

Defaults, for every host:

```yaml
---
username: netops
connection_options:
  netmiko:
    extras: {use_keys: true, key_file: /home/ana/.ssh/id_ed25519}
```

And `config.yaml` says where the three files are and how many hosts to work on at once:

```yaml
inventory:
  plugin: SimpleInventory
  options:
    host_file: inventory/hosts.yaml
    group_file: inventory/groups.yaml
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
```

`edge3` is in the inventory on purpose. Branch 3 is planned in lesson 5's data and has no router yet,
which is what an inventory looks like the day before an installation.

```schooling-example
{
  "language": "python",
  "file": "nr.py",
  "parts": [
    {
      "code": "import json\n\nfrom nornir import InitNornir\nfrom nornir_netmiko.tasks import netmiko_send_command\n"
    },
    {
      "code": "nr = InitNornir(config_file=\"config.yaml\")\nprint(\"hosts:\", \", \".join(nr.inventory.hosts))\n\n",
      "note": "**The inventory is data**, read from three YAML files: hosts, the groups they belong to, and defaults for everything. `config.yaml` says where they are and how many hosts to work on at once."
    },
    {
      "code": "def full_neighbours(task):\n    out = task.run(netmiko_send_command, command_string=\"show ip ospf neighbor json\")\n    data = json.loads(out.result)\n    return sum(n[\"nbrState\"].startswith(\"Full\") for e in data[\"neighbors\"].values() for n in e)\n\n\nresult = nr.run(task=full_neighbours)",
      "note": "**A task is a function of one host.** Nornir runs it on every host, in threads, and collects what each returned or raised."
    },
    {
      "code": "for host, r in sorted(result.items()):\n    if r.failed:\n        print(f\"{host:6} FAILED: {type(r[-1].exception).__name__}: {str(r[-1].exception).splitlines()[0]}\")\n    else:\n        print(f\"{host:6} {r[0].result} OSPF neighbour(s) Full\")\nprint(\"failed hosts:\", sorted(result.failed_hosts))",
      "note": "**One host failing does not stop the others.** `edge3` is in the inventory and not in the network; its result is an exception, and the three real routers still answered."
    }
  ]
}
```

```
ana@ctl:~$ time python nr.py
hosts: core1, edge1, edge2, edge3
core1  2 OSPF neighbour(s) Full
edge1  1 OSPF neighbour(s) Full
edge2  1 OSPF neighbour(s) Full
edge3  FAILED: NetmikoTimeoutException: TCP connection to device failed.
failed hosts: ['edge3']

real	0m0.876s
user	0m0.386s
sys	0m0.123s
```

Three routers answered, and `edge3` failed with the cause Netmiko gave, **without stopping the
others**. Nornir collects each host's result or exception, and `failed_hosts` lists the ones to look
at. The whole run took under a second of wall-clock time, because the four hosts were worked on at
the same time instead of one after the other; lesson 1's script needed seconds for three.

Hosts are selected by their data, never by a list of names in the code:

```schooling-example
{
  "language": "python",
  "file": "nr_filter.py",
  "parts": [
    {
      "code": "from nornir import InitNornir\nfrom nornir.core.filter import F\nfrom nornir_napalm.plugins.tasks import napalm_get\n\nnr = InitNornir(config_file=\"config.yaml\")"
    },
    {
      "code": "branches = nr.filter(F(site__startswith=\"branch-\") & ~F(name=\"edge3\"))\nprint(\"selected:\", \", \".join(branches.inventory.hosts))",
      "note": "**Filters choose hosts by their data**, never by hard-coded names. The same script runs on one branch or on all of them."
    },
    {
      "code": "result = branches.run(task=napalm_get, getters=[\"facts\"])\nfor host, r in sorted(result.items()):\n    facts = r[0].result[\"facts\"]\n    print(host, facts[\"vendor\"], facts[\"os_version\"], len(facts[\"interface_list\"]), \"interfaces\")",
      "note": "**NAPALM through Nornir**: the same getter on every selected host, with the driver named in `groups.yaml`."
    }
  ]
}
```

```
ana@ctl:~$ python nr_filter.py
selected: edge1, edge2
edge1 FRRouting 8.4.4 4 interfaces
edge2 FRRouting 8.4.4 4 interfaces
```

`F` builds a filter from the inventory's data: every host whose `site` starts with `branch-`, except
`edge3`. The task this time is NAPALM's `get` through `nornir_napalm`, with the driver named in
`groups.yaml`. **The inventory is the one place that says which devices exist**, and lesson 12 moves
it into NetBox, where Nornir reads it with a different inventory plugin and no other change.
