---
title: "Client credentials: uma máquina por conta própria"
version: 1
---

Toda noite um job copia os níveis de estoque da loja para o depósito. **Não há pessoa envolvida,
então não há ninguém para mandar a uma página de entrada nem ninguém para consentir.** O job é um
cliente agindo por si mesmo, e o OAuth tem um grant exatamente para isso: **client credentials**. O
cliente se autentica em `/token` e recebe um token em nome próprio. Não há navegador nem código.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Client credentials: três partes em vez de quatro. Um job do depósito, cadastrado como o cliente shelf-web, envia grant_type=client_credentials com seu id e segredo para /token e recebe só um access token, e então chama a lista de estoque com ele. Não há navegador, nem pessoa, nem código.\"><defs><marker id=\"l09-cc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">job do depósito</text><text x=\"105.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">client: shelf-web</text><rect x=\"275\" y=\"14\" width=\"170\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor de autorização</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/token</text><rect x=\"530\" y=\"100\" width=\"170\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor de recursos</text><text x=\"615.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/books/stock</text><line x1=\"120\" y1=\"98\" x2=\"273\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"108\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">grant_type=client_credentials</text><text x=\"108\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1 · id e segredo, HTTP Basic</text><line x1=\"330\" y1=\"68\" x2=\"165\" y2=\"98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"300\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 · um access token, mais nada</text><line x1=\"192\" y1=\"130\" x2=\"528\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-cc-ah)\"></line><text x=\"360.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 · Authorization: Bearer …</text><rect x=\"20\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"84.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem navegador</text><rect x=\"158\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"222.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem pessoa</text><rect x=\"296\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem código</text><rect x=\"434\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"498.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem refresh token</text><rect x=\"572\" y=\"190\" width=\"128\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"636.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem ID token</text></svg>", "caption": "Client credentials. O cliente age por conta própria, então tudo o que no fluxo de código existia por causa de uma pessoa está ausente.", "same": ["3 · Authorization: Bearer …"]}
```

O cliente do `idp.py` tem permissão para `books:read` sozinho, e nada mais. O `del(.access_token)`
deixa o token comprido fora da impressão, e o `machine.json` guarda tudo:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=client_credentials -d scope=books:read | tee machine.json | jq 'del(.access_token)'
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read"
}
ana@api:~/shelf$ MT=$(jq -r .access_token machine.json)
```

Faltam dois tokens, e as duas ausências são de propósito. **Nenhum refresh token**, porque o
cliente pode repetir esse pedido sempre que o token dele expirar; um refresh token seria uma segunda
credencial de longa duração protegendo nada. **Nenhum ID token**, porque ninguém entrou.

O token abre a lista de estoque como o de uma pessoa abriria:

```
ana@api:~/shelf$ curl -s localhost:8000/books/stock -H "Authorization: Bearer $MT" | jq -c '.[0]'
{"id":1,"title":"Dom Casmurro","stock":12}
```

As claims dele dizem de quem ele é. `sub`, o sujeito, é o próprio cliente, onde o token de uma
pessoa levava o id da Ana; o `check_token.py`, da seção de OpenID Connect, lê o token:

```
ana@api:~/shelf$ python3 check_token.py "$MT" shelf-api
{
  "iss": "http://localhost:8000",
  "iat": 1791606663,
  "exp": 1791606963,
  "aud": "shelf-api",
  "sub": "shelf-web",
  "client_id": "shelf-web",
  "scope": "books:read",
  "jti": "9f4af73e03383ad9"
}
```

Uma API que precisa de uma pessoa o recusa, e o servidor de autorização nem emite `openid` para uma
máquina:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $MT"
{"error": "insufficient_scope", "error_description": "this needs the scope openid"}
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=client_credentials -d scope=openid
{"error": "invalid_scope", "error_description": "a machine may ask for books:read only"}
```

## Agora o segredo é a credencial inteira

**No fluxo de código, um segredo de cliente roubado não bastava sozinho; aqui ele é tudo.** Quem
tem `shelf-web:lab-only-secret` gera tokens enquanto o segredo valer. Então o segredo de um cliente
máquina mora onde segredos devem morar: num gerenciador de segredos ou no ambiente da plataforma,
nunca no repositório, e é trocado num calendário. Melhor ainda, muitos servidores de autorização deixam um cliente provar quem é com uma chave
privada em vez de um segredo compartilhado. O cliente assina um JWT curto (`private_key_jwt`) ou
apresenta um certificado TLS de cliente (RFC 8705), e aí não há segredo no lado do servidor para
roubar.

Dê a cada cliente máquina o menor escopo que faz o trabalho dele, um cliente por trabalho, para que
uma credencial vazada abra uma porta só. E **nunca use client credentials para agir por uma
pessoa**: um token cujo `sub` é o cliente diz que o cliente fez, e todo log dali em diante erra
sobre quem.
