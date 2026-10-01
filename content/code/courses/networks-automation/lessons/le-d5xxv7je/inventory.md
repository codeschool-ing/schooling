---
title: An inventory that is not a file
version: 1
---

Lesson 8's Nornir inventory was three YAML files listing hosts and their addresses, which is a
copy of what NetBox already holds. The `nornir-netbox` plugin builds the inventory from NetBox
instead:

```yaml
inventory:
  plugin: NetBoxInventory2
  options:
    nb_url: https://netbox
    ssl_verify: /home/ana/lab-ca.pem
    filter_parameters: {role: router}
    use_platform_slug: true
    defaults_file: inventory/defaults.yaml
runner:
  plugin: threaded
  options:
    num_workers: 10
```

The filter is the API's own, `role=router`, so nc1 is left out exactly as it was from the curl
request. `use_platform_slug` makes each host's platform the slug of its NetBox platform, `frr`,
which is also the name of the lab's NAPALM driver. What NetBox cannot know, the user name and the
SSH key, stays in a defaults file:

```yaml
---
username: netops
connection_options:
  napalm:
    extras:
      optional_args: {key_file: /home/ana/.ssh/id_ed25519}
```

```schooling-example
{
  "language": "python",
  "file": "nr_nb.py",
  "parts": [
    {
      "code": "from nornir import InitNornir\nfrom nornir_napalm.plugins.tasks import napalm_get\n"
    },
    {
      "code": "nr = InitNornir(config_file=\"nb_config.yaml\")\nfor name, host in nr.inventory.hosts.items():\n    print(f\"{name}: hostname={host.hostname} platform={host.platform} site={host.data['site']['slug']}\")\n\nresult = nr.run(task=napalm_get, getters=[\"facts\"])\nfor name, r in sorted(result.items()):\n    facts = r[0].result[\"facts\"]\n    print(f\"{name}: {facts['vendor']} {facts['os_version']}, interfaces {', '.join(facts['interface_list'])}\")",
      "note": "**The inventory comes from NetBox.** The plugin reads the token from the `NB_TOKEN` environment variable, so it is never written into `nb_config.yaml`, which goes into the repository."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && NB_TOKEN=$(cat ~/.netbox-token) python nr_nb.py
core1: hostname=192.0.2.11 platform=frr site=core
edge1: hostname=192.0.2.12 platform=frr site=branch-1
edge2: hostname=192.0.2.13 platform=frr site=branch-2
core1: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
edge1: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
edge2: FRRouting 8.4.4, interfaces eth0, eth1, eth2, lo
```

**Each host's address came from its `primary_ip4`**, the plugin took the site and every other field
along as data, and NAPALM reached all three routers. A router added to NetBox with the router role
and a primary address is in the next run's inventory without anybody editing a file.

One thing to know about the plugin: **without `NB_TOKEN` it does not stop to say so.** It falls
back to a placeholder token written in its own source and sends that, and NetBox refuses it:

```
ana@ctl:~$ cd sot && python nr_nb.py 2>&1 | tail -1
ValueError: Failed to get data from NetBox instance https://netbox
```

The message says the request failed and not why, and nothing in it mentions a token. When a script
that has always worked fails like this, look at the environment first.
