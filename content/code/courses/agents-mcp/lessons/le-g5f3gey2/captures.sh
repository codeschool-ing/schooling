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
# (lab.sh reset); the files ana wrote (put below), which the lesson shows in
# full; and DEPLOYING remote_mcp.py to the second machine, which is
# `lab.sh remote`: it copies the file into the "remote" network namespace's
# /srv/mcp, gives that machine its own copy of the shop, writes the four
# tokens the authorization server would have issued (to ~/agents/tokens/ and,
# hashed, to the server's table) and starts the server there as the user mcpd.
# lab.sh says how each piece is built.
#
# NO MODEL TAKES PART IN THIS LESSON. The network namespace, the lab's
# certificate authority and certificate (openssl), the TLS checks, the
# server (mcp 2.3.0 on uvicorn 0.54.0), its bearer-token checks and metadata,
# curl's and the client's refusals and every result are real. The
# authorization server publishes METADATA ONLY: lab/remote/auth_metadata.py
# issues no tokens, and the lesson says so where it reads it. No token value
# is printed anywhere.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, with LAB_TODAY=2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/agents-capture.lock; flock 9
lab reset >/dev/null

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
    """Checks a bearer token against the table the authorization server keeps (the lab writes it)."""

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
"""Call the remote server: TLS checked against the lab's CA, and a bearer token from a file."""
import asyncio
import json
import ssl
import sys

import httpx2
from mcp import Client
from mcp.client.streamable_http import streamable_http_client

URL = "https://mcp.marginalia.test:8443/mcp"
CA = "/opt/agents/share/marginalia-ca.crt"   # the lab's authority, and the only one this client trusts


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
curl -s --cacert /opt/agents/share/marginalia-ca.crt https://mcp.marginalia.test:8443/mcp \
  -H "Authorization: Bearer $(cat tokens/$1)" \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: $2" \
  -d "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/call\", \"params\": {\"name\": \"$2\", \"arguments\": $3,
       \"_meta\": {\"io.modelcontextprotocol/protocolVersion\": \"2026-07-28\", \"io.modelcontextprotocol/clientCapabilities\": {}}}}" \
  -w "  [HTTP %{http_code}]\n"
SH

lab remote >/dev/null

block machine
on 'getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0'
on 'ls /srv/mcp 2>&1; ls -l tokens'

block tls
on 'curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"'
on 'openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile /opt/agents/share/marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"'

block unauthorised
on 'curl -s -i --cacert /opt/agents/share/marginalia-ca.crt https://mcp.marginalia.test:8443/mcp | grep -v "^date:"'

block discovery
on 'curl -s --cacert /opt/agents/share/marginalia-ca.crt https://mcp.marginalia.test:8443/.well-known/oauth-protected-resource/mcp | python -m json.tool'
on 'curl -s --cacert /opt/agents/share/marginalia-ca.crt https://auth.marginalia.test:9443/.well-known/oauth-authorization-server; echo'
on 'curl -s --cacert /opt/agents/share/marginalia-ca.crt -X POST https://auth.marginalia.test:9443/token; echo'

block tokens
on "bash call.sh support get_order '{\"order_id\": \"M-1043\"}' | cut -c1-170"
on "bash call.sh support refund '{\"order_id\": \"M-1047\", \"cents\": 3890, \"reason\": \"one copy arrived damaged\"}' | cut -c1-170"
on "bash call.sh refunds refund '{\"order_id\": \"M-1047\", \"cents\": 3890, \"reason\": \"one copy arrived damaged\"}' | cut -c1-170"
on "bash call.sh billing get_order '{\"order_id\": \"M-1043\"}'"
on "bash call.sh expired get_order '{\"order_id\": \"M-1043\"}'"

block client
on "python remote_client.py support get_order '{\"order_id\": \"M-1043\"}'"
on "python remote_client.py billing get_order '{\"order_id\": \"M-1043\"}'"
