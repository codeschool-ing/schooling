---
title: Ad-hoc commands, and modules that look before they act
version: 1
---

Before writing a playbook, you can ask Ansible to do one thing on a group of machines from the
command line. The shape is always the same: **which hosts, which module, which arguments.**

```
ana@laptop:~/shop/ansible$ ansible web -m command -a whoami
web2 | CHANGED | rc=0 >>
deploy
web1 | CHANGED | rc=0 >>
deploy
```

`web` is a group from the inventory, `-m command` is the module and `-a whoami` its argument. The
answer is per host. To act as root, Ansible logs in as `deploy` and then uses `sudo`, which it calls
**become**:

```
ana@laptop:~/shop/ansible$ ansible web -m command -a whoami --become
web1 | CHANGED | rc=0 >>
root
web2 | CHANGED | rc=0 >>
root
```

Installing a package needs root, and the error when you forget it is apt's own, from the machine:

```
ana@laptop:~/shop/ansible$ ansible web1 -m apt -a "name=tree state=present update_cache=true"
[WARNING]: Updating cache and auto-installing missing dependency: python3-apt
[ERROR]: Task failed: Module failed: E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)
Origin: <adhoc 'apt' task>

{'action': 'apt', 'args': {'name': 'tree', 'state': 'present', 'update_cache': 'true'}, 'timeout': 0, 'async_val': [...]

web1 | FAILED! => {
    "changed": false,
    "cmd": "/usr/bin/apt-get update",
    "msg": "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)",
    "rc": 100,
    "stderr": "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)\n",
    "stderr_lines": [
        "E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)"
    ],
    "stdout": "Reading package lists...\n",
    "stdout_lines": [
        "Reading package lists..."
    ]
}
```

With `--become` the `apt` module installs `tree` on both web servers. Its answer per host is long,
because it carries apt's whole output, so here it is filtered to the two lines that matter:

```
ana@laptop:~/shop/ansible$ ansible web -m apt -a "name=tree state=present update_cache=true" --become | grep -E "=>|\"changed\""
web2 | CHANGED => {
    "changed": true,
web1 | CHANGED => {
    "changed": true,
```

Run the same thing again:

```
ana@laptop:~/shop/ansible$ ansible web -m apt -a "name=tree state=present" --become
web2 | SUCCESS => {
    "cache_update_time": 1790954402,
    "cache_updated": false,
    "changed": false
}
web1 | SUCCESS => {
    "cache_update_time": 1790954403,
    "cache_updated": false,
    "changed": false
}
```

**This is the difference that the rest of the lesson stands on.** The `apt` module did not run
`apt-get install` and report what happened. It first asked the machine whether `tree` was already
installed, found that it was, and did nothing, so it reports `"changed": false` and the host line
says SUCCESS rather than CHANGED. A module like this describes a state, *tree is present*, and makes
only the difference, which is what `terraform apply` did in lesson 1.

`command` cannot do that. It runs a program and has no idea what the program did, so it reports
CHANGED every time, even for a program that only prints its version:

```
ana@laptop:~/shop/ansible$ ansible web1 -m command -a "tree --version"
web1 | CHANGED | rc=0 >>
tree v2.1.1 © 1996 - 2023 by Steve Baker, Thomas Moore, Francesc Rocher, Florian Sesser, Kyosuke Tokoro
```

`command` also runs the program directly, with no shell between, so a pipe is passed to `dpkg` as
more arguments. The `shell` module puts `/bin/sh` in front and the pipe works:

```
ana@laptop:~/shop/ansible$ ansible web1 -m command -a "dpkg -l | grep -c ^ii"
[ERROR]: Task failed: Module failed: The command exited with a non-zero return code.
Origin: <adhoc 'command' task>

{'action': 'command', 'args': {'_raw_params': 'dpkg -l | grep -c ^ii'}, 'timeout': 0, 'async_val': 0, 'poll': 15}

web1 | FAILED | rc=1 >>
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-=================================
ii  grep           3.11-4build1 amd64        GNU grep, egrep and fgrepdpkg-query: no packages found matching |
dpkg-query: no packages found matching -c
dpkg-query: no packages found matching ^iiThe command exited with a non-zero return code.
ana@laptop:~/shop/ansible$ ansible web -m shell -a "dpkg -l | grep -c ^ii"
web1 | CHANGED | rc=0 >>
193
web2 | CHANGED | rc=0 >>
193
```

The first failure is worth reading once, because it is how you will meet it. `dpkg -l` was given
`|`, `grep`, `-c` and `^ii` as package names, listed the one that exists, which is the package
`grep`, and failed on the others. Nothing was broken on the machine; the command meant something
else. **Prefer `command` and reach for `shell` only for a pipe or a redirection**, since a shell
also expands variables and wildcards in whatever you pass it.

Ad-hoc commands are for questions and one-off fixes: which version is installed, how full the disk
is, restart this one service now. What you want to keep, and run again next week on new machines,
belongs in a file. A command typed at a prompt leaves no record that a reviewer can read, the same
reason lesson 1 gave against `network.sh`. The file is a playbook.
