---
title: Reaching the office from home
version: 1
---

The server has a private address, `192.168.10.10`, which means nothing on the internet (lesson 2). From
home, the only address of the office anybody can reach is the router's, `203.0.113.2`, which is what
`office.example.com` points to. So the router needs a rule: connections arriving on its public side
for port 2222 go to the server's port 22.

```
ana@router:~$ sudo nft add table ip nat
ana@router:~$ sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority dstnat; }'
ana@router:~$ sudo nft add rule ip nat prerouting iifname "eth1" tcp dport 2222 dnat to 192.168.10.10:22
ana@router:~$ sudo nft list chain ip nat prerouting
table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                iifname "eth1" tcp dport 2222 dnat to 192.168.10.10:22
        }
}
```

That is **port forwarding**, destination NAT: the router rewrites where the connection is going. From
home:

```
ana@home:~$ ssh -p 2222 office.example.com
The authenticity of host '[office.example.com]:2222 ([203.0.113.2]:2222)' can't be established.
ED25519 key fingerprint is SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[office.example.com]:2222' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/ana/.ssh/id_ed25519': 
Last login: Fri Sep 25 15:10:53 2026 from 192.168.10.20
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@server:~$ hostname; who
server
ana      pts/1        2026-09-25 15:11 (198.51.100.77)
ana@server:~$ exit
logout
Connection to office.example.com closed.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Reaching the office server from home. Home, at 198.51.100.77, on the internet, connects to the office&#x27;s public address, 203.0.113.2, port 2222. The router&#x27;s rule rewrites the destination to the server&#x27;s private address, 192.168.10.10, port 22, and passes the connection on. The source address is not changed, so the server sees the connection come from 198.51.100.77.\"><defs><marker id=\"ou-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the internet</text><rect x=\"300\" y=\"16\" width=\"410\" height=\"180\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"312\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the office</text><rect x=\"20\" y=\"80\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">home</text><text x=\"32\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"320\" y=\"80\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">router</text><text x=\"332\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"566\" y=\"80\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"578\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M130 105 L318 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ou-ah)\"></path><text x=\"138\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to 203.0.113.2, port 2222</text><path d=\"M440 105 L564 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ou-ah)\"></path><text x=\"452\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rewritten to 192.168.10.10, port 22</text><text x=\"452\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">source stays 198.51.100.77</text></svg>", "caption": "Destination NAT changes where a connection goes and nothing about where it came from, which is why the server's who showed home's address. Port 2222 is only the router's; the server still listens on 22."}
```

ssh asked about the host key again, because to ssh `[office.example.com]:2222` is a different machine
from `192.168.10.10`. The fingerprint is the same `SHA256:lnt8eQ…`, and that is exactly how to know
the router delivered her to the real server. `who` on the server shows the connection coming from
`198.51.100.77`, home's address: the rule changed the destination and left the source alone.

**Port 2222 hides nothing.** Scanners try every port on every address, and an SSH server on the
internet sees login attempts within hours of appearing. What protects it is section 11: keys only, no
passwords. Many offices go further and expose no SSH at all, only a VPN, and reach the server from
inside it.
