---
title: An inventory, and variables beside it
version: 2
---

Ansible is the most widely used automation tool in networking, and it arrives at the same ideas
as lesson 8's Nornir from the other side. **Nornir is a Python library you write programs with;
Ansible is a program you describe the desired state to**, in YAML files called playbooks, and it
works out what to run. Both keep the list of devices as data, and both run on many devices at once.

A project is a directory, and its layout is a convention Ansible reads by itself. This one is
`~/net` in `ana`'s home, and every file in it is printed in this lesson; make the directory with
`mkdir -p ~/net` and save each file there as you meet it.

```
ana@ctl:~$ cd net && find . -type f | sort
./ansible.cfg
./bgp.yaml
./bgp_check.yaml
./facts.yaml
./group_vars/routers.yaml
./host_vars/core1.yaml
./host_vars/edge1.yaml
./host_vars/edge2.yaml
./inventory/hosts.yaml
./mgmt.yaml
./show.yaml
./ticket.yaml
```

`ansible.cfg` says where the inventory is:

```
[defaults]
inventory = inventory
stdout_callback = default
retry_files_enabled = false
```

The inventory groups the hosts. `routers` contains two groups, `core` and `branches`, so a
playbook can aim at every router or only at the branches:

```yaml
all:
  children:
    routers:
      children:
        core:
          hosts:
            core1: {ansible_host: core1.example.net}
        branches:
          hosts:
            edge1: {ansible_host: edge1.example.net}
            edge2: {ansible_host: edge2.example.net}
```

```
ana@ctl:~$ cd net && ansible-inventory --graph
@all:
  |--@ungrouped:
  |--@routers:
  |  |--@core:
  |  |  |--core1
  |  |--@branches:
  |  |  |--edge1
  |  |  |--edge2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The inventory as a tree: the group routers contains the groups core and branches; core holds core1, branches holds edge1 and edge2. Beside the tree, the variables: group_vars/routers.yaml applies to every router, with how to connect and the BGP AS; host_vars/edge1.yaml applies to edge1 alone, with its router ID and neighbours. Ansible merges them into the variables edge1 gets, and the host&#x27;s own value wins where both set one.\"><defs><marker id=\"iv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"110\" y=\"20\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">routers</text><rect x=\"20\" y=\"110\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">core</text><rect x=\"200\" y=\"110\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">branches</text><rect x=\"20\" y=\"200\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">core1</text><rect x=\"170\" y=\"200\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge1</text><rect x=\"260\" y=\"200\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge2</text><path d=\"M150 66 L80 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190 66 L260 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 156 L80 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M240 156 L210 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280 156 L300 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"400\" y=\"20\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/routers.yaml</text><text x=\"550.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every router: how to connect, the BGP AS</text><rect x=\"400\" y=\"110\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host_vars/edge1.yaml</text><text x=\"550.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">edge1 alone: router ID, neighbours</text><rect x=\"400\" y=\"200\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"550.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what edge1 gets</text><text x=\"550.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ansible-inventory --host edge1</text><path d=\"M550 92 L550 106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M550 182 L550 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iv-ah)\"></path><path d=\"M210 246 L210 260 L370 260 L396 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#iv-ah)\"></path><text x=\"330\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the host&#x27;s own value wins over the group&#x27;s</text></svg>", "caption": "Groups say where a host belongs; variable files say what it gets from each place it belongs to."}
```

**Variables live beside the inventory, in files named after a group or a host.**
`group_vars/routers.yaml` applies to every router: how to connect, and the values every router
shares.

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: frr.frr.frr
ansible_network_cli_ssh_type: paramiko
ansible_user: netops
ansible_ssh_private_key_file: /home/ana/.ssh/id_ed25519
bgp_as: 64512
management_network: 192.0.2.0/24
```

`host_vars/edge1.yaml` applies to one host, and holds what makes it different:

```yaml
router_id: 203.0.113.252
bgp_neighbours: [203.0.113.251]
```

The other two are the same shape. `host_vars/core1.yaml`, the router every branch peers with:

```yaml
router_id: 203.0.113.251
bgp_neighbours: [203.0.113.252, 203.0.113.253]
```

and `host_vars/edge2.yaml`:

```yaml
router_id: 203.0.113.253
bgp_neighbours: [203.0.113.251]
```

Ansible merges the two, and `ansible-inventory --host` shows the result for one host, which is the
first thing to check when a playbook does something unexpected:

```
ana@ctl:~$ cd net && ansible-inventory --host edge1
{
    "ansible_connection": "ansible.netcommon.network_cli",
    "ansible_host": "edge1.example.net",
    "ansible_network_cli_ssh_type": "paramiko",
    "ansible_network_os": "frr.frr.frr",
    "ansible_ssh_private_key_file": "/home/ana/.ssh/id_ed25519",
    "ansible_user": "netops",
    "bgp_as": 64512,
    "bgp_neighbours": [
        "203.0.113.251"
    ],
    "management_network": "192.0.2.0/24",
    "router_id": "203.0.113.252"
}
```

The four connection variables are the network part. **`ansible_connection: network_cli` means
"log in over SSH to a CLI"**, as Netmiko does, instead of Ansible's usual way of copying Python to
a Linux host and running it there, which a router cannot do. `ansible_network_os` names the
platform, `frr.frr.frr` from the `frr.frr` collection, so Ansible knows its prompts and its
commands. `ansible_network_cli_ssh_type: paramiko` picks the SSH library, lesson 8's bottom layer.
