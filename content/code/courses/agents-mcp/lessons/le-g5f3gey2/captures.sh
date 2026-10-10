#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), and the files ana wrote (put below), which the lesson shows
# in full, each checked by lab/shown.py. "sudo bash second_machine.sh" is run
# here as root with SUDO_USER=ana, which is what sudo would have given it, and
# with root's environment, which is how pip reaches the package index from the
# machine these captures were made on: through a proxy whose certificate is in
# a file mcpd cannot read, so a readable copy is passed as PIP_CERT.
#
# NO MODEL TAKES PART IN THIS LESSON. The network namespace, the certificate
# authority and certificate (openssl), the TLS checks, the server (mcp 2.3.0
# on uvicorn 0.54.0), its bearer-token checks and metadata, curl's and the
# client's refusals and every result are real. The authorization server
# publishes METADATA ONLY: auth_metadata.py issues no tokens, and the lesson
# says so where it reads it. No token value is printed anywhere.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
as_root() {
  printf 'ana@lab:~/agents$ sudo bash second_machine.sh %s\n' "$1"
  (cd /home/ana/agents && SUDO_USER=ana bash second_machine.sh "$1") 2>&1 || true
}
# The proxy's certificate, where mcpd can read it, for pip on this machine only.
if [ -n "${PIP_CERT:-}" ]; then
  install -m 0644 "$PIP_CERT" /var/tmp/agents-pip-ca.crt
  export PIP_CERT=/var/tmp/agents-pip-ca.crt REQUESTS_CA_BUNDLE=/var/tmp/agents-pip-ca.crt SSL_CERT_FILE=/var/tmp/agents-pip-ca.crt
fi

put remote_mcp.py <<'PY'
"""Marginalia's MCP server as a remote service: TLS, bearer tokens, and a scope per tool."""
import hashlib
import json
import time

import uvicorn
from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.auth.provider import AccessToken
from mcp.server.auth.settings import AuthSettings
from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp.server.transport_security import TransportSecuritySettings

import shop

URL = "https://mcp.marginalia.test:8443/mcp"


class TokenTable:
    """Checks a bearer token against the table the authorization server keeps (second_machine.sh writes it)."""

    async def verify_token(self, token: str) -> AccessToken | None:
        entry = json.load(open("tokens.json")).get(hashlib.sha256(token.encode()).hexdigest())
        if entry is None or entry["expires_at"] < time.time():
            return None
        return AccessToken(token=token, client_id=entry["client_id"], scopes=entry["scopes"],
                           expires_at=entry["expires_at"], resource=entry["resource"])


server = MCPServer(
    "marginalia-remote", version="1.0.0", token_verifier=TokenTable(),
    auth=AuthSettings(issuer_url="https://auth.marginalia.test:9443", resource_server_url=URL,
                      required_scopes=["orders:read"], validate_token_resource=True))


@server.tool()
def get_order(order_id: str) -> str:
    """Look up one Marginalia order by its id, M- and four digits."""
    try:
        found = shop.get_order(order_id)
    except LookupError as e:
        raise ToolError(str(e)) from e
    return json.dumps({k: found[k] for k in ("id", "status", "placed_on", "delivered_on", "tracking", "total")})


@server.tool()
def refund(order_id: str, cents: int, reason: str) -> str:
    """Refund part or all of an order, in cents. Needs the orders:refund scope."""
    token = get_access_token()
    if "orders:refund" not in token.scopes:
        raise ToolError(f"the token of {token.client_id} does not carry orders:refund")
    return json.dumps(shop.refund(order_id, cents, reason, approved_by=token.client_id))


app = server.streamable_http_app(transport_security=TransportSecuritySettings(
    allowed_hosts=["mcp.marginalia.test:8443"], allowed_origins=[]))

if __name__ == "__main__":
    uvicorn.run(app, host="203.0.113.10", port=8443, ssl_certfile="tls/server.crt", ssl_keyfile="tls/server.key",
                log_level="warning")
PY

put remote_client.py <<'PY'
"""Call the remote server: TLS checked against the second machine's CA, and a bearer token from a file."""
import asyncio
import json
import ssl
import sys

import httpx2
from mcp import Client
from mcp.client.streamable_http import streamable_http_client

URL = "https://mcp.marginalia.test:8443/mcp"
CA = "marginalia-ca.crt"   # the second machine's authority, and the only one this client trusts


async def main(token_name, tool, arguments):
    token = open(f"tokens/{token_name}").read()
    tls = ssl.create_default_context(cafile=CA)
    async with httpx2.AsyncClient(verify=tls, headers={"Authorization": f"Bearer {token}"}) as http:
        async with Client(streamable_http_client(URL, http_client=http)) as client:
            result = await client.call_tool(tool, json.loads(arguments))
            print(("error: " if result.is_error else "result: ") + result.content[0].text[:120])


def first_cause(group):
    """The innermost exception of a (possibly nested) group: the one that says what happened."""
    while isinstance(group, BaseExceptionGroup):
        group = group.exceptions[0]
    return group


try:
    asyncio.run(main(*sys.argv[1:]))
except BaseException as e:
    cause = first_cause(e)
    print(f"refused: {type(cause).__name__}: {cause}")
PY

put call.sh <<'SH'
# call.sh TOKEN-NAME TOOL ARGUMENTS: one tools/call to the remote server, by hand, with curl.
curl -s --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/mcp \
  -H "Authorization: Bearer $(cat tokens/$1)" \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: $2" \
  -d "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/call\", \"params\": {\"name\": \"$2\", \"arguments\": $3,
       \"_meta\": {\"io.modelcontextprotocol/protocolVersion\": \"2026-07-28\", \"io.modelcontextprotocol/clientCapabilities\": {}}}}" \
  -w "  [HTTP %{http_code}]\n"
SH

put auth_metadata.py <<'PY'
"""The authorization server's metadata, and nothing behind it.

remote_mcp.py names https://auth.marginalia.test:9443 as the authorization
server its tokens come from. This program publishes that server's metadata
(RFC 8414), so a client can follow the discovery chain to the end. It issues
no tokens: the endpoints it names answer 501 and say so. second_machine.sh
writes the tokens itself, and remote_mcp.py checks them against a table.
"""
import json
import ssl
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ISSUER = "https://auth.marginalia.test:9443"
METADATA = {
    "issuer": ISSUER,
    "authorization_endpoint": f"{ISSUER}/authorize",
    "token_endpoint": f"{ISSUER}/token",
    "response_types_supported": ["code"],
    "grant_types_supported": ["authorization_code", "refresh_token"],
    "code_challenge_methods_supported": ["S256"],
    "scopes_supported": ["orders:read", "orders:refund"],
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/.well-known/oauth-authorization-server":
            self.reply(200, METADATA)
        else:
            self.reply(501, {"error": "not_implemented",
                             "error_description": "this machine issues its tokens by file; see second_machine.sh"})

    do_POST = do_GET

    def reply(self, status, body):
        data = json.dumps(body, indent=1).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


httpd = ThreadingHTTPServer(("203.0.113.10", 9443), Handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain("tls/server.crt", "tls/server.key")
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
PY

put second_machine.sh <<'SH'
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
SH

block machine
as_root up
on 'getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0'
on 'ls /srv/mcp 2>&1; ls -l tokens marginalia-ca.crt'

block tls
on 'curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"'
on 'openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"'

block unauthorised
on 'curl -s -i --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/mcp | grep -v "^date:"'

block discovery
on 'curl -s --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/.well-known/oauth-protected-resource/mcp | python -m json.tool'
on 'curl -s --cacert marginalia-ca.crt https://auth.marginalia.test:9443/.well-known/oauth-authorization-server; echo'
on 'curl -s --cacert marginalia-ca.crt -X POST https://auth.marginalia.test:9443/token; echo'

block tokens
on "bash call.sh support get_order '{\"order_id\": \"M-1043\"}' | cut -c1-170"
on "bash call.sh support refund '{\"order_id\": \"M-1047\", \"cents\": 3890, \"reason\": \"one copy arrived damaged\"}' | cut -c1-170"
on "bash call.sh refunds refund '{\"order_id\": \"M-1047\", \"cents\": 3890, \"reason\": \"one copy arrived damaged\"}' | cut -c1-170"
on "bash call.sh billing get_order '{\"order_id\": \"M-1043\"}'"
on "bash call.sh expired get_order '{\"order_id\": \"M-1043\"}'"

block client
on "python remote_client.py support get_order '{\"order_id\": \"M-1043\"}'"
on "python remote_client.py billing get_order '{\"order_id\": \"M-1043\"}'"

block down
as_root down
