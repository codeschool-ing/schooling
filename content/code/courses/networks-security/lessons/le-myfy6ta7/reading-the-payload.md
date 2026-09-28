---
title: Reading past the headers
version: 1
---

**Deep packet inspection** reads the payload as well as the headers, and recognises protocols by
what they say rather than by where they say it. A **next-generation firewall** (NGFW) is a firewall
with that ability built in, so that a rule can name an application instead of a port.

The lab has no commercial NGFW, and it does not need one to show the mechanism. **Suricata** is an
open-source engine that reads traffic and identifies its protocol; lesson 15 uses it to detect, and
here it only watches. It runs on `fw`, listening on the LAN interface, with an empty rule file:

```
root@fw:~# cat /etc/suricata/rules/local.rules; grep -A1 "^rule-files" /etc/suricata/suricata.yaml
rule-files:
  - local.rules
root@fw:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth2 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

Then `laptop` does three things: fetches the web page over HTTPS, tries SSH to `remote` on 443, and
asks `app` for its page over plain HTTP on 8080. The SSH login fails because `ana` has no key on
`remote`, and that does not matter: the conversation still happened.

```
ana@laptop:~$ curl -s -o /dev/null https://www.example.com/
ana@laptop:~$ ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"
ana@203.0.113.50: Permission denied (publickey).
exit 255
ana@laptop:~$ curl -s -o /dev/null http://192.168.20.10:8080/
```

When Suricata stops, it writes a **flow record** for every conversation it saw, with the protocol
it decided the conversation carried:

```
root@fw:~# jq -c "select(.event_type==\"flow\") | [.src_ip, .dest_ip, .dest_port, .app_proto]" /var/log/suricata/eve.json
["192.168.10.20","203.0.113.50",443,"ssh"]
["192.168.10.20","192.0.2.80",443,"tls"]
["192.168.10.20","192.168.20.10",8080,"http"]
```

**Two flows went to port 443 and Suricata named them differently**: `ssh` and `tls`. The third,
on 8080, it named `http` although nothing says 8080 is for HTTP. It decided each one by the first
bytes of the conversation, which is exactly what the port-based rule could not do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three flows from laptop, compared in two columns. In the first column, what a port rule sees: port 443, port 443 and port 8080, all allowed. In the second, the first bytes of the payload and the protocol Suricata named from them: SSH-2.0-OpenSSH, named ssh; a TLS ClientHello for www.example.com, named tls; GET / HTTP/1.1, named http.\"><defs></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">flow</text><text x=\"230\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what a port rule sees</text><text x=\"430\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what the payload says</text><rect x=\"20\" y=\"40\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 203.0.113.50</text><text x=\"230\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 443</text><text x=\"230\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allowed</text><text x=\"430\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SSH-2.0-OpenSSH_9.6p1</text><text x=\"430\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ssh</text><rect x=\"20\" y=\"104\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 192.0.2.80</text><text x=\"230\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 443</text><text x=\"230\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allowed</text><text x=\"430\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClientHello, SNI www.example.com</text><text x=\"430\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tls</text><rect x=\"20\" y=\"168\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 192.168.20.10</text><text x=\"230\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 8080</text><text x=\"230\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allowed</text><text x=\"430\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET / HTTP/1.1</text><text x=\"430\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">http</text></svg>", "caption": "Same headers, different conversations. The port column cannot tell the first two rows apart."}
```

## How the recognition works

Every protocol opens in a recognisable way. SSH begins with a line of text, `SSH-2.0-` and the
software's name, from both sides. TLS begins with a *ClientHello*, a binary record whose first bytes
are fixed by the standard. HTTP begins with a method, a path and `HTTP/1.1`. An engine keeps a
parser for each and tries them on the first bytes of every new flow.

That has a consequence worth knowing: **the verdict arrives a few packets late**. The handshake has
to happen before there is anything to read, so an NGFW lets the first packets through on the port
rule and decides on the application once it has seen enough. A product that "blocks SSH" blocks it
after the SSH greeting, not before the connection.
