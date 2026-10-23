---
title: Drift, and the exceptions you write down
version: 1
---

**A baseline is true on the day it is applied and drifts from the day after.** Somebody fixes an
urgent problem by hand at night, and the fix stays. On `web`, imagine a colleague who needed to log
in as root for an emergency and added one line in a new file:

```
ana@web:~$ echo "PermitRootLogin yes" | sudo tee /etc/ssh/sshd_config.d/05-quickfix.conf
PermitRootLogin yes
ana@web:~$ sudo bash check.sh | grep FAIL; echo "failed: ${PIPESTATUS[0]}"
FAIL JAT-04 root may not log in over SSH
failed: 1
ana@admin:~$ ansible-playbook -i hosts.ini harden.yml | tail -2
web                        : ok=7    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

The check fails `JAT-04` at once, because `05-quickfix.conf` sorts before `10-hardening.conf` and
`sshd` keeps the first value it reads, exactly as lesson 1 found. **The playbook, run again, says
`changed=0`.** It was asked to make sure `10-hardening.conf` holds four lines, and it does. It was
never asked whether root can log in, and it cannot see a file it does not manage.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-fix-and-check\" aria-label=\"Two programs look at the same SSH server from different sides. On the left, the playbook on admin writes the file 10-hardening.conf and nothing else. In the middle, sshd reads every file in sshd_config.d in name order and keeps the first value of each setting. Somebody adds 05-quickfix.conf, which sorts first, so root logins are allowed again. On the right, check.sh asks sshd -T for the effective value and reports JAT-04 as failed. The playbook, which only knows its own file, reports changed=0.\"><defs><marker id=\"l02-fix-and-check-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"170.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">harden.yml</text><text x=\"105.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">writes its own file</text><text x=\"105.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">changed=0</text><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">it sees nothing wrong</text><rect x=\"255.0\" y=\"30.0\" width=\"210.0\" height=\"210.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sshd_config.d/</text><rect x=\"270.0\" y=\"70.0\" width=\"180.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">05-quickfix.conf</text><text x=\"282.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PermitRootLogin yes</text><rect x=\"270.0\" y=\"130.0\" width=\"180.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10-hardening.conf</text><text x=\"282.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PermitRootLogin no</text><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read in name order;</text><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the first value is kept</text><path d=\"M190.0 75.0 L270.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-fix-and-check-dh-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"40.0\" width=\"170.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"615.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks sshd -T</text><path d=\"M465.0 95.0 L530.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-fix-and-check-dh-ah-paper-dim)\"></path><text x=\"615.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">FAIL JAT-04</text><text x=\"615.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">it sees the effect</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the fix knows its file; the check knows the result</text></svg>", "caption": "A playbook can only report what it changed. A check reports what is true."}
```

That is the strongest argument for keeping the check separate from the fix, and for running both on
a schedule: the playbook puts back what it owns, and the check notices what nobody owns. Lesson 3
runs them across several machines and on a timer. Here the fix is a decision rather than a
command: was the emergency real, and is it over? It was, and it is, so the file goes:

```
ana@web:~$ sudo rm /etc/ssh/sshd_config.d/05-quickfix.conf && sudo systemctl reload ssh && sudo bash check.sh | grep -c PASS
7
```

Seven controls pass again. The lasting fix is a task in the playbook that removes any drop-in in
`sshd_config.d` other than its own, so the next quick fix lasts until the next run.

## When a control does not fit

Some recommendations are wrong for a particular machine, and applying them anyway breaks the job.
Lynis suggested a separate partition for `/home` and for `/var`. On a container, and on most
virtual machines built from one image, there is nothing to partition, and the risk the
recommendation addresses, a full disk taking the system down, is handled by monitoring instead.

**An exception is a control you decided not to apply, written down where the next auditor will
find it.** In Lynis that place is a profile, and `skip-test` is how a test is set aside:

```
ana@web:~$ printf "skip-test=FILE-6310\n" | sudo tee /etc/lynis/custom.prf
skip-test=FILE-6310
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed|Skipped" lynis.txt; grep -c FILE-6310 lynis.txt
  Hardening index : 66 [#############       ]
  Tests performed : 256
0
```

The skipped test no longer appears in the screen report, which counts 256 tests. The index went
**down**, from 69 to 66, because a skipped test changes what Lynis counts and its arithmetic does
not reward leaving one out. Had it gone up, the machine would have been no better either. The
profile line records that the test was set aside; it records nothing about why, and that is what
an auditor asks.

A written exception carries four things, and an organisation keeps them beside the baseline, not in
somebody's memory:

| | for `FILE-6310` on `web` |
|---|---|
| what is not applied | separate partitions for `/home` and `/var` |
| why | the machine is a container; there is no disk to partition |
| what covers the risk instead | free space monitored, with an alert at 80 % |
| who decided, and until when | the administrator, reviewed when the portal moves to new hardware |

The last row is the one that keeps an exception from becoming permanent by default. **An exception
without an expiry is a weakness with a reason attached.** Lesson 17 applies the same rule to a
patch that cannot be installed on time, and lesson 16 to a vulnerability that cannot be fixed.
