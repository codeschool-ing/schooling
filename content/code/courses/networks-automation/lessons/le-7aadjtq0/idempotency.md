---
title: changed, ok, and running it twice
version: 1
---

Lesson 1 called it idempotence: an operation that leaves the network the same whether it runs once
or twice. **Ansible is built around it**, and its output is how you see it. The prefix list from
lesson 1, as a task:

```schooling-example
{
  "language": "yaml",
  "file": "mgmt.yaml",
  "parts": [
    {
      "code": "- name: Every router has the MGMT prefix list\n  hosts: routers\n  gather_facts: false\n  tasks:"
    },
    {
      "code": "    - name: Permit the management network\n      ansible.netcommon.cli_config:\n        config: \"ip prefix-list MGMT seq 10 permit {{ management_network }}\"",
      "note": "**`cli_config` compares before it sends.** It reads the running configuration, sends only the lines that are missing, and reports `changed` only if it sent something."
    }
  ]
}
```

**Before changing anything, ask what would change.** `--check` runs the play without applying, and
`--diff` shows the lines:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml --check --diff

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
[WARNING]: To ensure idempotency and correct diff the input configuration lines
should be similar to how they appear if present in the running configuration on
device including the indentation
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [core1]
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [edge1]
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
changed: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Each router would receive the one line. The warning is `cli_config` being honest about how it
compares: it looks for the line as written in the running configuration, spacing and indentation
included, so a line written differently from how the router prints it will look new every time.
Then the real run:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
[WARNING]: To ensure idempotency and correct diff the input configuration lines
should be similar to how they appear if present in the running configuration on
device including the indentation
changed: [edge1]
changed: [core1]
changed: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

And a second one:

```
ana@ctl:~$ cd net && ansible-playbook mgmt.yaml

PLAY [Every router has the MGMT prefix list] ***********************************

TASK [Permit the management network] *******************************************
ok: [core1]
ok: [edge1]
ok: [edge2]

PLAY RECAP *********************************************************************
core1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**`changed` the first time, `ok` the second, on every router.** That second run is the proof that
the playbook can run every night: when the network already matches, nothing is sent and the recap
says `changed=0`. The BGP playbook behaved the same way:

```
ana@ctl:~$ cd net && ansible-playbook bgp.yaml | tail -5
PLAY RECAP *********************************************************************
core1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

`changed` has a second job: **it is what a pipeline reports**. A nightly run that says `changed=0`
means nobody touched the network; one that says `changed=3` means three things had drifted and were
put back, and somebody should find out why. That only works if every task reports change
truthfully, and the next section has one that does not.
