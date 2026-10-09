---
title: Guardrails, and undoing
version: 1
---

Automation fails in a particular way: **quickly, at scale, and with confidence.** A rule that misfires
once puts one wrong alert in a queue; a playbook that misfires blocks an address in a second, and if that
address is the backup provider, last night's backup did not happen and nobody knows. The defences are
written into the playbook before its first run:

| guardrail | what it prevents |
|---|---|
| **a never-block list** | blocking a partner, a provider, a payment gateway, or staff working from home |
| **the company's own networks** | an automated action against the infrastructure it is defending |
| **one target per action** | a rule that blocks a range, a subnet or a country by accident |
| **a named approver** | an action nobody can be asked about later |
| **a rate limit** | a flood of alerts turning into a flood of blocks |
| **an undo for every action** | a mistake that outlives the morning it was made |

Two of them, run on purpose:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.150 --approve ana
203.0.113.150: 0 failed logins over 0 accounts, 0 accepted
  refused to block: 203.0.113.150 is on the never-block list
  ticket written: ticket-203.0.113.150.json
root@soc:~# python3 playbook.py /home/ana/week/siem.db 192.168.20.10 --approve ana
192.168.20.10: 0 failed logins over 0 accounts, 0 accepted
  refused to block: 192.168.20.10 is one of the company's own addresses
  ticket written: ticket-192.168.20.10.json
```

The backup provider is refused because a person put it on the list. The file server is refused because it
is inside one of the company's networks. Both runs still wrote a ticket, so the refusal itself is on
record.

The playbook in this lesson has no rate limit; a production one counts its own actions per hour and stops,
and tells somebody, when the count looks like a flood. And every action needs its undo, written and
tested **before** it is needed. Here the undo is two commands: list the chain with handles, and delete the
one the playbook added.

```
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 drop comment "playbook, approved by ana" # handle 3
		ct state new log prefix "fw-new " group 1 # handle 2
	}
}
root@soc:~# ip netns exec fw nft delete rule ip fw forward handle 3
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 hostname
gw
```

The block is gone and the connection works again. An action you cannot reverse in the time it took to make
belongs to a person, not to a playbook.
