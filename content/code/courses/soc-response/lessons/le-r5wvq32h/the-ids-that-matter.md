---
title: The event ids that matter, and their Linux twins
version: 1
---

Windows has hundreds of event ids. An analyst reads about fifteen of them every week, and they are worth
knowing by number, because a SIEM rule and a colleague's message both name them that way.

| id | channel | what it says | the Linux line that says the same |
|---|---|---|---|
| **4624** | Security | an account logged on | `sshd: Accepted password for` in `auth.log` |
| **4625** | Security | a logon failed | `sshd: Failed password for`, or `Invalid user` |
| **4634** / **4647** | Security | logged off | `pam_unix(...): session closed for user` |
| **4648** | Security | a logon with explicitly supplied credentials (`runas`) | `su` or `sudo -u` in `auth.log` |
| **4672** | Security | special privileges assigned to a new logon (an administrator) | `sudo` lines in `auth.log` |
| **4688** | Security | a process was created, with its command line if that is enabled | `execve` records in `audit.log` |
| **4720** | Security | a user account was created | `useradd` lines in `auth.log` |
| **4728**, **4732**, **4756** | Security | a member added to a global, local or universal group | `usermod -aG` lines in `auth.log` |
| **4740** | Security | an account was locked out | `pam_faillock` lines |
| **1102** | Security | **the audit log was cleared** | a log file truncated or deleted |
| **7045** | System | a service was installed | a new unit file under `/etc/systemd/system` |
| **4104** | PowerShell/Operational | a script block ran, with its text | shell history, which is far weaker |
| **1** and **3** | Sysmon/Operational | process created with its hash; network connection | `auditd` rules, or an EDR agent |

Two fields inside **4624** and **4625** do most of the work. The **logon type** says how: `2` at the
keyboard, `3` over the network (a file share), `10` through Remote Desktop. And in 4625 the **status
code** says why it failed: `0xC000006A` is a wrong password for an account that exists, `0xC0000064` an
account that does not exist. A run of `0xC0000064` against many names is somebody guessing names; a run
of `0xC000006A` against one name is somebody guessing a password. That distinction comes back in lesson 9.

**1102 deserves its own line.** Clearing the Security log is something an administrator almost never
needs to do and an intruder very often wants to, and the event is written *after* the clear, so it
survives it. A 1102 nobody can explain is an incident until proven otherwise. The Linux twin has no such
courtesy: a truncated `auth.log` says nothing about itself, which is why lesson 3 ships logs off the
machine before anybody can edit them.
