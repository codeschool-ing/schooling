---
title: The remediation, written as code
version: 1
---

**A change applied by hand is applied once, to the machines somebody remembered, in the order they
remembered it.** The checks in the last section say what is wrong. The fix belongs in a file too,
so that it can be read before it runs, run on the next machine the same way, and run again
tomorrow to put back whatever drifted. That is **configuration as code**, and on Linux the tool
most organisations reach for is **Ansible**: it needs nothing on the machines it manages except
SSH and Python, and both are already on every machine in the lab.

Ansible runs from a control machine, which here is `admin`. It needs an **inventory**, the list
of machines it may touch, grouped by role. One group with one machine is enough for now:

```
ana@admin:~$ printf "[portal]\nweb\n" > hosts.ini; ansible -i hosts.ini portal -m ping
web | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

`-m ping` is not a network ping: it logs in over SSH, runs a small Python program, and answers
`pong`. It proves the three things the playbook will need, the network path, the key and Python on
the far side.

## The playbook

On `admin`, create `harden.yml`. Every task describes a state the portal should be in, and the
whole file is the portal's baseline, written as changes rather than as checks:

```schooling-example
{"language": "yaml", "file": "harden.yml", "parts": [{"code": "- name: Jatobá baseline for the portal\n  hosts: portal\n  become: true\n  tasks:", "note": "A playbook is a list of plays, and a play says which machines (`portal`, a group from the inventory) and what to make true on them. `become: true` runs each task with `sudo` on the far side, over the SSH key every lab machine already trusts."}, {"code": "    - name: Services the portal does not need are not installed\n      ansible.builtin.apt:\n        name: [vsftpd, openbsd-inetd, inetutils-telnetd, rpcbind, avahi-daemon, snmpd]\n        state: absent\n        purge: true", "note": "Each task describes a state, never a command. `state: absent` means \"make sure these are gone\": on a machine that has them it purges them, on one that does not it does nothing and says `ok`. That is what makes the playbook safe to run twice, or every night."}, {"code": "    - name: Only root has user id 0\n      ansible.builtin.lineinfile:\n        path: \"{{ item }}\"\n        regexp: '^suporte:'\n        state: absent\n      loop: [/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow]", "note": "The second root goes the way lesson 1 removed it, by deleting its line from the four account files, never with `userdel -r`. `loop` repeats the task once per file."}, {"code": "    - name: The intern's account cannot log in\n      ansible.builtin.user:\n        name: estagio\n        password_lock: true\n        shell: /usr/sbin/nologin\n        expires: 1\n\n    - name: The intern has no sudo rule\n      ansible.builtin.file:\n        path: /etc/sudoers.d/estagio\n        state: absent", "note": "The intern's account is locked, given no shell and expired, and its `sudo` rule is removed: the same three changes as lesson 1, written as the state they leave behind."}, {"code": "    - name: SSH refuses root and passwords\n      ansible.builtin.copy:\n        dest: /etc/ssh/sshd_config.d/10-hardening.conf\n        content: |\n          PermitRootLogin no\n          PasswordAuthentication no\n          X11Forwarding no\n          MaxAuthTries 3\n        validate: /usr/sbin/sshd -t -f %s\n      notify: reload ssh", "note": "`validate` runs `sshd -t` on the new file before it replaces anything, so a typo in the playbook never reaches the server. `notify` asks for the handler at the end, and only if this task changed something."}, {"code": "    - name: nginx does not announce its version\n      ansible.builtin.lineinfile:\n        path: /etc/nginx/nginx.conf\n        regexp: '^\\s*#?\\s*server_tokens'\n        line: \"\\tserver_tokens off;\"\n      notify: restart nginx\n\n  handlers:\n    - name: reload ssh\n      ansible.builtin.service: {name: ssh, state: reloaded}\n    - name: restart nginx\n      ansible.builtin.service: {name: nginx, state: restarted}", "note": "Handlers run once, after every task, whatever number of tasks notified them. A second run that changes nothing notifies nothing, so neither service is touched."}]}
```

Run it:

```
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml

PLAY [Jatobá baseline for the portal] ******************************************

TASK [Gathering Facts] *********************************************************
ok: [web]

TASK [Services the portal does not need are not installed] *********************
changed: [web]

TASK [Only root has user id 0] *************************************************
changed: [web] => (item=/etc/passwd)
changed: [web] => (item=/etc/shadow)
ok: [web] => (item=/etc/group)
ok: [web] => (item=/etc/gshadow)

TASK [The intern's account cannot log in] **************************************
changed: [web]

TASK [The intern has no sudo rule] *********************************************
changed: [web]

TASK [SSH refuses root and passwords] ******************************************
changed: [web]

TASK [nginx does not announce its version] *************************************
changed: [web]

RUNNING HANDLER [reload ssh] ***************************************************
changed: [web]

RUNNING HANDLER [restart nginx] ************************************************
changed: [web]

PLAY RECAP *********************************************************************
web                        : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

Each task prints `changed` where it had to change something and `ok` where the machine was
already right. Two lines of the account task say `ok`: `suporte` was created into group 0 and
never had a group of its own, so there was no line to remove from `/etc/group` or `/etc/gshadow`.
The recap counts eight changes, the six tasks and the two handlers they triggered.

## The second run is the test

A playbook is only safe to schedule if running it on a machine that is already right changes
nothing. That property is called **idempotence**, and the second run checks it:

```
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml | tail -2
web                        : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

`changed=0`. Seven tasks ran, the facts and the six of the playbook, found every state already
true and touched nothing, so no handler fired and neither service restarted. A playbook whose second run reports changes is either fighting
another tool for the same file or written as commands rather than states, and either way it should
not run unattended.

Then ask the machine, with the check from the last section, which knows nothing about Ansible:

```
ana@web:~$ sudo bash check.sh; echo "failed: $?"
PASS JAT-01 only root has user id 0
PASS JAT-02 nothing listens for telnet
PASS JAT-03 no FTP server is installed
PASS JAT-04 root may not log in over SSH
PASS JAT-05 SSH refuses passwords
PASS JAT-06 the intern's password is locked
PASS JAT-07 nginx hides its version
failed: 0
```

All seven pass. **Fix and check are two separate programs on purpose**: a playbook can only tell
you what it did, and a check tells you what is true. Lynis, run again:

```
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt
  Hardening index : 69 [#############       ]
  Tests performed : 257
ana@web:~$ sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2
warning[]=PKGS-7392|Found one or more vulnerable packages.
warning[]=NETW-2704|Nameserver 8.8.8.8 does not respond
warning[]=NETW-2704|Nameserver 8.8.4.4 does not respond
warning[]=NETW-2705|Couldn't find 2 responsive nameservers
warning[]=FIRE-4512|iptables module(s) loaded, but no rules active
warning[]=FINT-4315|No AIDE configuration file was found, needed for AIDE functionality
```

The two warnings about the second root are gone. The hardening index did not move: 69 again,
now over 257 tests instead of 259, because two tests had nothing left to look at once the services
were purged. That is the index's limit in one line. It is arithmetic over whatever the tool
counted, and **a baseline is judged by its controls passing, not by a score going up.** The
remaining warnings are the lab's missing internet, the firewall lesson 5 adds, the packages lesson
16 is about and the integrity database lesson 11 builds.
