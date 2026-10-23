---
title: The same idea on Linux, with Ansible
version: 1
---

**Linux has no Group Policy, and needs the same thing.** Most organisations that run Linux fleets
reach for a configuration tool instead: Ansible, Puppet, Chef or Salt. They differ in whether an
agent runs on each machine and whether the machine pulls or is pushed to, and they agree on the
shape: **a description of the desired state, held in one place, and a rule for which part of it
applies to which machine.** Lesson 2 used Ansible on one machine. Here it does what Group Policy
does, for three machines with different jobs.

Start the lab with `sudo bash hostlab.sh up admin web desk jump`, and work on `admin`. The
inventory puts each machine in a group by its job, and the variables live in files named after the
groups and the hosts:

```
ana@admin:~$ head -20 hosts.ini group_vars/*.yml host_vars/*.yml
==> hosts.ini <==
[servers]
web
jump

[workstations]
desk

==> group_vars/all.yml <==
ssh_max_auth_tries: 3
x11_forwarding: "no"
banner: "Jatoba Contabilidade. Authorised use only; sessions are logged."

==> group_vars/workstations.yml <==
x11_forwarding: "yes"

==> host_vars/jump.yml <==
ssh_max_auth_tries: 2
```

`all.yml` holds what every machine shares. `workstations.yml` changes one value for the
workstations, because people at desks open graphical programs over SSH and servers never do.
`jump.yml` tightens one value for one machine, because `jump` is the door lesson 15 builds and it
gets fewer attempts per connection than anything else. Ansible draws the groups for you:

```
ana@admin:~$ ansible-inventory -i hosts.ini --graph
@all:
  |--@ungrouped:
  |--@servers:
  |  |--web
  |  |--jump
  |--@workstations:
  |  |--desk
```

## Who wins

Every machine is also in the group `all`, so `desk` has two values for `x11_forwarding` and `jump`
has two for `ssh_max_auth_tries`. Ansible settles it by a fixed order of precedence: **a host's own
variables beat its groups', and a named group's beat `all`'s.** Ask what each machine ends up with
before anything runs; `-f 1` makes Ansible ask one machine at a time, so the answers come back in
the inventory's order:

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -m debug -a 'msg="tries={{ ssh_max_auth_tries }} x11={{ x11_forwarding }}"' | grep -E 'SUCCESS|msg'
web | SUCCESS => {
    "msg": "tries=3 x11=no"
jump | SUCCESS => {
    "msg": "tries=2 x11=no"
desk | SUCCESS => {
    "msg": "tries=3 x11=yes"
```

`web` keeps the defaults. `desk` gets the workstation's `yes`. `jump` gets its own `2`. Notice the
direction: here the machine's own file wins. In Group Policy the machine's own local policy is the
one that loses, because it is applied first and everything from the domain overwrites it, and a
reader used to one system is surprised by the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-vars\" aria-label=\"Where each machine gets its two values. The file all.yml gives every machine 3 attempts and no X11 forwarding. The file workstations.yml overrides X11 forwarding to yes for desk. The file jump.yml overrides the attempts to 2 for jump. Result: web has 3 and no, desk has 3 and yes, jump has 2 and no. The more specific file wins.\"><defs><marker id=\"l03-vars-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"680.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/all.yml</text><text x=\"330.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh_max_auth_tries: 3</text><text x=\"560.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">x11_forwarding: &quot;no&quot;</text><rect x=\"250.0\" y=\"100.0\" width=\"220.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">group_vars/workstations.yml</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">x11_forwarding: &quot;yes&quot;</text><rect x=\"490.0\" y=\"100.0\" width=\"210.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">host_vars/jump.yml</text><text x=\"595.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh_max_auth_tries: 2</text><rect x=\"40.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"90.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"160.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">no</text><path d=\"M130.0 80.0 L130.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"320.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><text x=\"390.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">yes</text><path d=\"M360.0 150.0 L360.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><rect x=\"505.0\" y=\"190.0\" width=\"180.0\" height=\"56.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><text x=\"555.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"625.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">no</text><path d=\"M595.0 150.0 L595.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-vars-dh-ah-paper-dim)\"></path><text x=\"130.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing more specific</text></svg>", "caption": "A host file beats a group file, and a named group beats all."}
```

## The playbook

On `admin`, create `baseline.yml`:

```schooling-example
{"language": "yaml", "file": "baseline.yml", "parts": [{"code": "- name: Jatobá baseline for every machine\n  hosts: all\n  become: true\n  tasks:", "note": "`hosts: all` is every machine in the inventory. What differs between them is not in this file at all: it comes from the variables each machine inherits from its groups, which is the point of the section above."}, {"code": "    - name: The banner shown before login\n      ansible.builtin.copy:\n        dest: /etc/issue.net\n        content: \"{{ banner }}\\n\"", "note": "`{{ banner }}` is replaced by the machine's value of `banner` before the file is written. Every machine has the same one, because it is only set in `all.yml`."}, {"code": "    - name: SSH, with this machine's values\n      ansible.builtin.copy:\n        dest: /etc/ssh/sshd_config.d/10-baseline.conf\n        content: |\n          PermitRootLogin no\n          PasswordAuthentication no\n          MaxAuthTries {{ ssh_max_auth_tries }}\n          X11Forwarding {{ x11_forwarding }}\n          Banner /etc/issue.net\n        validate: /usr/sbin/sshd -t -f %s\n      notify: reload ssh", "note": "One task, three different files: `web` gets 3 and `no`, `desk` gets 3 and `yes`, `jump` gets 2 and `no`. The settings that are the same everywhere are written as text, and only the two that vary are variables."}, {"code": "  handlers:\n    - name: reload ssh\n      ansible.builtin.service: {name: ssh, state: reloaded}", "note": "The handler reloads SSH only on the machines whose file actually changed."}]}
```

Before running it, look at what the three machines do now, with an ad-hoc command that asks each
one's `sshd`:

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -b -m shell -a "sshd -T | grep -E '^(maxauthtries|x11forwarding) '" | sed 's/ | CHANGED | rc=0 >>//'
web
maxauthtries 6
x11forwarding yes
jump
maxauthtries 6
x11forwarding yes
desk
maxauthtries 6
x11forwarding yes
```

Ubuntu's defaults, the same on all three. Apply the baseline, and ask again; each machine reports
three changes, the banner, the SSH file and the reload:

```
ana@admin:~$ ansible-playbook -i hosts.ini baseline.yml | tail -6

PLAY RECAP *********************************************************************
desk                       : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
jump                       : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web                        : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

```
ana@admin:~$ ansible all -i hosts.ini -f 1 -b -m shell -a "sshd -T | grep -E '^(maxauthtries|x11forwarding|banner) '" | sed 's/ | CHANGED | rc=0 >>//'
web
maxauthtries 3
x11forwarding no
banner /etc/issue.net
jump
maxauthtries 2
x11forwarding no
banner /etc/issue.net
desk
maxauthtries 3
x11forwarding yes
banner /etc/issue.net
```

Three machines, three different results from one playbook and one set of variables, and each one
the value its group or its own file said. **The rule is in one place and the differences are
declared**, which is everything Group Policy offers apart from the Windows registry.
