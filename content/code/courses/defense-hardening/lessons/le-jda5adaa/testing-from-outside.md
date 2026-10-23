---
title: What a dropped and a refused port look like
version: 1
---

**A rule set is a claim until a client has been refused by it.** Ask again from the other side. From
`desk`, which is not an administrative machine, and from `admin`, which is:

```
ana@desk:~$ for p in 21 22 80; do nc -zv -w2 web $p; done
nc: connect to web (192.168.60.10) port 21 (tcp) timed out: Operation now in progress
nc: connect to web (192.168.60.10) port 22 (tcp) timed out: Operation now in progress
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
ana@admin:~$ nc -zv -w2 web 22; ssh web hostname
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
web
ana@web:~$ sudo ss -Htln | awk '{print $4}' | wc -l
6
```

FTP and SSH now time out from `desk`; the portal answers. From `admin`, SSH works. And on `web`,
nothing changed: the last command counts six listeners, exactly as before. The services are still
there, unreachable, which is why lesson 1's purge and this filter belong together.

The counter at the end of the chain shows what the policy dropped:

```
ana@web:~$ sudo nft list chain inet host input
table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		icmp type echo-request accept
		tcp dport 80 accept
		ip saddr { 192.168.60.30, 192.168.60.40 } tcp dport 22 accept
		counter packets 4 bytes 240
	}
}
```

Four packets of 60 bytes: one connection attempt to port 21 and one to port 22, each sent twice,
because a client that hears nothing tries again before it gives up.

## Drop or reject

A dropped packet gets no answer, and the client waits until its own timeout:

```
ana@desk:~$ time nc -zv -w3 web 21
nc: connect to web (192.168.60.10) port 21 (tcp) timed out: Operation now in progress

real	0m3.006s
user	0m0.003s
sys	0m0.000s
```

Three seconds, the timeout `-w3` asked for. The alternative is to **reject**: the machine answers
that the port is unreachable, and the client gives up at once. Change the last line to
`counter reject` and try again:

```
ana@web:~$ sed "s/^\t\tcounter$/\t\tcounter reject/" nftables.conf > reject.conf && grep reject reject.conf && sudo nft -f reject.conf
		counter reject
ana@desk:~$ time nc -zv -w3 web 21
nc: connect to web (192.168.60.10) port 21 (tcp) failed: Connection refused

real	0m0.003s
user	0m0.000s
sys	0m0.003s
ana@desk:~$ sudo nmap -Pn -p 21,22,23,80,111 web | grep tcp
21/tcp  filtered ftp
22/tcp  filtered ssh
23/tcp  filtered telnet
80/tcp  open     http
111/tcp filtered rpcbind
```

`nc` fails in three milliseconds with `Connection refused`, where it waited three seconds before.
`nmap` still calls the ports `filtered`, and the reason is worth knowing: `reject` sends an ICMP
*port unreachable* message, and `nmap` reads that as a firewall answering for the port. A port with
no listener and no firewall answers with a TCP reset, which `nmap` reports as `closed`, as lesson 1's
last scan showed for UDP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-drop-reject\" aria-label=\"The same connection attempt to port 21, answered two ways, on a time line. With drop, desk sends a connection request, hears nothing, sends it again after a second and gives up when its own three-second timeout runs out. With reject, desk sends one request, web answers at once with port unreachable, and desk reports connection refused within milliseconds.\"><defs><marker id=\"l05-drop-reject-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-drop-reject-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">drop</text><path d=\"M120.0 80.0 L680.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">reject</text><path d=\"M120.0 180.0 L680.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 205.0 L120.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M306.7 205.0 L306.7 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"306.7\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 s</text><path d=\"M493.3 205.0 L493.3 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"493.3\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M680.0 205.0 L680.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 s</text><path d=\"M120.0 80.0 L120.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"124.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><path d=\"M306.7 80.0 L306.7 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"310.7\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><text x=\"676.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timed out</text><text x=\"460.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">silence</text><path d=\"M120.0 180.0 L120.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"124.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><path d=\"M134.0 150.0 L134.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-phosphor)\"></path><text x=\"144.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">port unreachable: refused at once</text></svg>", "caption": "Drop makes the client wait out its own timeout. Reject answers it."}
```

| | the client sees | suits |
|---|---|---|
| **drop** | silence, then its own timeout | an address the internet can reach: a scan is slower and learns less |
| **reject** | an immediate refusal | an internal network, where a person debugging a connection deserves a fast, honest answer |

Neither one hides the machine: the portal is still open on 80, and a host that answers on one port is
a host. For `web`, drop stays. The next section makes it survive a reboot.
