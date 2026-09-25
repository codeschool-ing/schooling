---
title: One public address for the whole office
version: 1
---

`192.168.10.20` is a **private address**. The ranges `10.0.0.0/8`, `172.16.0.0/12` and
`192.168.0.0/16` are set aside by RFC 1918 for use inside any building, and the internet does not
route them: millions of offices use `192.168.10.20` at the same time. To go out, the office borrows
the one public address its provider gave it, `203.0.113.2`. That is **NAT**, *network address
translation*, and it is one rule on the office router:

```
ana@router:~$ sudo nft list ruleset
table ip nat {
        chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "eth1" masquerade
        }
}
ana@www:~$ tail -1 /var/log/nginx/access.log
203.0.113.2 - - [25/Sep/2026:13:16:09 -0300] "GET / HTTP/2.0" 200 173 "-" "curl/8.5.0"
```

`masquerade` means: whatever leaves through `eth1`, the provider side, gets the router's own address
on that side as its source. The router remembers each connection it rewrote, and when a reply comes
back to `203.0.113.2`, it puts the laptop's address back and sends it inside. The laptop never knows.

**The web server certainly does not.** Its log records every visitor, and the last line is the laptop
fetching the page a moment before: from `203.0.113.2`. Every machine in the office appears to the
outside as that one address. That is why a website's "block this IP" can shut out a whole office for
one person's mistake, and why nobody outside can connect *in* to the laptop unless the router is told
to forward a port to it, which lesson 7 does for SSH.

Reading and planning private ranges belongs to the networks-addressing course. For support, the sign
to recognise is an address starting with `10.`, `172.16.` to `172.31.`, or `192.168.`: it is inside a
building, and somebody's router is translating it.
