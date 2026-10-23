---
title: The sinkhole tells you who
version: 1
---

**A sinkhole is an address that receives traffic meant for somewhere dangerous.** The policy zone
already sends every name under `cobranca-urgente.example.org` to `192.168.60.53`. Whatever program
asked will now connect there, believing it reached the real site, and a small server on that address
can record each visit: when, from which machine, for which name and which path.

The server is a few lines of Python's standard library. Write it as root on `dns` and start it as a
temporary service with `systemd-run`, which gives it a unit name, a journal and a way to stop it:

```
root@dns:~# cat > /root/sinkhole.py <<'EOF'
#!/usr/bin/env python3
"""Answers every web request with one line, and logs who asked for which name."""
import datetime
import http.server

class Sinkhole(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        now = datetime.datetime.now().isoformat(timespec="seconds")
        print(now, self.client_address[0], self.headers.get("Host"), self.path, flush=True)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Blocked by Jatoba: this address is on the list of dangerous sites.\n")

    def log_message(self, *args):
        pass

http.server.ThreadingHTTPServer(("0.0.0.0", 80), Sinkhole).serve_forever()
EOF
root@dns:~# systemd-run --unit=sinkhole python3 /root/sinkhole.py; sleep 1; systemctl is-active sinkhole
Running as unit: sinkhole.service; invocation ID: daefbefabe6c4104ad15a13bc5eccc7a
active
ana@desk:~$ curl -s http://pagamento.cobranca-urgente.example.org/boleto.pdf
Blocked by Jatoba: this address is on the list of dangerous sites.
root@dns:~# journalctl -u sinkhole -o cat | grep -v systemd
Started sinkhole.service - /usr/bin/python3 /root/sinkhole.py.
2026-10-23T02:03:08 192.168.60.20 pagamento.cobranca-urgente.example.org /boleto.pdf
```

The visit from `desk` got a one-line page saying the site is blocked, which is what a person in
front of a browser should see instead of an error they will try three times. The journal of the
sinkhole recorded the visit: the time, the address `192.168.60.20`, the name the browser asked for
in its `Host` header, and the file it wanted, `/boleto.pdf`.

**That last line is the reason sinkholes exist.** The resolver log said `desk` looked the name up;
the sinkhole says `desk` then tried to download a payment slip from it. A lookup can come from a
preview, a mail scanner or a link nobody clicked. A connection with a path is a program that meant
to fetch something, and on a machine where malware is calling home it is the call itself, landing on
a machine you own instead of the attacker's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-sinkhole\" aria-label=\"The path of one download. One: desk asks dns for pagamento.cobranca-urgente.example.org. Two: dns answers 192.168.60.53, its own address, instead of the real one. Three: desk connects there and asks for /boleto.pdf. Four: the sinkhole answers with a page saying the site is blocked and writes a log line with the time, desk's address, the name and the path. The real site, drawn dashed, is never reached.\"><defs><marker id=\"l14-sinkhole-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-sinkhole-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"90.0\" width=\"110.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"85.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.20</text><rect x=\"300.0\" y=\"40.0\" width=\"200.0\" height=\"150.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns  192.168.60.53</text><rect x=\"315.0\" y=\"75.0\" width=\"170.0\" height=\"36.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"400.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unbound, with the list</text><rect x=\"315.0\" y=\"125.0\" width=\"170.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"400.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sinkhole on port 80</text><text x=\"400.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">logs who, which name, which path</text><path d=\"M140.0 100.0 L315.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-paper-dim)\"></path><text x=\"225.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 the name?</text><path d=\"M315.0 100.0 L140.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-paper-dim)\"></path><text x=\"225.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 it is .53</text><path d=\"M140.0 128.0 L315.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-amber)\"></path><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 GET /boleto.pdf</text><rect x=\"570.0\" y=\"80.0\" width=\"130.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"635.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the real site</text><text x=\"635.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never reached</text><text x=\"400.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4 a page for the person, a log line for the defender</text></svg>", "caption": "The resolver changed one answer; the sinkhole turned the visit into a finding."}
```

## What a sinkhole does not do

It does not clean anything. `desk` is still whatever it was before; the sinkhole only made one
destination unreachable and told you about it. The finding goes where lesson 8 sends findings: the
machine is examined, and if something on it is calling a sinkholed domain every five minutes, that
is a machine to isolate and rebuild, not a log line to admire.

It also sees only what it can understand. This one speaks plain HTTP on port 80. A program that
connects with TLS to port 443 reaches the sinkhole and finds no service there, so the connection
fails and the resolver log is all you have. Commercial sinkholes answer on more ports, and some
present a certificate, which only works on machines that trust its issuer, the constraint every
inspection of encrypted traffic meets.

And it receives whatever it is sent, which can include data a program was trying to send out. **A
sinkhole is a machine that collects other people's traffic, so it is treated like one**: on its own
segment, with nothing else on it, its logs kept as long as the incident needs them and no longer.
