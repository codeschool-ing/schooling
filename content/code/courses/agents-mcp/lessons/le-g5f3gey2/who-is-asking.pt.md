---
title: Quem está pedindo
version: 1
---

Um pedido com uma conexão válida e sem token:

```
ana@lab:~/agents$ curl -s -i --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/mcp | grep -v "^date:"
HTTP/1.1 401 Unauthorized
server: uvicorn
content-type: application/json
content-length: 74
www-authenticate: Bearer error="invalid_token", error_description="Authentication required", resource_metadata="https://mcp.marginalia.test:8443/.well-known/oauth-protected-resource/mcp"

{"error": "invalid_token", "error_description": "Authentication required"}
```

`401 Unauthorized`, e um cabeçalho **`WWW-Authenticate`**. Além do erro, o cabeçalho leva `resource_metadata`, uma URL. A especificação exige que um servidor MCP protegido publique metadados sobre si mesmo, e este cabeçalho é como um cliente que só conhece o endereço do servidor os acha, e a partir deles, como obter um token. Seguindo a URL:

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

O primeiro documento são os **metadados do recurso protegido** do servidor (RFC 9728). Ele nomeia o `resource` que este servidor é (a URL canônica para a qual os tokens têm de ser emitidos), os **servidores de autorização** que emitem esses tokens, os escopos que ele aceita, e que os tokens vão num cabeçalho. O segundo são os **metadados** do próprio servidor de autorização (RFC 8414): para onde um cliente manda uma pessoa fazer login (`authorization_endpoint`), onde troca o resultado por um token (`token_endpoint`), que fluxos ele aceita, e o `S256`, o método de PKCE que a seção 08 explica.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A cadeia de descoberta que um cliente consegue seguir a partir só do endereço do servidor. Um pedido sem token recebe 401 e um cabeçalho WWW-Authenticate que nomeia os metadados do recurso protegido. Esse documento nomeia o servidor de autorização. Os metadados do próprio servidor de autorização nomeiam os endpoints, os escopos e o S256 do PKCE. Só então um cliente consegue pedir um token.\"><defs><marker id=\"l16chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">POST /mcp</text><text x=\"30\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem token: 401</text><rect x=\"200\" y=\"50\" width=\"160\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WWW-Authenticate</text><text x=\"210\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource_metadata=…</text><rect x=\"390\" y=\"50\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">metadados do recurso</text><text x=\"400\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">authorization_servers</text><rect x=\"570\" y=\"50\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">metadados do AS</text><text x=\"580\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">endpoints, S256</text><path d=\"M170 80 L200 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-amber)\"></path><path d=\"M360 80 L390 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-phosphor)\"></path><path d=\"M540 80 L570 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16chain-ah-phosphor)\"></path></svg>", "caption": "Cada passo nomeia o próximo. Nada precisa ser configurado antes, além da URL do servidor.", "same": ["resource_metadata=…", "authorization_servers", "endpoints, S256"]}
```

A terceira resposta é a honesta. O servidor de autorização deste laboratório **publica metadados e mais nada**: o endpoint de token responde `501` e diz que o laboratório emite tokens por arquivo. Rodar um servidor de autorização de verdade, com logins e telas de consentimento, é um curso à parte; o que importa aqui é que a cadeia é real e que um cliente consegue percorrê-la, e a seção 08 descreve os passos do fim dela que o laboratório pula.
