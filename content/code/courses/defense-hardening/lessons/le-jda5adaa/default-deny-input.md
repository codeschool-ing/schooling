---
title: A default-deny rule set for the portal
version: 1
---

**The portal needs two things from the network: HTTP from anybody, and SSH from the administrators.**
The administrators work from `admin` at `.30` and, after lesson 15, through `jump` at `.40`. Everything
else may be dropped. On `web`, write the rule set into a file in your home first, so you can check it
before it touches the running machine:

```
ana@web:~$ cat nftables.conf
#!/usr/sbin/nft -f
# /etc/nftables.conf on web: the portal accepts what its job needs, and nothing else.
flush ruleset

table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		icmp type echo-request accept
		tcp dport 80 accept
		ip saddr { 192.168.60.30, 192.168.60.40 } tcp dport 22 accept
		counter
	}
}
```

Read it from the top, because nftables does. A **table** of the `inet` family handles IPv4 and IPv6
together. The **chain** hooks the `input` path, which sees packets addressed to this machine, and its
**policy** is `drop`: a packet no rule accepts is discarded. Then the rules, in order:

| rule | why |
|---|---|
| `iif "lo" accept` | the machine talking to itself, as nginx does to the portal on 127.0.0.1 |
| `ct state established,related accept` | replies to connections already allowed, so each permission is written once |
| `ct state invalid drop` | packets that belong to no conversation the kernel knows |
| `icmp type echo-request accept` | ping, which monitoring and people use to ask whether the machine is up |
| `tcp dport 80 accept` | the portal, for anybody |
| `ip saddr { … } tcp dport 22 accept` | SSH, from the two administrative machines only |
| `counter` | counts what reaches the end, before the policy drops it |

`flush ruleset` at the top empties every table first, so loading the file twice gives the same
result as loading it once.

## Check, then load

`nft -c` parses the file and builds the rules without installing them. Only when it says nothing is
wrong does the file go in:

```
ana@web:~$ sudo nft -c -f nftables.conf && echo "syntax ok"
syntax ok
ana@web:~$ sudo nft -f nftables.conf && echo loaded
loaded
```

**Load a firewall on a remote machine with a second session already open**, and better, from a
console: a rule set that drops SSH from where you are working locks you out exactly as lesson 1's
SSH change could. In the lab the console is `sudo bash hostlab.sh root web`, which reaches the machine
without the network at all.
