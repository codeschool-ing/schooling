---
title: A rule written the wrong way round
version: 1
---

The name server in the DMZ needs to fetch its updates over HTTPS. The matrix has no DMZ-to-internet row,
so a rule is added:

```
root@fw:~# nft add rule ip filter forward iifname eth0 oifname eth1 ip saddr 192.0.2.53 tcp dport 443 counter accept comment '"dns fetches its updates"'
```

Then `dns` tries:

```
ana@dns:~$ probe remote:443
remote:443             blocked
root@fw:~# nft list chain ip filter forward | grep "its updates" | sed "s/^\t*//"
iifname "eth0" oifname "eth1" ip saddr 192.0.2.53 tcp dport 443 counter packets 0 bytes 0 accept comment "dns fetches its updates"
```

**Blocked, and the rule's counter is 0.** Read it slowly: `iifname eth0 oifname eth1` means *arriving
from the internet and leaving into the DMZ*, while `ip saddr 192.0.2.53` says the packet comes from
`dns`, which lives in the DMZ. No packet can satisfy both, so the rule is not wrong in any way nftables
could complain about; it is merely impossible. The intended rule is `iifname eth1 oifname eth0`.

Impossible rules are easy to write because a rule has two ends and each is described twice, once by
interface and once by address. They are also easy to find: **a rule whose counter stays at zero after
the traffic it was written for has been tried** is shadowed, impossible, or describing traffic that does
not exist. All three are worth knowing about.

| symptom | usual cause |
|---|---|
| counter at 0, the traffic still passes | shadowed by an accept above it |
| counter at 0, the traffic is still dropped | wrong direction, wrong interface, or a typo in an address |
| counter climbing, but on the wrong traffic | a mask or a port range wider than intended |
