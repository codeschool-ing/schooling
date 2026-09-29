---
title: An inventory, and variables beside it
version: 1
---

Ansible is the most widely used automation tool in networking, and it arrives at the same ideas
as lesson 8's Nornir from the other side. **Nornir is a Python library you write programs with;
Ansible is a program you describe the desired state to**, in YAML files called playbooks, and it
works out what to run. Both keep the list of devices as data, and both run on many devices at once.

A project is a directory, and its layout is a convention Ansible reads by itself:

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
