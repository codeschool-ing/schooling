---
title: The second machine
version: 2
---

ana gets a second machine without a second computer: a **network namespace** called `remote`, with its own network interface and address, `203.0.113.10`, reached from ana's side through a virtual cable whose end is `203.0.113.1`. Two names point at it, `mcp.marginalia.test` and `auth.marginalia.test`. `second_machine.sh` builds it, as root, and deploys there the two programs the next sections read: `auth_metadata.py` (section 04) and the server ana wrote, `remote_mcp.py` (section 05). They run as the user `mcpd`, with **their own Python and their own copy of the shop**. Save both in `~/agents` first; the script copies them from there.

```bash
# second_machine.sh up|down: a second machine on this one, for lesson 16. Run it from ~/agents, with sudo.
#
# "remote" is a network namespace: an interface and an address of its own, 203.0.113.10 (an address
# kept for documentation, RFC 5737), reached from here through a virtual cable whose end is 203.0.113.1.
# Two names point at it. The servers run there as the user mcpd, from /srv/mcp, with their own Python
# and their own copy of the shop: nothing there reads /home.
set -euo pipefail
ME=${SUDO_USER:?run it with sudo, from your own account}
SRV=/srv/mcp

down() {
  ip netns pids remote 2>/dev/null | xargs -r kill || true
  ip netns del remote 2>/dev/null || true   # the cable goes with it
  sed -i '/marginalia[.]test/d' /etc/hosts
}

up() {
  down
  ip netns add remote
  ip link add mcp0 type veth peer name mcp1 netns remote
  ip addr add 203.0.113.1/24 dev mcp0
  ip link set mcp0 up
  ip -n remote addr add 203.0.113.10/24 dev mcp1
  ip -n remote link set mcp1 up
  ip -n remote link set lo up
  echo "203.0.113.10 mcp.marginalia.test auth.marginalia.test" >> /etc/hosts

  id mcpd >/dev/null 2>&1 || useradd --system --home-dir $SRV --shell /usr/sbin/nologin mcpd
  rm -rf $SRV
  install -d -o mcpd -g mcpd -m 0700 $SRV $SRV/tls
  install -o mcpd -g mcpd -m 0644 remote_mcp.py auth_metadata.py shop.py make_shop.py $SRV/
  runuser -u mcpd -- sh -c "cd $SRV && python3 -m venv .venv && .venv/bin/pip install -q mcp==2.3.0 uvicorn==0.54.0 &&
                            .venv/bin/python make_shop.py > /dev/null"

  # A certificate authority of this machine's own, which signs the servers' certificate and is then
  # thrown away. Its certificate is the one file you need: your clients are told to trust it.
  local ca; ca=$(mktemp -d)
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=Marginalia lab CA" \
    -keyout $ca/ca.key -out $ca/ca.crt 2>/dev/null
  openssl req -newkey rsa:2048 -nodes -subj "/CN=mcp.marginalia.test" \
    -keyout $SRV/tls/server.key -out $ca/server.csr 2>/dev/null
  printf 'subjectAltName=DNS:mcp.marginalia.test,DNS:auth.marginalia.test\n' > $ca/san.ext
  openssl x509 -req -in $ca/server.csr -CA $ca/ca.crt -CAkey $ca/ca.key -CAcreateserial -days 825 \
    -extfile $ca/san.ext -out $SRV/tls/server.crt 2>/dev/null
  install -o "$ME" -g "$ME" -m 0644 $ca/ca.crt marginalia-ca.crt
  rm -rf $ca

  # The tokens an authorization server would have issued: each value to tokens/NAME, readable by you
  # only, and its SHA-256, with what it grants, to the server's table. Never printed.
  install -d -o "$ME" -g "$ME" -m 0700 tokens
  local name client scopes resource expires value sep=""
  echo "{" > $SRV/tokens.json
  while read -r name client scopes resource expires; do
    value=lab-$(openssl rand -hex 24)
    printf '%s' "$value" > tokens/$name
    chown "$ME:$ME" tokens/$name
    chmod 0600 tokens/$name
    printf '%s "%s": {"client_id": "%s", "scopes": %s, "resource": "%s", "expires_at": %s}\n' "$sep" \
      "$(printf '%s' "$value" | sha256sum | cut -d' ' -f1)" "$client" "$scopes" "$resource" \
      "$(date -d "$expires" +%s)" >> $SRV/tokens.json
    sep=","
  done <<'TOKENS'
support support-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp +90days
refunds refunds-desk ["orders:read","orders:refund"] https://mcp.marginalia.test:8443/mcp +90days
billing billing-agent ["orders:read"] https://billing.marginalia.test/mcp +90days
expired old-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp -1day
TOKENS
  echo "}" >> $SRV/tokens.json
  chown -R mcpd:mcpd $SRV
  chmod 0600 $SRV/tokens.json $SRV/tls/server.key

  local p
  for p in remote_mcp auth_metadata; do
    ip netns exec remote runuser -u mcpd -- env -i HOME=$SRV PATH=/usr/bin:/bin \
      setsid sh -c "cd $SRV && exec .venv/bin/python $p.py" > /dev/null 2>> $SRV/servers.log < /dev/null &
  done
  for _ in $(seq 50); do
    if (exec 3<> /dev/tcp/203.0.113.10/8443) 2> /dev/null; then echo "remote is up"; return; fi
    sleep 0.2
  done
  echo "the server did not start; sudo tail $SRV/servers.log says why" >&2
  exit 1
}

case ${1:-} in
  up) up ;;
  down) down ;;
  *) echo "usage: sudo bash second_machine.sh up|down" >&2; exit 2 ;;
esac
```

It needs `ip` and `openssl`, which Ubuntu Server installs by default, and the network once, for `pip` to fetch `mcp` and `uvicorn` into the second machine's own environment. When the server answers on port 8443 it says `remote is up`; when it does not, it says where the server's error went.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two machines. On ana&#x27;s, a host with a token file and the lab&#x27;s CA certificate. On the second, the network namespace remote at 203.0.113.10, the user mcpd runs the MCP server on port 8443 and the authorization server&#x27;s metadata on port 9443, with its own copy of the shop. Between them, HTTPS: TLS checked against the lab&#x27;s CA, and a bearer token on every request.\"><defs><marker id=\"l16mach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ana&#x27;s machine, 203.0.113.1</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_client.py</text><text x=\"50\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a host, as ana</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tokens/, marginalia-ca.crt</text><text x=\"50\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it carries and trusts</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"456\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remote, 203.0.113.10</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_mcp.py :8443</text><text x=\"470\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as mcpd, its own shop.db</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth_metadata.py :9443</text><text x=\"470\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">metadata only</text><path d=\"M260 85 L460 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16mach-ah-phosphor)\"></path><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTPS + bearer token</text></svg>", "caption": "The boundary is the network now: a certificate says who the server is, a token says who is asking."}
```

```
ana@lab:~/agents$ sudo bash second_machine.sh up
remote is up
ana@lab:~/agents$ getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0
203.0.113.10    mcp.marginalia.test auth.marginalia.test
203.0.113.10    mcp.marginalia.test auth.marginalia.test
mcp0@if2         UP             203.0.113.1/24 
ana@lab:~/agents$ ls /srv/mcp 2>&1; ls -l tokens marginalia-ca.crt
ls: cannot open directory '/srv/mcp': Permission denied
-rw-r--r-- 1 ana ana 1135 Oct  7 23:37 marginalia-ca.crt

tokens:
total 16
-rw------- 1 ana ana 52 Oct  7 23:37 billing
-rw------- 1 ana ana 52 Oct  7 23:37 expired
-rw------- 1 ana ana 52 Oct  7 23:37 refunds
-rw------- 1 ana ana 52 Oct  7 23:37 support
```

The names resolve to the second machine's address, and ana's end of the cable is up. `ls /srv/mcp` is refused: the server's files belong to `mcpd`, and ana cannot read them, nor the token table inside. The other direction holds too: `remote_mcp.py` reads its own `data/shop.db`, not anything in `/home/ana`. The `tokens` directory holds four bearer tokens the script wrote for ana, readable by her only; section 06 uses each. `marginalia-ca.crt` is the one file of the second machine's certificate authority that ana has, and the next block uses it.

A namespace separates networks, and the separate user and directories separate files. It is not a real second computer (the two share a kernel), and for the purposes of this lesson it does not need to be: everything the client and server can observe is what they would observe across a real network.

**TLS comes first.** The server's certificate was signed by a certificate authority the script created and then deleted the key of, and nothing on ana's machine trusts that authority unless told to:

```
ana@lab:~/agents$ curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"
curl exit code: 60
ana@lab:~/agents$ openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"
subject=CN = mcp.marginalia.test
issuer=CN = Marginalia lab CA
Verify return code: 0 (ok)
```

Without that CA, `curl` refused the connection with exit code `60`, which is curl's code for a certificate it could not verify. With `-CAfile` pointing at `marginalia-ca.crt`, the same certificate verified: subject `mcp.marginalia.test`, issuer `Marginalia lab CA`, return code `0`. That file is the only change on the client side. **Nothing in this lesson turns verification off**: a client that skips the check would talk just as happily to anyone who answered at that address, which is the thing TLS exists to prevent.
