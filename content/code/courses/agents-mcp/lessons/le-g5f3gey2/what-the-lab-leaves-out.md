---
title: What the lab leaves out
version: 1
---

The lab wrote the tokens into files. In a real deployment a client obtains them through the flow the specification defines, and this is that flow at the end of section 04's chain, in the order a client follows it:

1. **Register, or be known.** The specification says clients and authorization servers should support **Client ID Metadata Documents**: the client's id is a URL where a document describing it is published. Pre-registration is the other route. Dynamic client registration, which earlier revisions leaned on, is deprecated in 2026-07-28.
2. **Send the person to the authorization endpoint** with an authorization request that carries a **PKCE** challenge (the `S256` in the metadata: the client keeps a random secret and sends its hash, so a stolen authorization code is useless without the secret), the scopes it wants, and the **`resource` parameter** naming the MCP server's canonical URL (RFC 8707). The person logs in and consents there, never in the client.
3. **Exchange the code for a token** at the token endpoint, proving the PKCE secret, and check that the response came from the issuer the client recorded before redirecting.
4. **Send the token** in the `Authorization` header on every request to that server, and to no other.

Two rules from the specification sit on either side of that flow, and both are about where a token may go. **A client must not send a server any token other than one issued for that server by that server's authorization server.** And **a server must not pass on a token it received**: if it calls another service, it obtains a token of its own for that service. The second rule has a name in the specification's security notes, *token passthrough*. The reason is section 06's audience check from the other side: a server that forwarded tokens would let any client act at the downstream service with whatever the token allowed, and the downstream service could not tell.

What the lab does run is everything a server must do with a token once it has one: check it, check it was issued for this server, check its scope, and refuse without saying which check failed. That half does not depend on how the token was obtained.
