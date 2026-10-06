"""The authorization server's metadata, and nothing behind it.

Lesson 16's remote server names https://auth.marginalia.test:9443 as the
authorization server its tokens come from. This program publishes that
server's metadata (RFC 8414) so a client can follow the discovery chain to
the end. It issues no tokens: the endpoints it names answer 501 and say so.
The lab writes the tokens itself (lab.sh, start_remote), and the remote
server checks them against a table, the way an introspection endpoint would.
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
                             "error_description": "this lab issues its tokens by file; see lab.sh"})

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
