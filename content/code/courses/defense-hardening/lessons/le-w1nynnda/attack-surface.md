---
title: What hardening is, and where it starts
version: 1
---

**Hardening is removing what a machine does not need, and tightening what it keeps.** A server is
installed to do a job. Everything else it does, every service listening on a port, every account
that can log in, every program that came along with a package, is something that can go wrong
without having done any good. The sum of those things is the machine's **attack surface**, and a
defender's first job is to make it as small as the job allows.

The common picture is the opposite: hardening as adding things, a security product here, a stronger
setting there. Most of this course does add controls, and lessons 7 to 14 are about them. But a
control protects what is there, and the cheapest service to protect is the one that is not
running. A port nobody listens on needs no patch, no firewall rule and no monitoring.

**You cannot remove what you have not listed.** That is the principle the other eighteen lessons rest on, and lesson 18 gives it its full treatment.
Inventory, of machines and of what runs on
them, is the basis of every defence, because a control applied to "all our servers" protects
exactly the servers somebody remembered. This lesson starts with the smallest inventory there is,
one machine, and makes it the habit of every lesson after it: **measure first, change, then measure
again.**

## The portal as it was handed over

`web` is Jatobá's client portal, a page served by nginx in front of a small Python program. Its
previous administrator installed things over the years and removed none of them. You know what the
portal needs, a web server and a way for an administrator to log in, and nothing else. So start
where an attacker would, from another machine on the same network, and ask what `web` answers to.
`nmap` sends a connection attempt to the thousand most common TCP ports and reports which ones
accepted:

```
ana@desk:~$ nmap web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:13 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000089s latency).
rDNS record for 192.168.60.10: web.jatoba.example
Not shown: 995 closed tcp ports (conn-refused)
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
23/tcp  open  telnet
80/tcp  open  http
111/tcp open  rpcbind

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
ana@desk:~$ sudo nmap -sU -p 111,161,5353 web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:13 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.00016s latency).
rDNS record for 192.168.60.10: web.jatoba.example

PORT     STATE         SERVICE
111/udp  open          rpcbind
161/udp  open          snmp
5353/udp open|filtered zeroconf
MAC Address: 52:54:00:A8:3C:0A (QEMU virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 1.42 seconds
```

Five TCP ports accept a connection, where the job needs two: **22** for SSH and **80** for the
portal. The UDP scan needs `sudo` because it builds its own packets, and it finds three more
services. `open|filtered` on 5353 means no answer came back, which for UDP can mean a service that
stays quiet or a firewall that drops; the next section asks the machine itself.

Each of those eight is a program somebody could talk to without logging in, and each comes with the
bugs its authors have not found yet. FTP and telnet send passwords in clear text across the
network. `rpcbind` exists to help clients find NFS services this machine does not offer. SNMP
version 2 is answered by anybody who knows the community string, and the next section shows that
this one is `public`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-surface\" aria-label=\"The portal server web drawn twice. On the left, as it was handed over: eight listeners on its edge, TCP 21 ftp, 22 ssh, 23 telnet, 80 http and 111 rpcbind, and UDP 111 rpcbind, 161 snmp and 5353 mdns. Six of them are marked as not needed by the job. On the right, after the lesson: only TCP 22 ssh and TCP 80 http, and the portal itself on 127.0.0.1:8080 inside the box, reachable only from the machine.\"><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">as handed over</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">after lesson 1</text><rect x=\"40.0\" y=\"50.0\" width=\"150.0\" height=\"220.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"52.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8080</text><rect x=\"190.0\" y=\"60.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 21</text><text x=\"312.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ftp</text><rect x=\"190.0\" y=\"85.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"312.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ssh</text><rect x=\"190.0\" y=\"110.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 23</text><text x=\"312.0\" y=\"120.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">telnet</text><rect x=\"190.0\" y=\"135.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"145.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"312.0\" y=\"145.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">http</text><rect x=\"190.0\" y=\"160.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"170.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 111</text><text x=\"312.0\" y=\"170.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind</text><rect x=\"190.0\" y=\"185.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"195.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 111</text><text x=\"312.0\" y=\"195.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind</text><rect x=\"190.0\" y=\"210.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"220.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 161</text><text x=\"312.0\" y=\"220.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">snmp</text><rect x=\"190.0\" y=\"235.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"245.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 5353</text><text x=\"312.0\" y=\"245.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mdns</text><rect x=\"400.0\" y=\"50.0\" width=\"150.0\" height=\"220.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"412.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8080</text><rect x=\"550.0\" y=\"85.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"672.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ssh</text><rect x=\"550.0\" y=\"135.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"145.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"672.0\" y=\"145.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">http</text><text x=\"615.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the job, and nothing else</text><rect x=\"250.0\" y=\"280.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a listener the job does not need</text></svg>", "caption": "Eight listeners where the job needs two. Every marked tab is a program a stranger can talk to."}
```

**Scan only machines you are responsible for.** Your own lab is yours to probe in any way you like.
Outside it, a port scan of somebody else's network is at best a breach of their terms and at worst a
crime, and an authorised scan at work is one somebody wrote down beforehand.
