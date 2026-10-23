---
title: Measuring with Lynis
version: 1
---

**Lynis is an auditor that runs on the machine it audits.** It reads configuration files, asks
services what they do, and prints a finding for every check that did not pass. It changes
nothing. It is a shell script, it needs no agent and no server, and it is in Ubuntu's archive, so
the lab installed it on every machine.

Start the lab with `sudo bash hostlab.sh up web admin`. `web` is the portal as it was handed over:
everything lesson 1 removed is back, because every lesson starts from a fresh `up`. Audit it:

```
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt
  Hardening index : 69 [#############       ]
  Tests performed : 259
```

`--quick` skips the pauses between sections, and the full report goes to `lynis.txt` because it
is several hundred lines long. The two lines kept are the summary. The **hardening index** is
Lynis's own score out of 100, weighted by the checks that passed, and it is useful only against
itself: the same machine before and after a change. Two machines with the same index can be wrong
in completely different ways.

## Warnings first

Lynis writes a machine-readable copy of every result to `/var/log/lynis-report.dat`, one per
line, which is easier to read than the screen:

```
ana@web:~$ sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2
warning[]=AUTH-9204|Multiple users with UID 0 found in passwd file
warning[]=AUTH-9208|Multiple accounts found with same UID
warning[]=PKGS-7392|Found one or more vulnerable packages.
warning[]=NETW-2704|Nameserver 8.8.8.8 does not respond
warning[]=NETW-2704|Nameserver 8.8.4.4 does not respond
warning[]=NETW-2705|Couldn't find 2 responsive nameservers
warning[]=FIRE-4512|iptables module(s) loaded, but no rules active
warning[]=FINT-4315|No AIDE configuration file was found, needed for AIDE functionality
```

A **warning** is a finding Lynis thinks needs action. Two of them are lesson 1's second root,
found by two different checks. One says vulnerable packages are installed, which is lesson 16's
subject, and one that file integrity monitoring has no configuration, which is lesson 11's. Three
are about name servers that do not answer and one says the firewall has no rules: true, and about
the lab rather than the portal, because nothing in the lab reaches the internet and lesson 5 writes
the firewall. **Reading a warning is deciding which kind it is.**

## Then suggestions

```
ana@web:~$ sudo grep -c '^suggestion' /var/log/lynis-report.dat
43
ana@web:~$ sudo grep -E '^suggestion.*(AUTH|BANN|KRNL-5820|FILE-6310)' /var/log/lynis-report.dat | cut -d'|' -f1,2
suggestion[]=KRNL-5820|If not required, consider explicit disabling of core dump in /etc/security/limits.conf file
suggestion[]=AUTH-9230|Configure password hashing rounds in /etc/login.defs
suggestion[]=AUTH-9262|Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc
suggestion[]=AUTH-9282|When possible set expire dates for all password protected accounts
suggestion[]=AUTH-9284|Look at the locked accounts and consider removing them
suggestion[]=AUTH-9286|Configure minimum password age in /etc/login.defs
suggestion[]=AUTH-9286|Configure maximum password age in /etc/login.defs
suggestion[]=AUTH-9328|Default umask in /etc/login.defs could be more strict like 027
suggestion[]=FILE-6310|To decrease the impact of a full /home file system, place /home on a separate partition
suggestion[]=FILE-6310|To decrease the impact of a full /var file system, place /var on a separate partition
suggestion[]=BANN-7126|Add a legal banner to /etc/issue, to warn unauthorized users
suggestion[]=BANN-7130|Add legal banner to /etc/issue.net, to warn unauthorized users
```

A **suggestion** is a check that did not pass and that Lynis does not consider urgent. Each one
names its test id, and the id is what makes it actionable: `lynis show details` prints what the
test looked at.

```
ana@web:~$ sudo lynis show details AUTH-9204 | head -8
2026-10-23 02:04:03 Performing test ID AUTH-9204 (Check users with an UID of zero)
2026-10-23 02:04:03 Test: Searching accounts with UID 0
2026-10-23 02:04:03 Result: Found more than one administrator accounts
2026-10-23 02:04:03 Warning: Multiple users with UID 0 found in passwd file [test:AUTH-9204] [details:-] [solution:-]
2026-10-23 02:04:03 Administrator account: suporte:0
2026-10-23 02:04:03 ====
```

Read them as a list of questions, not a list of orders. A legal banner in `/etc/issue` is an
argument some legal departments make and others do not. A separate partition for `/home` is
impossible to retrofit on a running server and pointless in a container. Core dumps disabled is
cheap and worth doing. Each one needs a decision, and the decision is about this machine.

**What Lynis cannot know matters too.** Nothing in its 259 tests knows that this machine is a
portal whose job is two ports, so none of its eight warnings is about the FTP server, telnet or the
SNMP community `public` that lesson 1 found in minutes. An auditor knows the checks; only you know
the job, which is why the baseline you write later in this lesson is your own.
