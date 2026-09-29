---
title: A rule set other people can read
version: 1
---

A firewall's rule set outlives the person who wrote it. Four habits keep it readable, and nftables
supports each directly.

**One family for both protocols.** The lab's tables are `ip`, IPv4 only:

```
root@fw:~# nft list tables
table ip filter
```

On a network with IPv6, a `table ip` leaves every IPv6 packet unfiltered, which is a second,
invisible policy of `accept`. The `inet` family handles both with one set of rules. The baseline,
with only its `table` line changed, checks cleanly:

```
root@fw:~# nft -c -f baseline-inet.nft && echo "inet rule set: ok"
inet rule set: ok
```

**Sets instead of repeated rules.** A group of addresses or ports used in several places belongs in a
named set, defined once:

```
root@fw:~# cat sets.nft
table ip filter {
  set admins {
    type ipv4_addr
    elements = { 192.168.99.10 }
    comment "machines allowed to administer servers"
  }
  set admin_ports {
    type inet_service
    elements = { 22, 9100 }
  }
}
root@fw:~# nft -f sets.nft && nft insert rule ip filter forward index 2 ip saddr @admins oifname "eth3" tcp dport @admin_ports ct state new accept comment \"administration, by set\"
root@fw:~# nft list chain ip filter forward | grep "@admins"
		ip saddr @admins oifname "eth3" tcp dport @admin_ports ct state new accept comment "administration, by set"
```

The rule reads *from an admin, to the servers, on an admin port*. Adding a machine to the admins is a
change to the set, not to any rule, and it applies everywhere the set is used:

```
root@fw:~# nft add element ip filter admins { 192.168.99.11 } && nft list set ip filter admins | grep elements
		elements = { 192.168.99.10, 192.168.99.11 }
```

**A comment on every accept**, naming the decision it records, as the baseline does: `"the proxy
reaches the application"` says why the rule exists, which the rule itself cannot.

**The file is the source, and it lives in version control.** The running rule set is a copy of a file
that somebody reviewed, never the other way round. A change is a commit with a reason, a review and
a history, which is also the first place anybody looks when a cell of the matrix turns out to be open
that should not be. Lesson 18 collects the mistakes that review exists to catch.
