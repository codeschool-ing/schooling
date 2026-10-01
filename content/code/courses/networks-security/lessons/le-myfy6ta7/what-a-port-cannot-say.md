---
title: What a port number cannot say
version: 1
---

Lesson 1's firewall judges **headers**: addresses, protocol, ports. The rule every office writes
first is some version of "staff may browse the web", and in header terms that means TCP to ports 80
and 443:

```
root@fw:~# cat edge.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" tcp dport { 80, 443 } ct state new accept comment "staff may browse"
    iifname "eth2" udp dport 53 ip daddr 192.0.2.53 ct state new accept
    iifname "eth1" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
  }
}
root@fw:~# nft -f edge.nft
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

The last rule of the set lets the proxy in the DMZ reach the application, which lesson 3 is about.
The page loads. Now the same laptop, the same rule, a different machine on the internet:

```
ana@laptop:~$ nc -w2 203.0.113.50 443 </dev/null
SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19
ana@laptop:~$ nc -w2 203.0.113.50 22 </dev/null; echo "exit $?"
exit 1
```

**Port 443 answered with an SSH server's greeting.** `remote` runs SSH on the port a firewall keeps
open for HTTPS, and the rule let it through because the rule asked about the port and nothing else.
Port 22, which is where SSH normally lives, is closed, and that made no difference at all.

A port number is a convention between two programs. The server chooses what to listen on and the
client chooses what to ask for, and **nothing on the wire checks that port 443 carries HTTPS**. So
the rule "allow 443" really means "allow any program that agrees to use 443":

| on port 443 | allowed by `tcp dport 443`? |
|---|---|
| a browser fetching a page | yes |
| an SSH session to a machine outside | yes |
| a program sending files to a storage service nobody approved | yes |
| malware reaching the server that gives it orders | yes |

None of these is exotic, and the last one is deliberate: remote-control software
uses 443 because it is the one port every network leaves open. A defender needs a way
to ask **what is actually being said**, and that means reading past the headers.
