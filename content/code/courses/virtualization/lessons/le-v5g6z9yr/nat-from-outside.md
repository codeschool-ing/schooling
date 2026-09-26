---
title: NAT, from the office
version: 1
---

The guest on the default network, and what the office sees of it:

```
ana@vmn:~$ ip -br addr show enp1s0; ip route | head -1
enp1s0           UP             192.168.122.232/24 metric 100 fe80::5054:ff:fe55:d409/64 
default via 192.168.122.1 dev enp1s0 proto dhcp src 192.168.122.232 metric 100 
ana@vmn:~$ curl -sS http://10.0.0.50/
office printer: ready
ana@host:~$ tail -1 /var/log/office-http.log
10.0.0.1 - - [25/Sep/2026 21:14:27] "GET / HTTP/1.1" 200 -
ana@host:~$ sudo ip netns exec printer curl -sS -m 5 http://$(getent hosts vmn | cut -d" " -f1)/
curl: (7) Failed to connect to 192.168.122.232 port 80 after 0 ms: Couldn't connect to server
```

vmn has `192.168.122.232`, from libvirt, and its way out is `192.168.122.1`, the host. It reached the printer. But
the printer's log says the visitor was **`10.0.0.1`**, the host: the office never saw vmn's address.
And when the printer tried to reach vmn, it could not even start: `192.168.122.0/24` means nothing on the
office network, and nobody there has a route to it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"NAT, step by step. vmn sends a request from its own address, 192.168.122.232. The host rewrites the sender to its own office address, 10.0.0.1, and remembers the connection. The printer&#x27;s log records 10.0.0.1. The reply goes to 10.0.0.1, and the host passes it back to vmn.\"><defs><marker id=\"nt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vmn</text><rect x=\"290\" y=\"40\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">host rewrites the sender</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"594\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the printer’s log</text><text x=\"594\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10.0.0.1</text><path d=\"M162 58 L288 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\"></path><text x=\"170\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from 192.168.122.232</text><path d=\"M462 58 L578 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\"></path><text x=\"470\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">from 10.0.0.1</text><path d=\"M 640 92 L 640 106 L 90 106 L 90 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#nt-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replies go to 10.0.0.1, and host passes them back</text></svg>", "caption": "The office network never sees the guest’s address, only the host’s. That is why a NAT guest can reach anything the host can, and nothing can start a conversation with it."}
```

That is NAT's whole character. **A NAT guest can reach anything the host can, and nothing can reach
it.** It is the safest default for a guest that only needs to browse and update, and the wrong one for
a guest that has to be a server to anyone but the host.

The exception is **port forwarding**: a rule on the host that sends one of its own ports to a guest's,
such as the host's port 8080 to the guest's 80. VirtualBox has it in the NAT adapter's *Port
Forwarding* button; libvirt needs a firewall rule of your own. Each forwarded port is a small hole in
NAT's protection, made on purpose.
