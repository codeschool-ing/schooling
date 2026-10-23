---
title: Two ways to close a port
version: 1
---

**A port is closed in one of two places: on the machine, by nothing listening, or in front of the
listener, by a filter that drops what arrives.** Lesson 1 did the first: it purged the services the
portal did not need, and the port closed because there was no program left behind it. This lesson
does the second, and the two are not alternatives. A defender wants both.

Start the lab with `sudo bash hostlab.sh up web desk admin`. As in every lesson, `web` is fresh:
the FTP server, telnet and `rpcbind` that lesson 1 removed are back. From `desk`, try five ports:

```
ana@desk:~$ for p in 21 22 23 80 111; do nc -zv -w2 web $p; done
Connection to web (192.168.60.10) 21 port [tcp/ftp] succeeded!
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
Connection to web (192.168.60.10) 23 port [tcp/telnet] succeeded!
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
Connection to web (192.168.60.10) 111 port [tcp/sunrpc] succeeded!
```

On `web`, the same five, plus the portal behind nginx, are listening:

```
ana@web:~$ sudo ss -Htln | awk '{print $4}'
127.0.0.1:8080
0.0.0.0:111
0.0.0.0:80
0.0.0.0:21
0.0.0.0:22
0.0.0.0:23
```

## What each way protects against

| | closes the port by | protects against | misses |
|---|---|---|---|
| **removing the listener** | taking away the program | its bugs, now and later; its configuration mistakes | a new listener tomorrow: a package, a test server, a tool somebody started by hand |
| **filtering** | dropping packets before any program sees them | every listener the rules do not name, including tomorrow's | a flaw in a service the rules allow, which is reachable by design |

The two cover each other's gaps. Lesson 1's purge means the FTP server cannot be attacked at all,
whatever the firewall says. A filter that accepts only what the job needs means that the next
service somebody installs, by accident or on purpose, is unreachable until somebody decides it
should not be. **A host firewall is the inventory of what may be reached, enforced by the kernel.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-two-layers\" aria-label=\"Packets from desk arrive at web and meet two layers. The first is the input chain of the firewall, with policy drop: port 80 is accepted for anybody, port 22 only from admin and jump, and everything else stops there. The second layer is the listeners on the machine. FTP, telnet and rpcbind are still listening behind the firewall, unreachable; lesson 1 removed them as well, so that neither layer depends on the other.\"><defs><marker id=\"l05-two-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-two-layers-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"110.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"190.0\" y=\"30.0\" width=\"170.0\" height=\"230.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">input chain</text><text x=\"275.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">policy drop</text><rect x=\"205.0\" y=\"90.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"337.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">anybody</text><rect x=\"205.0\" y=\"122.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"337.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">admin, jump</text><rect x=\"205.0\" y=\"154.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 21</text><text x=\"337.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dropped</text><rect x=\"205.0\" y=\"186.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 23</text><text x=\"337.0\" y=\"198.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dropped</text><rect x=\"205.0\" y=\"218.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 111</text><text x=\"337.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dropped</text><path d=\"M130.0 140.0 L190.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-paper-dim)\"></path><rect x=\"430.0\" y=\"30.0\" width=\"270.0\" height=\"230.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">listeners on web</text><rect x=\"445.0\" y=\"90.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">nginx :80</text><rect x=\"445.0\" y=\"122.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sshd :22</text><rect x=\"445.0\" y=\"154.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">vsftpd :21</text><rect x=\"445.0\" y=\"186.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">inetd :23</text><rect x=\"445.0\" y=\"218.0\" width=\"240.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"457.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">rpcbind :111</text><path d=\"M345.0 102.0 L445.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-phosphor)\"></path><path d=\"M345.0 134.0 L445.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-two-layers-dh-ah-phosphor)\"></path><text x=\"565.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">still listening, unreachable</text></svg>", "caption": "The filter hides what is still running. Removing it, as lesson 1 did, is the other layer."}
```

## Default deny

The filter in the next section starts from one rule written last and applying to everything: drop.
Each rule above it is a permission for one thing the job needs. That order is called **default
deny**, and it is the shape every firewall rule set in this course takes. The opposite, accept
everything and drop the known bad, is a list of the attacks somebody thought of on the day they
wrote it.

This lesson filters what arrives at the machine, the **input** direction. Filtering what a machine
sends, and filtering per application, are lesson 10's subject. The second half of this lesson closes
a different kind of port: the USB socket on a workstation, which is a way in for data, and out.
