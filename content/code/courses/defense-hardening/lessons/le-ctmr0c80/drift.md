---
title: Finding drift before fixing it
version: 1
---

**Drift is any difference between a machine and the description it is supposed to match.** Group
Policy deals with most of it silently: a policy setting changed locally is put back at the next
refresh. Ansible, run on a schedule, does the same. But putting things back without looking loses
information, because a setting somebody changed by hand was changed for a reason, and the reason is
either a problem the baseline does not handle or somebody who should not have been there.

## A hand edit on a workstation

On `desk`, somebody raised the number of SSH attempts in the baseline's own file, perhaps to stop a
colleague with a sticky keyboard being cut off:

```
ana@desk:~$ sudo sed -i "s/^MaxAuthTries .*/MaxAuthTries 10/" /etc/ssh/sshd_config.d/10-baseline.conf; grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 10
```

Run the baseline from `admin` in **check mode**: `--check` asks every task what it would change and
changes nothing, `--diff` prints the difference, and `--limit desk` keeps it to the one machine.

```
ana@admin:~$ ansible-playbook -i hosts.ini baseline.yml --check --diff --limit desk | grep -E "^[-+]|changed=|TASK \[SSH"
TASK [SSH, with this machine's values] *****************************************
--- before: /etc/ssh/sshd_config.d/10-baseline.conf
+++ after: /etc/ssh/sshd_config.d/10-baseline.conf
-MaxAuthTries 10
+MaxAuthTries 3
desk                       : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ana@desk:~$ grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 10
```

The diff is the drift, line for line: the file says 10 and the baseline says 3. The recap counts two
changes it *would* make, the file and the reload it would trigger, and the second command shows the
file untouched. **Check mode turns a configuration tool into an audit tool**: the same description
that fixes machines can report how far each one has moved, which is what you want before deciding
whether to fix it or to change the description.

## Two answers to drift

| | when it is right |
|---|---|
| put it back | the change was a mistake, a shortcut, or nobody can say who made it |
| change the description | the change met a real need, so the need belongs in the baseline, as a group or host variable with a reason beside it |

Here, a keyboard is not a reason to triple the attempts an attacker gets on every connection. The
baseline stays, and the next run puts 3 back.

## Drift the tool cannot see

Check mode reports differences in what the playbook manages, and nothing else, which is the limit
lesson 2 met from the other side. A new file in `sshd_config.d`, a package installed by hand, a
second account with user id 0: none of them is in `baseline.yml`, so none appears in the diff. Group
Policy has the same edge, and one more: a registry value written by an old policy that has since been
removed stays behind on the machine, **tattooed**, because nothing manages it any more. Both are why
lesson 2 kept a separate check that asks the machine what is true, and why lesson 18 collects the
inventory of what is actually there.
