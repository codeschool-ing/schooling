---
title: Who is asking
version: 1
---

A request with a valid connection and no token:

```
ana@lab:~/agents$ curl -s -i --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/mcp | grep -v "^date:"
HTTP/1.1 401 Unauthorized
server: uvicorn
content-type: application/json
content-length: 74
www-authenticate: Bearer error="invalid_token", error_description="Authentication required", resource_metadata="https://mcp.marginalia.test:8443/.well-known/oauth-protected-resource/mcp"

{"error": "invalid_token", "error_description": "Authentication required"}
```

`401 Unauthorized`, and a **`WWW-Authenticate`** header. Besides the error, the header carries `resource_metadata`, a URL. The specification requires a protected MCP server to publish metadata about itself, and this header is how a client that knows nothing but the server's address finds it, and from it, how to get a token. Following the URL:

```
ana@lab:~/agents$ curl -s --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/.well-known/oauth-protected-resource/mcp | python -m json.tool
{
    "resource": "https://mcp.marginalia.test:8443/mcp",
    "authorization_servers": [
        "https://auth.marginalia.test:9443"
    ],
    "scopes_supported": [
        "orders:read"
    ],
    "bearer_methods_supported": [
        "header"
    ]
}
ana@lab:~/agents$ curl -s --cacert marginalia-ca.crt https://auth.marginalia.test:9443/.well-known/oauth-authorization-server; echo
{
 "issuer": "https://auth.marginalia.test:9443",
 "authorization_endpoint": "https://auth.marginalia.test:9443/authorize",
 "token_endpoint": "https://auth.marginalia.test:9443/token",
 "response_types_supported": [
  "code"
 ],
 "grant_types_supported": [
  "authorization_code",
  "refresh_token"
 ],
 "code_challenge_methods_supported": [
  "S256"
 ],
 "scopes_supported": [
  "orders:read",
  "orders:refund"
 ]
}
ana@lab:~/agents$ curl -s --cacert marginalia-ca.crt -X POST https://auth.marginalia.test:9443/token; echo
{
 "error": "not_implemented",
 "error_description": "this lab issues its tokens by file; see lab.sh"
}
```

The first document is the server's **protected resource metadata** (RFC 9728). It names the `resource` this server is (the canonical URL tokens must be issued for), the **authorization servers** that issue those tokens, the scopes it supports, and that tokens go in a header. The second is that authorization server's own **metadata** (RFC 8414): where a client sends a person to log in (`authorization_endpoint`), where it exchanges the result for a token (`token_endpoint`), which flows it supports, and `S256`, the PKCE method section 08 explains.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The discovery chain a client can follow from nothing but the server&#x27;s address. A request with no token gets 401 and a WWW-Authenticate header naming the protected resource metadata. That document names the authorization server. The authorization server&#x27;s own metadata names its endpoints, the scopes and S256 for PKCE. Only then can a client ask for a token.\"><defs><marker id=\"l16chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /mcp</text><text x=\"30\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no token: 401</text><rect x=\"200\" y=\"50\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WWW-Authenticate</text><text x=\"210\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource_metadata=…</text><rect x=\"390\" y=\"50\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">resource metadata</text><text x=\"400\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">authorization_servers</text><rect x=\"570\" y=\"50\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">AS metadata</text><text x=\"580\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">endpoints, S256</text><path d=\"M170 80 L200 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-amber)\"></path><path d=\"M360 80 L390 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-phosphor)\"></path><path d=\"M540 80 L570 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-phosphor)\"></path></svg>", "caption": "Each step names the next. Nothing has to be configured in advance but the server's URL."}
```

The authorization server here is `auth_metadata.py`, which `second_machine.sh` started beside the MCP server:

```python
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
```

The third response is the honest one. This lab's authorization server **publishes metadata and nothing else**: its token endpoint answers `501` and says the lab issues tokens by file. Running a real authorization server, with logins and consent screens, is a course of its own; what matters here is that the chain is real and that a client can walk it, and section 08 describes the steps at the end of it that the lab skips.
