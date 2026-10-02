---
title: The inventory, and how Ansible reaches a machine
version: 1
---

Terraform ends where the operating system begins. Lesson 1 drew the line: the cloud's API can
create a machine and cannot see which packages are on it, what is in `/etc/nginx` or whether a
service is running. **Ansible works on the other side of that line**, and it gets there the way you
would by hand: it logs in over SSH and runs something.

The common first picture is a server in the middle and an agent on every machine, the way a
monitoring system is built. Ansible has neither. **It runs on Ana's laptop, which Ansible calls the
control node**, and it needs two things on each machine it manages: an SSH server that accepts her
key, and Python, which the small programs it sends are written in. Ubuntu ships both. Nothing of
Ansible is installed there, and nothing runs between two of her commands.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Ana's laptop holds Ansible, the inventory and the playbook. From it, three SSH connections go out, one to each machine: web1 and web2 in the group web, db1 in the group db. Each machine runs only sshd and Python; nothing of Ansible is installed on it.\"><defs><marker id=\"ps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"230\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana's laptop</text><text x=\"135.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the control node</text><text x=\"135.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ansible-playbook</text><text x=\"135.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inventory.ini</text><text x=\"135.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">site.yml</text><text x=\"135.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">everything lives here</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"160\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">web</text><rect x=\"440\" y=\"195\" width=\"260\" height=\"75\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">db</text><rect x=\"470\" y=\"50\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web1</text><text x=\"575.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd and Python, nothing else</text><path d=\"M250 140 L360 140 L360 74 L468 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><rect x=\"470\" y=\"115\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web2</text><text x=\"575.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd and Python, nothing else</text><path d=\"M250 140 L360 140 L360 139 L468 139\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><rect x=\"470\" y=\"215\" width=\"210\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">db1</text><text x=\"575.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sshd and Python, nothing else</text><path d=\"M250 140 L360 140 L360 239 L468 239\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ps-ah-phosphor)\"></path><text x=\"320.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">SSH</text></svg>", "caption": "Ansible pushes: everything it needs is on the laptop, and each machine is reached over SSH when a command runs."}
```

The machines in this lesson are three containers on the laptop, `web1`, `web2` and `db1`, each
running Ubuntu 24.04 with `sshd` and a user `deploy` who may use `sudo`. They are real enough for
everything Ansible does: packages come from the Ubuntu archive and nginx serves pages. Moto is not
involved, because moto runs no machines.

The first file is the **inventory**: which machines exist and which groups they belong to.

```ini
[web]
web1
web2

[db]
db1

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
```

A name in brackets is a group, and every line below it is a host. `[all:vars]` sets variables for
every host: the user to log in as, and where Python is. That second line is not decoration. Without
it Ansible looks for an interpreter on each machine, finds one, and prints a warning on every
command that a later Python could be found instead; naming it says which one you meant. A small
`ansible.cfg` beside the inventory saves typing `-i inventory.ini` on every command:

```ini
[defaults]
inventory = inventory.ini
```

Because the connection is plain SSH, plain SSH rules apply, including host keys. Ana trusts the
three machines' keys once, before the first command. On machines you did not just create yourself,
compare the fingerprints with what the machine's console shows before trusting them.

```
ana@laptop:~/shop/ansible$ ssh-keyscan -t ed25519 web1 web2 db1 >> ~/.ssh/known_hosts 2>/dev/null
```

Now the question every Ansible session starts with: can I reach them?

```
ana@laptop:~/shop/ansible$ ansible all -m ping
web2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
web1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
db1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

**`ping` here is not the network ping.** It is a module: Ansible logged in as `deploy`, ran a tiny
Python program on each machine and got `pong` back, which proves the SSH login and the interpreter
both work. The hosts answered in the order they finished, which is why `db1` sits between the other
two; a second run can print them in another order.

`ansible-inventory` shows how Ansible read the file, as a tree or as the YAML form an inventory can
also be written in:

```
ana@laptop:~/shop/ansible$ ansible-inventory --graph
@all:
  |--@ungrouped:
  |--@web:
  |  |--web1
  |  |--web2
  |--@db:
  |  |--db1
```

```
ana@laptop:~/shop/ansible$ ansible-inventory --list --yaml
all:
  children:
    db:
      hosts:
        db1:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
    web:
      hosts:
        web1:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
        web2:
          ansible_python_interpreter: /usr/bin/python3
          ansible_user: deploy
```

The YAML shows something the INI file hides: variables belong to hosts in the end. `[all:vars]`
was copied onto each of the three.

**A machine that cannot be logged into is UNREACHABLE, which is not the same as FAILED.** Asking
for `root` instead of `deploy`, whose key is not authorised there:

```
ana@laptop:~/shop/ansible$ ansible db1 -m ping -e ansible_user=root
[ERROR]: Task failed: Failed to connect to the host via ssh: root@db1: Permission denied (publickey,password).
Origin: <adhoc 'ping' task>

{'action': 'ping', 'args': {}, 'timeout': 0, 'async_val': 0, 'poll': 15}

db1 | UNREACHABLE! => {
    "changed": false,
    "msg": "Task failed: Failed to connect to the host via ssh: root@db1: Permission denied (publickey,password).",
    "unreachable": true
}
```

UNREACHABLE means Ansible never got as far as running anything; FAILED, which the next section
shows, means it logged in and the task went wrong. The distinction comes back in every summary
Ansible prints.
