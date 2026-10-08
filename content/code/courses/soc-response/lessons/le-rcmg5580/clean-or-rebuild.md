---
title: Clean or rebuild
version: 1
---

After the audit, two ways forward for a host the intruder controlled:

| | clean it | rebuild it |
|---|---|---|
| **what happens** | remove each item the audit found, keep the server | a new server from the standard build, data restored from backup |
| **trusts** | that the audit found everything | that the build and the backup are clean |
| **costs** | little downtime | hours of work and a planned outage |
| **fits** | a contained, well-understood intrusion with no administrator access | anything where the intruder may have had root, or the scope is unclear |

The deciding question is the second row. **An audit finds what it looks for**, and an intruder with root
could have changed anything, including the tools the audit runs. On Thursday the account was an ordinary
user's, and the audit found one key; cleaning is defensible. Lesson 13 still scheduled a rebuild of `gw`,
because nobody can prove a negative about a host a stranger used for an hour, and a rebuild is cheap when
the build is a script.

The lab's build *is* a script, so a rebuild is two commands, and it shows the trap at once:

```
root@soc:~# bash soclab.sh down
root@soc:~# bash soclab.sh up
root@soc:~# ip netns exec fw nft list chain ip fw forward
table ip fw {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ct state new log prefix "fw-new " group 1
	}
}
root@soc:~# ip -n outside addr add 203.0.113.150/24 dev eth0
root@soc:~# ip netns exec outside python3 -m http.server 8080 >/dev/null 2>&1 &
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/
200
```

The chain holds only the logging rule from lesson 1. **The egress rule is gone**, because it lived on the
running firewall, not in `soclab.sh`, and the file server reaches `203.0.113.200` again with a `200`. That is
the general shape of the trap: **rebuild from the old recipe and you rebuild the old hole.** Every fix made
during the response has to go into the source the next build is made from.

The log files are still there: they live in `/var/log/soclab` on the host, outside the namespaces, which is
lesson 3's point about remote logging, arriving from another direction. Rebuild the systems, keep the
evidence.

In the lab, the source for the rule is a one-line file. Write it as `files-egress.nft`:

```
add rule ip fw forward ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter drop comment "INC-2026-014 files egress"
```

`nft -f` reads a file of `nft` commands, the same `add rule` lesson 13 typed:

```
root@soc:~# cat files-egress.nft
add rule ip fw forward ip saddr 192.168.20.10 oifname "eth0" ip daddr != 203.0.113.150 counter drop comment "INC-2026-014 files egress"
root@soc:~# ip netns exec fw nft -f files-egress.nft
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.200:8080/; echo "exit $?"
000
exit 28
root@soc:~# ip netns exec files curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://203.0.113.150:8080/
200
```

Closed again: `000` and exit `28` to `203.0.113.200`, `200` to the backup. In a company, the file would be in
the firewall's configuration under version control, and the rebuild would read it without anybody having to
remember.
