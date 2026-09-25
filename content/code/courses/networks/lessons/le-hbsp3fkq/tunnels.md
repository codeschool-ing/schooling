---
title: Carrying another connection through SSH
version: 1
---

The office server has a small web page showing the state of the backups. It listens only on
`127.0.0.1`, the server talking to itself, so nothing on the network can reach it:

```
ana@laptop:~$ curl -sS -m 3 http://192.168.10.10:8080/
curl: (7) Failed to connect to 192.168.10.10 port 8080 after 0 ms: Couldn't connect to server
ana@server:~$ ss -tln | grep 8080
LISTEN 0      5          127.0.0.1:8080      0.0.0.0:*          
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh -f -N -L 8080:127.0.0.1:8080 office
ana@laptop:~$ curl -s http://127.0.0.1:8080/
<h1>Office server: backups</h1>
<p>Last backup: finished.</p>
```

`curl` from the laptop was refused, and `ss` shows why: `127.0.0.1:8080`, not `0.0.0.0:8080`.
`ssh -L 8080:127.0.0.1:8080 office` makes the laptop's own port 8080 a door into the server. Whatever
connects to it is carried inside the SSH connection, and sshd, on the server, connects to `127.0.0.1`
port 8080 on the other side. `-f` sends ssh to the background and `-N` runs no command, since the
tunnel is the whole point.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A local port forward. On the laptop, curl asks for 127.0.0.1 port 8080, where the ssh client started with -L is listening. The client carries the request inside its encrypted connection to the server&#x27;s port 22. On the server, sshd opens a connection to 127.0.0.1 port 8080, the backups page, which listens only there. A direct connection from the laptop to 192.168.10.10 port 8080 is refused.\"><defs><marker id=\"tn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"210\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"500\" y=\"20\" width=\"210\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"512\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"22\" y=\"50\" width=\"190\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl 127.0.0.1:8080</text><rect x=\"120\" y=\"126\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh -L</text><rect x=\"512\" y=\"126\" width=\"80\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sshd</text><rect x=\"512\" y=\"50\" width=\"190\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"522\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backups page, 127.0.0.1:8080</text><path d=\"M165 84 L165 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><path d=\"M210 143 L510 143\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">encrypted, inside the connection to port 22</text><path d=\"M552 126 L552 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><path d=\"M212 67 L510 67\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">192.168.10.10:8080: refused</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">-L 8080:127.0.0.1:8080</text></svg>", "caption": "On the far side of -L, 127.0.0.1 means the server itself, because that is where sshd makes the last connection. The page never listened on the network, and still does not."}
```

Read the three parts as *local port* : *destination* : *destination port*, where **the destination is
seen from the server**. `127.0.0.1` means the server itself; another machine's address there would
reach a machine only the server can see.

Two relatives were not run for this lesson. `-R` is the mirror image: a port on the server leads back to
the client, which is how somebody behind a NAT offers a way in without a rule on the router. `-D 1080`
turns ssh into a SOCKS proxy, so a browser configured to use it browses from the server's side. Both
are useful, and both carry traffic past a firewall that was not written to expect them, which is why
some servers forbid forwarding with `AllowTcpForwarding no`.
