---
title: Modules that know the platform
version: 1
---

`cli_command` sends whatever it is given. The modules that make Ansible worth using on a network are
the ones that **know the platform**: they take data, read the device's state, and work out the
commands themselves. Collections carry them per vendor, and the `frr.frr` collection has two, a
fact gatherer and a BGP module.

Facts first. `frr_facts` runs `show` commands and turns the output into variables:

```schooling-example
{
  "language": "yaml",
  "file": "facts.yaml",
  "parts": [
    {
      "code": "- name: What the collection knows about each router\n  hosts: branches\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Gather interface facts\n      frr.frr.frr_facts:\n        gather_subset: interfaces\n    - name: Show a few\n      ansible.builtin.debug:\n        msg: \"{{ ansible_net_hostname }} runs FRR {{ ansible_net_version }}, interfaces {{ ansible_net_interfaces.keys() | sort | join(', ') }}\"",
      "note": "**`frr_facts` turns `show` output into variables** named `ansible_net_…`, so later tasks can decide on them."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook facts.yaml

PLAY [What the collection knows about each router] *****************************

TASK [Gather interface facts] **************************************************
ok: [edge1]
ok: [edge2]

TASK [Show a few] **************************************************************
ok: [edge1] => {
    "msg": "edge1 runs FRR 8.4.4, interfaces eth0, eth1, eth2, lo"
}
ok: [edge2] => {
    "msg": "edge2 runs FRR 8.4.4, interfaces eth0, eth1, eth2, lo"
}

PLAY RECAP *********************************************************************
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

The play ran on `branches` only, the two edges, because that is its `hosts`. The variables are
available to every later task in the play, which is how a playbook decides, for instance, to skip a
task on a router whose software is too old.

Then configuration as data. `frr_bgp` takes BGP as a structure, with the values coming from each
host's variables:

```schooling-example
{
  "language": "yaml",
  "file": "bgp.yaml",
  "parts": [
    {
      "code": "- name: iBGP between the loopbacks\n  hosts: routers\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Configure BGP, one neighbour at a time\n      frr.frr.frr_bgp:\n        config:\n          bgp_as: \"{{ bgp_as }}\"\n          router_id: \"{{ router_id }}\"\n          neighbors:\n            - neighbor: \"{{ item }}\"\n              remote_as: \"{{ bgp_as }}\"\n              update_source: lo\n        operation: merge",
      "note": "**A vendor module speaks in data, not in lines.** `frr_bgp` takes the BGP configuration as a structure, and the collection works out the FRR commands, leaving out the ones already there."
    },
    {
      "code": "      loop: \"{{ bgp_neighbours }}\"",
      "note": "**One run of the task per entry in the host's own list.** core1's list has two neighbours and each edge's has one; the playbook is the same for all three."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook bgp.yaml

PLAY [iBGP between the loopbacks] **********************************************

TASK [Configure BGP, one neighbour at a time] **********************************
changed: [edge1] => (item=203.0.113.251)
changed: [edge2] => (item=203.0.113.251)
changed: [core1] => (item=203.0.113.252)
changed: [core1] => (item=203.0.113.253)

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**The same playbook made three different configurations**, because each host's `bgp_neighbours`
list is different: `core1` got two neighbours and each edge one. What the module sent to `edge1`,
read back through its CLI:

```
ana@ctl:~$ ssh netops@edge1 "show running-config" | sed -n "/^router bgp/,/^exit/p"
router bgp 64512
 bgp router-id 203.0.113.252
 neighbor 203.0.113.251 remote-as 64512
 neighbor 203.0.113.251 update-source lo
exit
```

And the check that the sessions actually came up, as a playbook of its own that fails if they did
not:

```schooling-example
{
  "language": "yaml",
  "file": "bgp_check.yaml",
  "parts": [
    {
      "code": "- name: Are the BGP sessions up?\n  hosts: routers\n  gather_facts: false\n  tasks:\n    - name: Read BGP state\n      ansible.netcommon.cli_command:\n        command: show bgp summary json\n      register: bgp\n"
    },
    {
      "code": "    - name: Every peer is Established\n      ansible.builtin.assert:\n        that: item.value.state == \"Established\"\n        quiet: true\n      loop: \"{{ (bgp.stdout | from_json).ipv4Unicast.peers | dict2items }}\"\n      loop_control:\n        label: \"{{ item.key }} {{ item.value.state }}\"",
      "note": "**An assertion turns a check into a failure.** If any peer is not `Established`, the task fails for that router and the play says so, which is what a script after a change should do."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook bgp_check.yaml

PLAY [Are the BGP sessions up?] ************************************************

TASK [Read BGP state] **********************************************************
ok: [edge2]
ok: [core1]
ok: [edge1]

TASK [Every peer is Established] ***********************************************
ok: [core1] => (item=203.0.113.252 Established)
ok: [core1] => (item=203.0.113.253 Established)
ok: [edge1] => (item=203.0.113.251 Established)
ok: [edge2] => (item=203.0.113.251 Established)

PLAY RECAP *********************************************************************
core1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**Four sessions, all `Established`.** `assert` is how a playbook turns an expectation into a failure
that stops a run; lesson 13 builds its checks the same way, with `pytest` instead.

Other vendors' collections have many more modules than `frr.frr`: `cisco.ios`, `arista.eos` and
`junipernetworks.junos` have one per area of configuration, interfaces, VLANs, OSPF, ACLs, each
taking data in a shape that is close to the same across the three.
