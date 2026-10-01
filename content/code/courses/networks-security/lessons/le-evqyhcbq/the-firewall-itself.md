---
title: Protecting the firewall itself
version: 1
---

The `forward` chain protects the zones. The `input` chain protects **`fw`**, and a firewall that can
be administered from anywhere is a single password away from being somebody else's firewall. The
baseline's input chain:

```
root@fw:~# nft list chain ip filter input
table ip filter {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		iifname "eth4" ip saddr 192.168.99.0/24 tcp dport 22 ct state new accept comment "fw is administered from mgmt only"
	}
}
```

Policy `drop`. Replies to `fw`'s own connections and traffic on the loopback interface are allowed,
and new connections only for SSH, only arriving on the management interface, only from the
management range. From the staff LAN and from `admin`:

```
ana@laptop:~$ ping -c1 -W1 192.168.10.1 | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@laptop:~$ probe fw:22
fw:22                  blocked
ana@admin:~$ probe fw:22
fw:22                  refused
```

`laptop` cannot reach `fw`'s SSH port, and from `admin` it says `refused`: the rule let the packet
in and `fw` runs no SSH server in the lab. **The management interface is the only door, and the door
leads to a room nobody has furnished yet.**

## ICMP is not optional

`laptop`'s ping went unanswered, which is the policy working as written and not as intended. Dropping
all ICMP is a common mistake with real costs:

| ICMP message | what breaks without it |
|---|---|
| destination unreachable, including *fragmentation needed* | path MTU discovery: large packets vanish and connections stall mid-transfer |
| time exceeded | `traceroute` shows nothing past this hop |
| echo request and reply | `ping`, the first tool anybody reaches for |

Errors about the firewall's own connections already pass as `related`. For the rest, a rule that
allows the three types that matter, with a rate limit so they cannot be used to flood:

```
root@fw:~# nft list chain ip filter input | grep icmp
		icmp type { destination-unreachable, echo-request, time-exceeded } limit rate 10/second burst 5 packets accept comment "ping and the errors path discovery needs"
ana@laptop:~$ ping -c1 -W1 192.168.10.1 | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.281/0.281/0.281/0.000 ms
```

**Allow ICMP deliberately and rate-limit it**, rather than dropping it and debugging stalled
connections for a week.
