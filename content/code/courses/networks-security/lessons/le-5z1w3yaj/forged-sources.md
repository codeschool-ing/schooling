---
title: A source address is a claim
version: 1
---

Every packet carries the address it came from, and **the sender writes that field**. Nothing in IP
checks it. A machine can put any address it likes there, and the packet travels just as well; what it
cannot do is receive the answer, which goes to whoever really owns the address. That is **address
spoofing**, and it is the network-layer cousin of lesson 7's ARP spoofing, where the lie was about which
MAC owns an address on one segment.

Forged sources matter for three reasons a defender meets:

| use of a forged source | why it works | lesson |
|---|---|---|
| getting past a rule that trusts an address | a firewall rule `ip saddr 192.168.20.0/24 accept` believes the field | this lesson |
| reflection and amplification | the answers go to the forged address, the victim | 6 |
| hiding where a flood comes from | each packet claims a different, random source | 6 |

The lab can show the first on its own equipment. In your lab this lesson starts from
`sudo bash nslab.sh reset` followed by `sudo bash dnssec.sh`, the script of section 06, and with the
company's policy loaded on `fw` plus one rule that lets the staff LAN ask the signed zone of
section 06 on its port, 5300:

```sh
# on fw, as root
nft -f baseline.nft; nft insert rule ip filter forward index 1 iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 5300 ct state new accept comment \"the resolver asks the signed zone\"
# on remote, as root
ip addr add 192.168.20.99/32 dev eth0
# on laptop, as root
ip addr add 198.51.100.7/32 dev eth0
```

The last two lines give `remote`, on the internet, a second address from the company's **server
range**, `192.168.20.99`, and `laptop` one that belongs to nobody, for section 04. `remote` uses its
new address as the source of a request to the shop, and a recording on `www`, started a moment before
with `setsid timeout 6 tcpdump -n -i eth0 -c 1 "tcp dst port 443 and src 192.168.20.99" > /root/syn.txt 2>/dev/null </dev/null &`,
shows what arrived:

```
ana@remote:~$ curl -s -m2 --interface 192.168.20.99 https://www.example.com/; echo "exit $?"
exit 28
root@www:~# cut -d" " -f2-7 syn.txt
IP 192.168.20.99.37688 > 192.0.2.80.443: Flags [S],
```

The request timed out, as it had to: `www` answered `192.168.20.99`, and that address is not on the
internet, so the answer went nowhere useful. **But the `SYN` reached `www` claiming to come from the
servers segment**, through a firewall whose rules were written about zones. Any rule anywhere that
trusts `192.168.20.0/24` as "our servers" just trusted a packet from the internet.

The fix is not to stop trusting addresses entirely, which would leave little to write rules with. It
is to **check that a source address arrives from where that address lives**, which is exactly the
fact lesson 1 said interfaces carry.
