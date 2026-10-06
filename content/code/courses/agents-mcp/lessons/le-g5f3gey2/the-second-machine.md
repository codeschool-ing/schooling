---
title: The second machine
version: 1
---

The lab gives ana a second machine without a second computer: a **network namespace** called `remote`, with its own network interface and address, `203.0.113.10`, reached from ana's side through a virtual cable whose end is `203.0.113.1`. Two names point at it, `mcp.marginalia.test` and `auth.marginalia.test`. `lab.sh` builds it, and `lab.sh remote` deploys the server ana wrote (section 05) and starts it there as the user `mcpd`, with **its own copy of the shop**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two machines. On ana&#x27;s, a host with a token file and the lab&#x27;s CA certificate. On the second, the network namespace remote at 203.0.113.10, the user mcpd runs the MCP server on port 8443 and the authorization server&#x27;s metadata on port 9443, with its own copy of the shop. Between them, HTTPS: TLS checked against the lab&#x27;s CA, and a bearer token on every request.\"><defs><marker id=\"l16mach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ana&#x27;s machine, 203.0.113.1</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_client.py</text><text x=\"50\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a host, as ana</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tokens/, marginalia-ca.crt</text><text x=\"50\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it carries and trusts</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"456\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remote, 203.0.113.10</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_mcp.py :8443</text><text x=\"470\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as mcpd, its own shop.db</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth_metadata.py :9443</text><text x=\"470\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">metadata only</text><path d=\"M260 85 L460 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16mach-ah-phosphor)\"></path><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTPS + bearer token</text></svg>", "caption": "The boundary is the network now: a certificate says who the server is, a token says who is asking."}
```

```
ana@lab:~/agents$ getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0
203.0.113.10    mcp.marginalia.test auth.marginalia.test
203.0.113.10    mcp.marginalia.test auth.marginalia.test
mcp0@if7         UP             203.0.113.1/24 
ana@lab:~/agents$ ls /srv/mcp 2>&1; ls -l tokens
ls: cannot open directory '/srv/mcp': Permission denied
total 16
-rw------- 1 ana ana 52 Oct  6 00:55 billing
-rw------- 1 ana ana 52 Oct  6 00:55 expired
-rw------- 1 ana ana 52 Oct  6 00:55 refunds
-rw------- 1 ana ana 52 Oct  6 00:55 support
```

The names resolve to the second machine's address, and ana's end of the cable is up. `ls /srv/mcp` is refused: the server's files belong to `mcpd`, and ana cannot read them, nor the token table inside. The other direction holds too: `remote_mcp.py` reads its own `data/shop.db`, not anything in `/home/ana`. The `tokens` directory holds four bearer tokens the lab wrote for ana, readable by her only; section 06 uses each.

A namespace separates networks, and the separate user and directories separate files. It is not a real second computer (the two share a kernel), and for the purposes of this lesson it does not need to be: everything the client and server can observe is what they would observe across a real network.

**TLS comes first.** The server's certificate was signed by a certificate authority the lab created for itself, and nothing on ana's machine trusts that authority unless told to:

```
ana@lab:~/agents$ curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"
curl exit code: 60
ana@lab:~/agents$ openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile /opt/agents/share/marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"
subject=CN = mcp.marginalia.test
issuer=CN = Marginalia lab CA
Verify return code: 0 (ok)
```

Without the lab's CA, `curl` refused the connection with exit code `60`, which is curl's code for a certificate it could not verify. With `-CAfile` pointing at `/opt/agents/share/marginalia-ca.crt`, the same certificate verified: subject `mcp.marginalia.test`, issuer `Marginalia lab CA`, return code `0`. That file is the only change on the client side. **Nothing in this lesson turns verification off**: a client that skips the check would talk just as happily to anyone who answered at that address, which is the thing TLS exists to prevent.
