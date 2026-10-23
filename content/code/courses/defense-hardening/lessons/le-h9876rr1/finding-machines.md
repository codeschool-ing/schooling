---
title: Finding the machines
version: 1
---

**Start with what the firm believes it has.** At Jatobá that belief is a short file kept by the person
who looks after IT: one line per machine, with its address, its role, the person responsible for it
and how much the firm would suffer if it were lost. Write it on `admin` as `hosts.csv`:

```
name,address,role,owner,criticality
web,192.168.60.10,portal,Marta,high
desk,192.168.60.20,workstation,Rafael,low
admin,192.168.60.30,administration,Marta,high
jump,192.168.60.40,bastion,Marta,high
dns,192.168.60.53,resolver,Marta,medium
```

Five machines. Now ask the network. `nmap -sn` sends no port probes, only enough to learn which
addresses answer at all, which is the gentlest question there is and the one to start any discovery
with. As with every scan in this course, **ask it only of a network you are responsible for**:

```
ana@admin:~$ nmap -sn 192.168.60.0/24 | grep -E "report|done"
Nmap scan report for sw.jatoba.example (192.168.60.2)
Nmap scan report for web.jatoba.example (192.168.60.10)
Nmap scan report for desk.jatoba.example (192.168.60.20)
Nmap scan report for admin.jatoba.example (192.168.60.30)
Nmap scan report for jump.jatoba.example (192.168.60.40)
Nmap scan report for dns.jatoba.example (192.168.60.53)
Nmap scan report for trap.jatoba.example (192.168.60.66)
Nmap done: 256 IP addresses (7 hosts up) scanned in 2.31 seconds
```

Seven machines answer where the file lists five. The difference is the first finding of the lesson,
and the shell can compute it: the addresses `nmap` found that are not in the file.

```
ana@admin:~$ nmap -sn -oG - 192.168.60.0/24 | awk "/Up\$/{print \$2}" | sort > found.txt; cut -d, -f2 hosts.csv | tail -n +2 | sort > listed.txt; comm -23 found.txt listed.txt
192.168.60.2
192.168.60.66
```

Two machines nobody listed. `192.168.60.2` is `sw`, the switch: infrastructure is the commonest thing
to leave off an inventory, and it is also something that can be configured badly, run out-of-date
software and be broken into. `192.168.60.66` is `trap`, which lesson 13 made a honeypot on purpose;
on a real network, an address that answers and appears in no record is a machine somebody plugged in
and nobody owns. **The response is the same either way: find the owner, then decide**. Either it goes
on the list with a name beside it, or it comes off the network.

## What a sweep cannot see

A sweep sees what answers, at the moment it runs. It misses the laptop at home this week, the machine
whose firewall drops even this probe, and everything on another segment. That is why real inventories
combine sources: the sweep, the DHCP server's leases, the switch's table of the hardware addresses it
has seen on each port, which lesson 4 is about, and the agents that report from each machine wherever it is. Each one catches
something the others miss, and the inventory is their union, checked against the list.
