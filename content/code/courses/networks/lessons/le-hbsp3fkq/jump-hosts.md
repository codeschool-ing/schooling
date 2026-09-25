---
title: Hopping through a machine
version: 1
---

The company's web server, `www`, accepts SSH only from the office's public address, a common and
sensible rule. From home, the connection goes nowhere:

```
ana@home:~$ ssh -o ConnectTimeout=5 192.0.2.80 hostname
ssh: connect to host 192.0.2.80 port 22: Connection timed out
ana@home:~$ eval $(ssh-agent) >/dev/null
ana@home:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@home:~$ ssh -J ana@office.example.com:2222 www.example.com
The authenticity of host 'www.example.com (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:U+Bkk5q+PbWG3Mc+gWmCF0v3GJIoOHojfGM7BzNHKBo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'www.example.com' (ED25519) to the list of known hosts.
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@www:~$ hostname
www
ana@www:~$ exit
logout
Connection to www.example.com closed.
```

The direct attempt gave up after the five seconds `ConnectTimeout=5` allowed: www's firewall dropped it
without answering (lesson 3's difference between a drop and a refusal). `ssh -J` goes through the
office server instead. ssh connects to the server first, asks it to open a connection to
`www.example.com` port 22, and then runs a second, complete SSH session through that connection. Seen
from www, the connection comes from the office's address, and is let in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A jump host. Home, at 198.51.100.77, tries to reach www at 192.0.2.80 directly, and the connection is dropped, because www accepts SSH only from the office&#x27;s address, 203.0.113.2. With ssh -J, home first connects to the office server through router port 2222. The server then opens a connection to www, which leaves the office from 203.0.113.2 and is allowed. The SSH session with www runs inside that path, end to end, from home to www.\"><defs><marker id=\"jp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">home</text><text x=\"32\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"295\" y=\"118\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"307\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"307\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"592\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><path d=\"M140 48 L578 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">dropped: www accepts SSH only from 203.0.113.2</text><path d=\"M140 84 L293 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\"></path><text x=\"24\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">first hop, via router:2222</text><path d=\"M425 134 L578 84\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\"></path><text x=\"456\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">from 203.0.113.2: allowed</text><path d=\"M140 68 L360 106 L578 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\" stroke-dasharray=\"2 3\"></path><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the session with www runs inside, end to end</text></svg>", "caption": "The server only relays bytes it cannot read. Keys, passwords and host-key checks are between home and www, which is why home's known_hosts, not the server's, gained www's key."}
```

**The server in the middle only relays bytes.** The session with www is encrypted end to end between
home and www, and the key never leaves home. The host key ssh asked about was www's, stored in home's
`known_hosts`. `<no hostip for proxy command>` is ssh saying it never learned www's address itself,
because the server did the connecting. In `~/.ssh/config`, a `ProxyJump office` line in www's block
makes every connection take that path.

A machine that exists to be hopped through is called a **jump host**, or a bastion, and it is the one
door a whole network of servers is reached by.
