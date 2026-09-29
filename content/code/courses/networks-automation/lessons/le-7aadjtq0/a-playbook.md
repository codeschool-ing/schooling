---
title: A first playbook
version: 1
---

A playbook is a list of **plays**; a play is a set of hosts and a list of **tasks**; a task calls
one **module** with arguments. That is the whole grammar.

```schooling-example
{
  "language": "yaml",
  "file": "show.yaml",
  "parts": [
    {
      "code": "- name: Ask every router about its OSPF neighbours\n  hosts: routers\n  gather_facts: false\n  tasks:",
      "note": "**A play says which hosts, and a list of tasks to run on each.** `gather_facts: false` skips the Linux facts Ansible collects by default, which a router's CLI cannot give."
    },
    {
      "code": "    - name: Show the neighbours\n      ansible.netcommon.cli_command:\n        command: show ip ospf neighbor json\n      register: ospf\n",
      "note": "**A task calls one module with arguments.** `cli_command` sends one command over the network_cli connection and returns what the device printed; `register` keeps the result in a variable."
    },
    {
      "code": "    - name: Count them\n      ansible.builtin.debug:\n        msg: \"{{ (ospf.stdout | from_json).neighbors | length }} OSPF neighbour(s)\"",
      "note": "**Variables are Jinja2 expressions.** `from_json` parses the router's JSON, and the task prints one line per router."
    }
  ]
}
```

```
ana@ctl:~$ cd net && ansible-playbook show.yaml

PLAY [Ask every router about its OSPF neighbours] ******************************

TASK [Show the neighbours] *****************************************************
ok: [edge1]
ok: [edge2]
ok: [core1]

TASK [Count them] **************************************************************
ok: [core1] => {
    "msg": "2 OSPF neighbour(s)"
}
ok: [edge1] => {
    "msg": "1 OSPF neighbour(s)"
}
ok: [edge2] => {
    "msg": "1 OSPF neighbour(s)"
}

PLAY RECAP *********************************************************************
core1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
edge2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Three things in that output are Ansible's and appear in every run. **Each task is reported per
host**, in whatever order the hosts finished, because Ansible works on them in parallel. The status
of each is `ok`, `changed`, `failed` or `skipped`. And the **play recap** at the end counts them per
host; it is the line a person or a pipeline reads first.

`cli_command` is the network equivalent of lesson 8's `send_command`, and `from_json` is lesson 8's
`json.loads`: the router answered in JSON because the command ended in `json`, and the expression
counted the neighbours. The expressions between `{{` and `}}` are **Jinja2**, the template language
lesson 10 is about; in a playbook they compute values from variables and results.

The task reported `ok` and not `changed`, and that is not decoration. `cli_command` only reads, and
it says so. **What a task reports about change is a promise**, and the next sections are about
keeping it.
